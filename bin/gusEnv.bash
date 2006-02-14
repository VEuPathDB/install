# set up the environment for developing a GUS application
#
# this script assumes:
#
# (1) you have a directory for your app that contains the sub directories:
#    gus_home/
#    project_home/
#
# (2) that you have two environment variables set up (in your shell start up):
#   $PRE_GUS_PATH   - the PATH to put before the GUS part of the PATH
#   $POST_GUS_PATH  - the PATH to put after the GUS part of the PATH
#
# (3) you have cd'd into the app directory when you run this script 
#
#
# the script sets up:
#  - $GUS_HOME
#  - $PROJECT_HOME
#  - $PATH
#  - a prompt that shows the host, app name, and pwd
#
# to use this script:
#  % cd my_app_dir
#  % source gusEnv.csh
#

if [ ! -d $PWD/project_home ]; then
  echo "Error: directory '$PWD/project_home' does not exist"
  exit 1
fi

if [ ! -d $PWD/gus_home ]; then
  echo "Error: directory '$PWD/gus_home' does not exist"
  exit 1
fi

export PROJECT_HOME=$PWD/project_home
export GUS_HOME=$PWD/gus_home
export PATH=$PRE_GUS_PATH/:$PROJECT_HOME/install/bin:$GUS_HOME/bin:$POST_GUS_PATH

pwd=`basename $PWD`
PS1="[\h:$pwd \W]$ "

echo
echo PROJECT_HOME: $PROJECT_HOME
echo
echo GUS_HOME: $GUS_HOME
echo
echo PATH: $PATH
echo


