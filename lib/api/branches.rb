require 'mime/types'

module API
  # Projects API
  class Branches < Grape::API
    before { authenticate! }
    before { authorize! :download_code, user_project }

    resource :projects do
      # Get a project repository branches
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   GET /projects/:id/repository/branches
      get ":id/repository/branches" do
        present user_project.repo.heads.sort_by(&:name), with: Entities::RepoObject, project: user_project
      end

      # Get a single branch
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   branch (required) - The name of the branch
      # Example Request:
      #   GET /projects/:id/repository/branches/:branch
      get ":id/repository/branches/:branch" do
        @branch = user_project.repo.heads.find { |item| item.name == params[:branch] }
        not_found!("Branch does not exist") if @branch.nil?
        present @branch, with: Entities::RepoObject, project: user_project
      end

      # Protect a single branch
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   branch (required) - The name of the branch
      # Example Request:
      #   PUT /projects/:id/repository/branches/:branch/protect
      put ":id/repository/branches/:branch/protect" do
        authorize_admin_project

        @branch = user_project.repository.find_branch(params[:branch])
        not_found! unless @branch
        protected_branch = user_project.protected_branches.find_by(name: @branch.name)
        user_project.protected_branches.create(name: @branch.name) unless protected_branch

        present @branch, with: Entities::RepoObject, project: user_project
      end

      # Unprotect a single branch
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   branch (required) - The name of the branch
      # Example Request:
      #   PUT /projects/:id/repository/branches/:branch/unprotect
      put ":id/repository/branches/:branch/unprotect" do
        authorize_admin_project

        @branch = user_project.repository.find_branch(params[:branch])
        not_found! unless @branch
        protected_branch = user_project.protected_branches.find_by(name: @branch.name)
        protected_branch.destroy if protected_branch

        present @branch, with: Entities::RepoObject, project: user_project
      end

      # Create branch
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   branch_name (required) - The name of the branch
      #   ref (required) - Create branch from commit sha or existing branch
      # Example Request:
      #   POST /projects/:id/repository/branches
      post ":id/repository/branches" do
        authorize_push_project
        @branch = CreateBranchService.new.execute(user_project, params[:branch_name], params[:ref], current_user)

        present @branch, with: Entities::RepoObject, project: user_project
      end
    end
  end
end
