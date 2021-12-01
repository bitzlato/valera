# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

lock '3.16'

set :user, 'app'
set :application, 'valera'

if ENV['USE_LOCAL_REPO'].nil?
  set :repo_url,
      ENV.fetch('DEPLOY_REPO',
                `git remote -v | grep origin | head -1 | awk  '{ print $2 }'`.chomp)
end
set :keep_releases, 10

set :roles, %w[db web app sentry].freeze
set :linked_files, %w[.env config/master.key]
set :linked_dirs,
    %w[log node_modules tmp/pids tmp/cache tmp/sockets public/valera/assets config/credentials public/packs]

set :config_files, fetch(:linked_files)

set :deploy_to, -> { "/home/#{fetch(:user)}/#{fetch(:application)}" }

set :disallow_pushing, true

# set :db_dump_dir, "./db"
set :db_dump_extra_opts, '--force'

default_branch = 'master'
current_branch = `git rev-parse --abbrev-ref HEAD`.chomp

if ENV.key? 'BRANCH'
  set :branch, ENV.fetch('BRANCH')
elsif default_branch == current_branch
  set :branch, default_branch
else
  ask(:branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp })
end

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
set :puma_start_task, 'systemd:puma:start'
set :puma_extra_settings, %{
  lowlevel_error_handler do |e|
    Bugsnag.notify(e) if defined? Bugsnag
    [500, {}, ["An error has occurred"]]
  end
 }

set :init_system, :systemd

set :app_version, SemVer.find.to_s

after 'deploy:check', 'master_key:check'
after 'deploy:publishing', 'systemd:puma:reload-or-restart'
after 'deploy:publishing', 'systemd:daemon:reload-or-restart'

set :systemd_daemon_role, :app

# майкера отключили
# set :systemd_daemon_instances, -> { %w[maker poller websocket_collectors] }
set :systemd_daemon_instances, -> { %w[poller websocket_collectors] }

# Rake::Task["deploy:assets:backup_manifest"].clear_actions

if Gem.loaded_specs.key?('capistrano-sentry')
  set :sentry_organization, ENV['SENTRY_ORGANIZATION']
  set :sentry_release_version, -> { [fetch(:app_version), fetch(:current_version)].compact.join('-') }
  before 'deploy:starting', 'sentry:validate_config'
  after 'deploy:published', 'sentry:notice_deployment'
end
