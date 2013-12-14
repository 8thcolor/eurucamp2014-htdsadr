class Projects::HooksController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_admin_project!

  respond_to :html

  layout "project_settings"

  def index
    @hooks = @project.hooks
    @hook = ProjectHook.new
  end

  def create
    @hook = @project.hooks.new(params[:hook])
    @hook.save

    if @hook.valid?
      redirect_to project_hooks_path(@project)
    else
      @hooks = @project.hooks
      render :index
    end
  end

  def test
    TestHookContext.new(project, current_user, params).execute

    redirect_to :back
  end

  def destroy
    @hook = @project.hooks.find(params[:id])
    @hook.destroy

    redirect_to project_hooks_path(@project)
  end
end
