# gusEnv.bash
# Set up the environment for developing a GUS application.
#
# usage:
#  $ source gusEnv.bash -local
# or:
#  $ cd my_app_dir
#  $ source gusEnv.bash
#
# The script sets the following environment variables
#  $PROJECT_HOME  - parent for Subversion project source-code directories
#  $GUS_HOME  - parent for executables (installed largely from $PROJECT_HOME by build)
#  $PATH  - bash's ordered list of directories to search for scripts run interactively
#  $PS1  - bash's prompt string, set here to show the host, app name, and pwd
#
# It is assumed that the $PROJECT_HOME and $GUS_HOME are siblings, both under
# the "application directory". If this script is run with the "-local" option,
# it will use the application directory that contains it. For example,
#
# source /home/myApp/project_home/install/bin/gusEnv.bash -local
#
# will use /home/myApp as the application directory, setting PROJECT_HOME to
# /home/myApp/project_home, and so forth. If "-local" is not specified, the
# current $PWD is used as the application directory.
#
# To set $PATH, the script uses the environment variables $PRE_GUS_PATH and
# $POST_GUS_PATH. The resulting path consists of GUS's binary directories
# ($PROJECT_HOME/install/bin and $GUS_HOME/bin) preceeded by $PRE_GUS_PATH
# and followed by $POST_GUS_PATH. If $POST_GUS_PATH is not defined, it is
# set to the initial value of $PATH.

# default to PWD
APP_DIR=$PWD

# override with this script's app dir, if "-local" is specified
if [ "$1" =  "-local" ]
then
  SCRIPT_DIR=`dirname $BASH_SOURCE`
  APP_DIR=`cd ${SCRIPT_DIR}; cd ../../..; pwd`
fi

if [ ! -d ${APP_DIR}/project_home -a ! -L ${APP_DIR}/project_home ]; then
  echo "Error: directory '${APP_DIR}/project_home' does not exist"
#  exit 1
fi

if [ ! -d ${APP_DIR}/gus_home -a ! -L ${APP_DIR}/gus_home ]; then
  echo "Error: directory '${APP_DIR}/gus_home' does not exist"
#  exit 1
fi

if [ ! -n "$POST_GUS_PATH" ]; then
  echo "setting POST_GUS_PATH to previous path"
  export POST_GUS_PATH=$PATH
fi

export PROJECT_HOME=${APP_DIR}/project_home
export GUS_HOME=${APP_DIR}/gus_home
export PATH=$PRE_GUS_PATH/:$PROJECT_HOME/install/bin:$GUS_HOME/bin:$POST_GUS_PATH

pwd=`basename ${APP_DIR}`
PS1="[\h:$pwd \W]$ "

echo
echo PROJECT_HOME: $PROJECT_HOME
echo
echo GUS_HOME: $GUS_HOME
echo
echo PATH: $PATH
echo


