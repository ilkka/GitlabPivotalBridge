# Capfile for deployment
#
# Assumptions:
#  - Puppet is installed on the server(s)
#  - There is a regular user 'deploy' on the server(s)
#  - That user has write access to /opt
#  - That user accepts my SSH key
#  - That user can sudo to run "puppet" and set env vars, .e.g:
#  
#  # Example 'deploy' user sudoers line
#  deploy ALL = (ALL:ALL) NOPASSWD: SETENV: /usr/bin/puppet, /sbin/start, /sbin/stop
#
require 'rubygems'
require 'playframework/capistrano'
require 'etc'

load 'deploy'

set :application, 'GitlabPivotalBridge'
set :repository,  'git@github.com:ilkka/GitlabPivotalBridge.git'

set :ssh_options, { :forward_agent => true }

default_run_options[:pty] = true # should help with sudo password prompts, see http://stackoverflow.com/questions/431925/capistrano-is-hanging-when-prompting-for-sudo-password-to-an-ubuntu-box

set :scm,    :git
set :branch, 'master'

set :user,           fetch(:user, 'deploy')
set :use_sudo,       false
set :deploy_to,      "/opt/#{application}"
set :prod_conf_path, "#{release_path}/conf/prod.conf"

after "deploy", "deploy:cleanup"
after "deploy:start", "start"
after "deploy:stop", "stop"
after "deploy:restart", "restart"
before "deploy:restart", "puppet"

depend :remote, :command, "puppet"

task :start do
  run "#{sudo} /sbin/start gitlabpivotalbridge"
end

task :stop do
  run "#{sudo} /sbin/stop gitlabpivotalbridge"
end

task :restart do
  run "#{sudo} /sbin/restart gitlabpivotalbridge"
end

task :puppet do
  transaction do
    run "env "\
      "FACTER_app_path=#{release_path} "\
      "#{sudo} -E puppet apply #{release_path}/manifests/bridge.pp"
  end
end

# vim: ft=ruby
