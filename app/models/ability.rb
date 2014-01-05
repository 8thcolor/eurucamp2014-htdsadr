class Ability
  class << self
    def allowed(user, subject)
      return not_auth_abilities(user, subject) if user.nil?
      return [] unless user.kind_of?(User)
      return [] if user.blocked?

      case subject.class.name
      when "Project" then project_abilities(user, subject)
      when "Issue" then issue_abilities(user, subject)
      when "Note" then note_abilities(user, subject)
      when "ProjectSnippet" then project_snippet_abilities(user, subject)
      when "PersonalSnippet" then personal_snippet_abilities(user, subject)
      when "MergeRequest" then merge_request_abilities(user, subject)
      when "Group" then group_abilities(user, subject)
      when "Namespace" then namespace_abilities(user, subject)
      else []
      end.concat(global_abilities(user))
    end

    # List of possible abilities
    # for non-authenticated user
    def not_auth_abilities(user, subject)
      project = if subject.kind_of?(Project)
                  subject
                elsif subject.respond_to?(:project)
                  subject.project
                else
                  nil
                end

      if project && project.public?
        [
          :read_project,
          :read_wiki,
          :read_issue,
          :read_milestone,
          :read_project_snippet,
          :read_team_member,
          :read_merge_request,
          :read_note,
          :download_code
        ]
      else
        []
      end
    end

    def global_abilities(user)
      rules = []
      rules << :create_group if user.can_create_group
      rules
    end

    def project_abilities(user, project)
      rules = []

      team = project.team

      # Rules based on role in project
      if team.masters.include?(user)
        rules += project_master_rules

      elsif team.developers.include?(user)
        rules += project_dev_rules

      elsif team.reporters.include?(user)
        rules += project_report_rules

      elsif team.guests.include?(user)
        rules += project_guest_rules
      end

      if project.public? || project.internal?
        rules += public_project_rules
      end

      if project.owner == user || user.admin?
        rules += project_admin_rules
      end

      if project.group && project.group.has_owner?(user)
        rules += project_admin_rules
      end

      if project.archived?
        rules -= project_archived_rules
      end

      rules
    end

    def public_project_rules
      project_guest_rules + [
        :download_code,
        :fork_project
      ]
    end

    def project_guest_rules
      [
        :read_project,
        :read_wiki,
        :read_issue,
        :read_milestone,
        :read_project_snippet,
        :read_team_member,
        :read_merge_request,
        :read_note,
        :write_project,
        :write_issue,
        :write_note
      ]
    end

    def project_report_rules
      project_guest_rules + [
        :download_code,
        :fork_project,
        :write_project_snippet
      ]
    end

    def project_dev_rules
      project_report_rules + [
        :write_merge_request,
        :write_wiki,
        :push_code
      ]
    end

    def project_archived_rules
      [
        :write_merge_request,
        :push_code,
        :push_code_to_protected_branches,
        :modify_merge_request,
        :admin_merge_request
      ]
    end

    def project_master_rules
      project_dev_rules + [
        :push_code_to_protected_branches,
        :modify_issue,
        :modify_project_snippet,
        :modify_merge_request,
        :admin_issue,
        :admin_milestone,
        :admin_project_snippet,
        :admin_team_member,
        :admin_merge_request,
        :admin_note,
        :admin_wiki,
        :admin_project
      ]
    end

    def project_admin_rules
      project_master_rules + [
        :change_namespace,
        :change_visibility_level,
        :rename_project,
        :remove_project,
        :archive_project
      ]
    end

    def group_abilities user, group
      rules = []

      if group.users.include?(user) || user.admin?
        rules << :read_group
      end

      # Only group owner and administrators can manage group
      if group.has_owner?(user) || user.admin?
        rules += [
          :manage_group,
          :manage_namespace
        ]
      end

      rules.flatten
    end

    def namespace_abilities user, namespace
      rules = []

      # Only namespace owner and administrators can manage it
      if namespace.owner == user || user.admin?
        rules += [
          :manage_namespace
        ]
      end

      rules.flatten
    end

    [:issue, :note, :project_snippet, :personal_snippet, :merge_request].each do |name|
      define_method "#{name}_abilities" do |user, subject|
        if subject.author == user
          [
            :"read_#{name}",
            :"write_#{name}",
            :"modify_#{name}",
            :"admin_#{name}"
          ]
        elsif subject.respond_to?(:assignee) && subject.assignee == user
          [
            :"read_#{name}",
            :"write_#{name}",
            :"modify_#{name}",
          ]
        else
          subject.respond_to?(:project) ? project_abilities(user, subject.project) : []
        end
      end
    end
  end
end
