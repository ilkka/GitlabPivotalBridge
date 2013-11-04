from fabric.state import env
from fabric.api import task, run, local
from fabric.context_managers import lcd, cd, settings
from fabric.operations import put, prompt
from datetime import datetime

env.app_name = "gitlabpivotalbridge"
env.basedir = "/opt/%(app_name)s" % env
env.shared_dir = env.basedir + "/shared"
env.manifest_dir = env.shared_dir + "/manifests"
env.puppet_module_dir = env.shared_dir + "/modules"
env.releases_dir = env.basedir + "/releases"
env.now = datetime.utcnow()
env.release_ts = "%d%02d%02d%02d%02d%02d" % \
        (env.now.year, env.now.month, env.now.day,
        env.now.hour, env.now.minute, env.now.second)
env.release_dir = env.releases_dir + "/" + env.release_ts

@task
def deploy():
  prompt("App port: ", "play_port", "9000", "\d+")
  local("play clean compile stage")
  with lcd("target/universal/stage"):
    local("rm -f conf/site.conf")
    run("mkdir -p %s" % env.release_dir)
    with cd(env.release_dir):
      put("*", ".")
      run("echo %s > REVISION" % local("git rev-parse HEAD", capture=True))
    with cd(env.basedir):
      run("rm -f current")
      run("ln -s %s current" % env.release_dir)
  with settings(warn_only=True):
    run("sudo stop %(app_name)s" % env)
  run("mkdir -p %(shared_dir)s" % env)
  put("manifests", env.shared_dir)
  with cd(env.shared_dir):
    run("""FACTER_app_name=%(app_name)s\
           FACTER_app_path=%(release_dir)s\
           FACTER_manifest_path=%(manifest_dir)s\
           FACTER_play_port=%(play_port)s\
           sudo -E puppet\
           apply\
           --detailed-exitcodes\
           --modulepath %(puppet_module_dir)s\
           %(manifest_dir)s/bridge.pp;\
           test $? -le 2
        """ % env)
  with settings(warn_only=True):
    run("sudo restart %(app_name)s" % env)
  with cd(env.releases_dir):
    run("ls -1|head -n -5|xargs rm -rf")

