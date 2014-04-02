module Issues
  class ReopenService < Issues::BaseService
    def execute(issue)
      if issue.reopen
        event_service.reopen_issue(issue, current_user)
        create_note(issue)
        execute_hooks(issue)
      end

      issue
    end

    private

    def create_note(issue)
      Note.create_status_change_note(issue, issue.project, current_user, issue.state, nil)
    end
  end
end
