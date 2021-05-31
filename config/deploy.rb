# frozen_string_literal: true

lock '3.16'

set :user, 'app'
set :application, 'valera'

set :repo_url, 'git@github.com:finfex/valera.git' if ENV['USE_LOCAL_REPO'].nil?
set :keep_releases, 10

set :roles, %w[web app bugsnag].freeze
set :linked_files, %w[.env config/master.key]
set :linked_dirs, %w[log node_modules tmp/pids tmp/cache tmp/sockets public/valera/assets public/packs]

set :config_files, fetch(:linked_files)

set :deploy_to, -> { "/home/#{fetch(:user)}/#{fetch(:application)}" }

set :disallow_pushing, true

# set :db_dump_dir, "./db"
set :db_dump_extra_opts, '--force'

set :branch, ENV.fetch('BRANCH', 'main')
#  ask(:branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp })

set :rbenv_type, :user
set :rbenv_ruby, File.read('.ruby-version').strip

set :nvm_node, File.read('.nvmrc').strip
set :nvm_map_bins, %w[node npm yarn rake]

# Only attempt migration if db/migrate changed - not related to Webpacker, but a nice thing
set :conditionally_migrate, true

# set :assets_roles, %i[webpack] # Give the webpack role to a single server
# set :assets_prefix, 'packs' # Assets are located in /packs/
set :assets_prefix, 'valera/assets' # Assets are located in /packs/
set :assets_dependencies,
    %w[
      app/assets lib/assets vendor/assets app/javascript
      yarn.lock Gemfile.lock config/routes.rb config/initializers/assets.rb
      .semver
    ]

# set :assets_manifests, lambda { # Tell Capistrano-Rails how to find the Webpacker manifests
# [release_path.join('public', fetch(:assets_prefix), 'manifest.json*')]
# }

set :keep_assets, 2
set :local_assets_dir, 'public'

set :puma_init_active_record, true

set :db_local_clean, false
set :db_remote_clean, true

set :puma_control_app, true
set :puma_threads, [2, 4]
set :puma_tag, fetch(:application)
set :puma_daemonize, false
set :puma_preload_app, false
set :puma_prune_bundler, true
set :puma_init_active_record, true
set :puma_workers, 0
set :puma_bind, %w[tcp://0.0.0.0:9293]
set :puma_start_task, 'systemd:puma:start'

set :init_system, :systemd

set :bugsnag_api_key, ENV['BUGSNAG_API_KEY']
set :app_version, SemVer.find.to_s

after 'deploy:check', 'master_key:check'
after 'deploy:publishing', 'systemd:puma:reload-or-restart'
after 'deploy:publishing', 'systemd:daemon:reload-or-restart'
after 'deploy:published', 'bugsnag:release'

set :systemd_daemon_role, :app
set :systemd_daemon_instances, -> { %w[maker poller websocket_collectors] }

# Rake::Task["deploy:assets:backup_manifest"].clear_actions
