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

# To add new service you should build a class inherited from Service
# and implement a set of methods
class Service < ActiveRecord::Base
  default_value_for :active, false

  attr_accessible :title, :token, :type, :active, :api_key

  belongs_to :project
  has_one :service_hook

  validates :project_id, presence: true

  def activated?
    active
  end

  def title
    # implement inside child
  end

  def description
    # implement inside child
  end

  def to_param
    # implement inside child
  end

  def fields
    # implement inside child
    []
  end

  def execute
    # implement inside child
  end

  def can_test?
    !project.empty_repo?
  end
end
