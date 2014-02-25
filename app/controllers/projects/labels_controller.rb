class Projects::LabelsController < Projects::ApplicationController
  before_filter :module_enabled

  # Allow read any issue
  before_filter :authorize_read_issue!

  respond_to :js, :html

  def index
    @labels = @project.issues_labels
  end

  def generate
    Gitlab::IssuesLabels.generate(@project)

    redirect_to project_issues_path(@project)
  end

  protected

  def module_enabled
    return render_404 unless @project.issues_enabled
  end
end
