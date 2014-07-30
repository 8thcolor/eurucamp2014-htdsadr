module Emails
  module Projects
    def project_access_granted_email(user_project_id)
      @users_project = UsersProject.find user_project_id
      @project = @users_project.project
      @target_url = project_url(@project)
      mail(to: @users_project.user_email,
           subject: subject("Access to project was granted"))
    end

    def project_was_moved_email(project_id, user_id)
      @user = User.find user_id
      @project = Project.find project_id
      @target_url = project_url(@project)
      mail(to: @user.email,
           subject: subject("Project was moved"))
    end

    def repository_push_email(project_id, recipient, author_id, branch, compare)
      @project = Project.find(project_id)
      @author  = User.find(author_id)
      @compare = compare
      @commits = Commit.decorate(compare.commits)
      @diffs   = compare.diffs
      @branch  = branch

      @target_url, @subject = 
        target_url_and_subject_for_repository_push(@project, @commits)

      mail(from: sender(author_id),
           to: recipient,
           subject: subject(@subject))
    end

    private

    def target_url_and_subject_for_repository_push(project, commits)
      return [
          project_compare_url(project, from: commits.first, to: commits.last),
          "#{commits.length} new commits pushed to repository" 
      ] if commits.length > 1

      [
        project_commit_url(project, commits.first),
        commits.first.title
      ]
    end
  end
end
