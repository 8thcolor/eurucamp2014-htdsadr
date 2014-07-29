class DashboardBaseController < ApplicationController
  def merge_requests
    @merge_requests = MergeRequestsFinder.new.execute(current_user, params)
    @merge_requests = @merge_requests.page(params[:page]).per(20)
    @merge_requests = @merge_requests.preload(:author, :target_project)
  end

  def issues
    @issues = IssuesFinder.new.execute(current_user, params)
    @issues = @issues.page(params[:page]).per(20)
    @issues = @issues.preload(:author, :project)

    respond_to do |format|
      format.html
      format.atom { render layout: false }
    end
  end
end