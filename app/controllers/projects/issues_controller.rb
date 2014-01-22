class Projects::IssuesController < Projects::ApplicationController
  before_filter :module_enabled
  before_filter :issue, only: [:edit, :update, :show]

  # Allow read any issue
  before_filter :authorize_read_issue!

  # Allow write(create) issue
  before_filter :authorize_write_issue!, only: [:new, :create]

  # Allow modify issue
  before_filter :authorize_modify_issue!, only: [:edit, :update]

  respond_to :html

  def index
    terms = params['issue_search']

    @issues = issues_filtered
    @issues = @issues.where("title LIKE ?", "%#{terms}%") if terms.present?
    @issues = @issues.page(params[:page]).per(20)

    assignee_id, milestone_id = params[:assignee_id], params[:milestone_id]
    @assignee = @project.team.find(assignee_id) if assignee_id.present? && !assignee_id.to_i.zero?
    @milestone = @project.milestones.find(milestone_id) if milestone_id.present? && !milestone_id.to_i.zero?
    sort_param = params[:sort] || 'newest'
    @sort = sort_param.humanize unless sort_param.empty?


    respond_to do |format|
      format.html
      format.atom { render layout: false }
      format.json do
        render json: {
          html: view_to_html_string("projects/issues/_issues")
        }
      end
    end
  end

  def new
    @issue = @project.issues.new(params[:issue])
    respond_with(@issue)
  end

  def edit
    respond_with(@issue)
  end

  def show
    @note = @project.notes.new(noteable: @issue)
    @notes = @issue.notes.inc_author.fresh
    @noteable = @issue

    respond_with(@issue)
  end

  def create
    @issue = @project.issues.new(params[:issue])
    @issue.author = current_user
    @issue.save

    respond_to do |format|
      format.html do
        if @issue.valid?
          redirect_to project_issue_path(@project, @issue)
        else
          render :new
        end
      end
      format.js
    end
  end

  def update
    @issue.update_attributes(params[:issue].merge(author_id_of_changes: current_user.id))
    @issue.reset_events_cache

    respond_to do |format|
      format.js
      format.html do
        if @issue.valid?
          redirect_to [@project, @issue]
        else
          render :edit
        end
      end
    end
  end

  def bulk_update
    result = Issues::BulkUpdateService.new(project, current_user, params).execute
    redirect_to :back, notice: "#{result[:count]} issues updated"
  end

  protected

  def issue
    @issue ||= begin
                 @project.issues.find_by!(iid: params[:id])
               rescue ActiveRecord::RecordNotFound
                 redirect_old
               end
  end

  def authorize_modify_issue!
    return render_404 unless can?(current_user, :modify_issue, @issue)
  end

  def authorize_admin_issue!
    return render_404 unless can?(current_user, :admin_issue, @issue)
  end

  def module_enabled
    return render_404 unless @project.issues_enabled
  end

  def issues_filtered
    params[:scope] = 'all' if params[:scope].blank?
    params[:state] = 'opened' if params[:state].blank?
    @issues = FilteringService.new.execute(Issue, current_user, params.merge(project_id: @project.id))
  end

  # Since iids are implemented only in 6.1
  # user may navigate to issue page using old global ids.
  #
  # To prevent 404 errors we provide a redirect to correct iids until 7.0 release
  #
  def redirect_old
    issue = @project.issues.find_by(id: params[:id])

    if issue
      redirect_to project_issue_path(@project, issue)
      return
    else
      raise ActiveRecord::RecordNotFound.new
    end
  end
end
