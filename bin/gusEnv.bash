# Set up the environment for developing a GUS application, using the current PWD
# as the application directory (the parent to the gus_home and project_home
# directories. It warns (but continues) if either directory does not exist. 
#
# the script sets up:
#  - $GUS_HOME
#  - $PROJECT_HOME
#  - $PATH
#  - a prompt that shows the host, app name, and pwd
#
# To set $PATH, the script uses the environment variables $PRE_GUS_PATH and
# $POST_GUS_PATH. The resulting path consists of GUS's binary directories
# ($PROJECT_HOME/install/bin and $GUS_HOME/bin) preceeded by $PRE_GUS_PATH
# and followed by $POST_GUS_PATH. If $POST_GUS_PATH is not defined, it is
# set to the initial value of $PATH.
#
# usage:
#  $ cd my_app_dir
#  $ source gusEnv.bash

if [ ! -d $PWD/project_home -a ! -L $PWD/project_home ]; then
  echo "Error: directory '$PWD/project_home' does not exist"
#  exit 1
fi

if [ ! -d $PWD/gus_home -a ! -L $PWD/gus_home ]; then
  echo "Error: directory '$PWD/gus_home' does not exist"
#  exit 1
fi

if [ ! -n "$POST_GUS_PATH" ]; then
  echo "setting POST_GUS_PATH to previous path"
  export POST_GUS_PATH=$PATH
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


