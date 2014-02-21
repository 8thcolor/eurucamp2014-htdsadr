# == Schema Information
#
# Table name: services
#
#  id          :integer          not null, primary key
#  type        :string(255)
#  title       :string(255)
#  token       :string(255)
#  project_id  :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  active      :boolean          default(FALSE), not null
#  project_url :string(255)
#  subdomain   :string(255)
#  room        :string(255)
#  api_key     :string(255)
#

require "gemnasium/gitlab_service"

class GemnasiumService < Service
  validates :token, :api_key, presence: true, if: :activated?

  def title
    'Gemnasium'
  end

  def description
    'Gemnasium monitors your project dependencies and alerts you about updates and security vulnerabilities.'
  end

  def to_param
    'gemnasium'
  end

  def fields
    [
      { type: 'text', name: 'api_key', placeholder: 'Your personal API KEY on gemnasium.com ' },
      { type: 'text', name: 'token', placeholder: 'The project\'s slug on gemnasium.com' }
    ]
  end

  def execute(push_data)
    repo_path = File.join(Gitlab.config.gitlab_shell.repos_path, "#{project.path_with_namespace}.git")
    Gemnasium::GitlabService.execute(
      ref: push_data[:ref],
      before: push_data[:before],
      after: push_data[:after],
      token: token,
      api_key: api_key,
      repo: repo_path
      )
  end
end
