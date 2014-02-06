class ProjectsController < ApplicationController
  skip_before_filter :authenticate_user!, only: [:show]
  before_filter :project, except: [:new, :create]
  before_filter :repository, except: [:new, :create]

  # Authorize
  before_filter :authorize_read_project!, except: [:index, :new, :create]
  before_filter :authorize_admin_project!, only: [:edit, :update, :destroy, :transfer, :archive, :unarchive]
  before_filter :require_non_empty_project, only: [:blob, :tree, :graph]

  layout 'navless', only: [:new, :create, :fork]
  before_filter :set_title, only: [:new, :create]

  def new
    @project = Project.new
  end

  def edit
    render 'edit', layout: "project_settings"
  end

  def create
    @project = ::Projects::CreateService.new(current_user, params[:project]).execute

    respond_to do |format|
      flash[:notice] = 'Project was successfully created.' if @project.saved?
      format.html do
        if @project.saved?
          redirect_to @project
        else
          render "new"
        end
      end
      format.js
    end
  end

  def update
    status = ::Projects::UpdateService.new(@project, current_user, params).execute

    respond_to do |format|
      if status
        flash[:notice] = 'Project was successfully updated.'
        format.html { redirect_to edit_project_path(@project), notice: 'Project was successfully updated.' }
        format.js
      else
        format.html { render "edit", layout: "project_settings" }
        format.js
      end
    end
  end

  def transfer
    ::Projects::TransferService.new(project, current_user, params).execute
  end

  def show
    return authenticate_user! unless @project.public? || current_user

    limit = (params[:limit] || 20).to_i
    @events = @project.events.recent
    @events = event_filter.apply_filter(@events)
    @events = @events.limit(limit).offset(params[:offset] || 0)

    respond_to do |format|
      format.html do
        if @project.empty_repo?
          render "projects/empty", layout: user_layout
        else
          if current_user
            @last_push = current_user.recent_push(@project.id)
          end
          render :show, layout: user_layout
        end
      end
      format.json { pager_json("events/_events", @events.count) }
    end
  end

  def destroy
    return access_denied! unless can?(current_user, :remove_project, project)

    project.team.truncate
    project.destroy

    respond_to do |format|
      format.html { redirect_to root_path }
    end
  end

  def fork
    @forked_project = ::Projects::ForkService.new(project, current_user).execute

    respond_to do |format|
      format.html do
        if @forked_project.saved? && @forked_project.forked?
          redirect_to(@forked_project, notice: 'Project was successfully forked.')
        else
          @title = 'Fork project'
          render "fork"
        end
      end
      format.js
    end
  end

  def autocomplete_sources
    @suggestions = {
      emojis: Emoji.names,
      issues: @project.issues.select([:iid, :title, :description]),
      members: @project.team.members.sort_by(&:username).map { |user| { username: user.username, name: user.name } }
    }

    respond_to do |format|
      format.json { render :json => @suggestions }
    end
  end

  def archive
    return access_denied! unless can?(current_user, :archive_project, project)
    project.archive!

    respond_to do |format|
      format.html { redirect_to @project }
    end
  end

  def unarchive
    return access_denied! unless can?(current_user, :archive_project, project)
    project.unarchive!

    respond_to do |format|
      format.html { redirect_to @project }
    end
  end

  private

  def set_title
    @title = 'New Project'
  end

  def user_layout
    current_user ? "projects" : "public_projects"
  end
end
