require 'sidekiq/web'
require 'api/api'

Gitlab::Application.routes.draw do
  #
  # Search
  #
  get 'search' => "search#show"
  get 'search/autocomplete' => "search#autocomplete", as: :search_autocomplete

  # API
  API::API.logger Rails.logger
  mount API::API => '/api'

  constraint = lambda { |request| request.env["warden"].authenticate? and request.env['warden'].user.admin? }
  constraints constraint do
    mount Sidekiq::Web, at: "/admin/sidekiq", as: :sidekiq
  end

  # Enable Grack support
  mount Grack::Bundle.new({
    git_path:     Gitlab.config.git.bin_path,
    project_root: Gitlab.config.gitlab_shell.repos_path,
    upload_pack:  Gitlab.config.gitlab_shell.upload_pack,
    receive_pack: Gitlab.config.gitlab_shell.receive_pack
  }), at: '/', constraints: lambda { |request| /[-\/\w\.]+\.git\//.match(request.path_info) }, via: [:get, :post]

  #
  # Help
  #
  get 'help'                => 'help#index'
  get 'help/api'            => 'help#api'
  get 'help/api/:category'  => 'help#api', as: 'help_api_file'
  get 'help/markdown'       => 'help#markdown'
  get 'help/permissions'    => 'help#permissions'
  get 'help/public_access'  => 'help#public_access'
  get 'help/raketasks'      => 'help#raketasks'
  get 'help/ssh'            => 'help#ssh'
  get 'help/system_hooks'   => 'help#system_hooks'
  get 'help/web_hooks'      => 'help#web_hooks'
  get 'help/workflow'       => 'help#workflow'
  get 'help/shortcuts'
  get 'help/security'

  #
  # Global snippets
  #
  resources :snippets do
    member do
      get "raw"
    end
  end
  get "/s/:username" => "snippets#user_index", as: :user_snippets, constraints: { username: /.*/ }

  #
  # Public namespace
  #
  namespace :public do
    resources :projects, only: [:index]
    root to: "projects#index"
  end

  #
  # Attachments serving
  #
  get 'files/:type/:id/:filename' => 'files#download', constraints: { id: /\d+/, type: /[a-z]+/, filename:  /.+/ }

  #
  # Admin Area
  #
  namespace :admin do
    resources :users, constraints: { id: /[a-zA-Z.\/0-9_\-]+/ } do
      member do
        put :team_update
        put :block
        put :unblock
      end
    end

    resources :groups, constraints: { id: /[^\/]+/ } do
      member do
        put :project_teams_update
      end
    end

    resources :hooks, only: [:index, :create, :destroy] do
      get :test
    end

    resources :broadcast_messages, only: [:index, :create, :destroy]
    resource :logs, only: [:show]
    resource :background_jobs, controller: 'background_jobs', only: [:show]

    resources :projects, constraints: { id: /[a-zA-Z.\/0-9_\-]+/ }, only: [:index, :show] do
      member do
        put :transfer
      end
    end

    root to: "dashboard#index"
  end

  get "errors/githost"

  #
  # Profile Area
  #
  resource :profile, only: [:show, :update] do
    member do
      get :history
      get :design

      put :reset_private_token
      put :update_username
    end

    scope module: :profiles do
      resource :account, only: [:show, :update]
      resource :notifications, only: [:show, :update]
      resource :password, only: [:new, :create, :edit, :update] do
        member do
          put :reset
        end
      end
      resources :keys
      resources :groups, only: [:index] do
        member do
          delete :leave
        end
      end
      resource :avatar, only: [:destroy]
    end
  end

  match "/u/:username" => "users#show", as: :user, constraints: { username: /.*/ }, via: :get



  #
  # Dashboard Area
  #
  resource :dashboard, controller: "dashboard", only: [:show] do
    member do
      get :projects
      get :issues
      get :merge_requests
    end
  end

  #
  # Groups Area
  #
  resources :groups, constraints: {id: /(?:[^.]|\.(?!atom$))+/, format: /atom/}  do
    member do
      get :issues
      get :merge_requests
      get :members
    end

    resources :users_groups, only: [:create, :update, :destroy]
  end

  resources :projects, constraints: { id: /[^\/]+/ }, only: [:new, :create]

  devise_for :users, controllers: { omniauth_callbacks: :omniauth_callbacks, registrations: :registrations }

  #
  # Project Area
  #
  resources :projects, constraints: { id: /[a-zA-Z.0-9_\-]+\/[a-zA-Z.0-9_\-]+/ }, except: [:new, :create, :index], path: "/" do
    member do
      put :transfer
      post :fork
      post :archive
      post :unarchive
      get :autocomplete_sources
    end

    scope module: :projects do
      resources :blob,      only: [:show, :destroy], constraints: {id: /.+/}
      resources :raw,       only: [:show], constraints: {id: /.+/}
      resources :tree,      only: [:show], constraints: {id: /.+/, format: /(html|js)/ }
      resources :edit_tree, only: [:show, :update], constraints: {id: /.+/}, path: 'edit'
      resources :new_tree,  only: [:show, :update], constraints: {id: /.+/}, path: 'new'
      resources :commit,    only: [:show], constraints: {id: /[[:alnum:]]{6,40}/}
      resources :commits,   only: [:show], constraints: {id: /(?:[^.]|\.(?!atom$))+/, format: /atom/}
      resources :compare,   only: [:index, :create]
      resources :blame,     only: [:show], constraints: {id: /.+/}
      resources :network,   only: [:show], constraints: {id: /(?:[^.]|\.(?!json$))+/, format: /json/}
      resources :graphs,    only: [:show], constraints: {id: /(?:[^.]|\.(?!json$))+/, format: /json/}

      match "/compare/:from...:to" => "compare#show", as: "compare", via: [:get, :post], constraints: {from: /.+/, to: /.+/}

        resources :snippets, constraints: {id: /\d+/} do
          member do
            get "raw"
          end
        end

      resources :wikis, only: [:show, :edit, :destroy, :create], constraints: {id: /[a-zA-Z.0-9_\-]+/} do
        collection do
          get :pages
          put ':id' => 'wikis#update'
          get :git_access
        end

        member do
          get "history"
        end
      end

      resource :wall, only: [:show], constraints: {id: /\d+/} do
        member do
          get 'notes'
        end
      end

      resource :repository, only: [:show] do
        member do
          get "stats"
          get "archive", constraints: { format: Gitlab::Regex.archive_formats_regex }
        end
      end

      resources :services, constraints: { id: /[^\/]+/ }, only: [:index, :edit, :update] do
        member do
          get :test
        end
      end

      resources :deploy_keys, constraints: {id: /\d+/} do
        member do
          put :enable
          put :disable
        end
      end

      resources :branches, only: [:index, :new, :create, :destroy], constraints: { id: Gitlab::Regex.git_reference_regex } do
        collection do
          get :recent, constraints: { id: Gitlab::Regex.git_reference_regex }
        end
      end

      resources :tags, only: [:index, :new, :create, :destroy], constraints: { id: Gitlab::Regex.git_reference_regex }
      resources :protected_branches, only: [:index, :create, :destroy], constraints: { id: Gitlab::Regex.git_reference_regex }

      resources :refs, only: [] do
        collection do
          get "switch"
        end

        member do
          # tree viewer logs
          get "logs_tree", constraints: { id: Gitlab::Regex.git_reference_regex }
          get "logs_tree/:path" => "refs#logs_tree",
            as: :logs_file,
            constraints: {
              id:   Gitlab::Regex.git_reference_regex,
              path: /.*/
            }
        end
      end

      resources :merge_requests, constraints: {id: /\d+/}, except: [:destroy] do
        member do
          get :diffs
          get :automerge
          get :automerge_check
          get :ci_status
        end

        collection do
          get :branch_from
          get :branch_to
          get :update_branches
        end
      end

      resources :hooks, only: [:index, :create, :destroy], constraints: {id: /\d+/} do
        member do
          get :test
        end
      end

      resources :team, controller: 'team_members', only: [:index]
      resources :milestones, except: [:destroy], constraints: {id: /\d+/}

      resources :labels, only: [:index] do
        collection do
          post :generate
        end
      end

      resources :issues, constraints: {id: /\d+/}, except: [:destroy] do
        collection do
          post  :bulk_update
        end
      end

      resources :team_members, except: [:index, :edit], constraints: { id: /[a-zA-Z.\/0-9_\-#%+]+/ } do
        collection do
          delete :leave

          # Used for import team
          # from another project
          get :import
          post :apply_import
        end
      end

      resources :notes, only: [:index, :create, :destroy, :update], constraints: {id: /\d+/} do
        member do
          delete :delete_attachment
        end

        collection do
          post :preview
        end
      end
    end
  end

  root to: "dashboard#show"
end
