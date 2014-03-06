class GitTagPushService
  attr_accessor :project, :user, :push_data
  def execute(project, user, oldrev, newrev, ref)
    @project, @user = project, user
    @push_data = create_push_data(oldrev, newrev, ref)
    project.execute_hooks(@push_data.dup, :tag_push_hooks)
  end

  private

  def create_push_data(oldrev, newrev, ref)
    data = {
      ref: ref,
      oldrev: oldrev,
      newrev: newrev,
      user_id: user.id,
      user_name: user.name,
      project_id: project.id,
      repository: {
        name: project.name,
        url: project.url_to_repo,
        description: project.description,
        homepage: project.web_url
      }
    }
  end
end
