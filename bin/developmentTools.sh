#!/bin/bash
################################################################################
##
##  file:    developmentTools.sh
##  author:  Ryan Doherty
##  purpose: provide a variety of tools for assisting VEuPathDB developers
##
##  For a VEuPathDB website developer, there can be a challenge to efficiently
##  interacting with Git, deploying your code modifications to the development
##  server (e.g. blender), reloading sites, checking logs, etc.  It's also
##  hard to remember which sites you have to work with, and what values to use
##  to set a website context and interact with instance_manager.  The goal of
##  this script's utilities is to provide the most common actions with minimal
##  configuration (or things to remember).
##
################################################################################
##
##  Functionality
##
##  When you source this file, you will get a set of default functionality.  You
##  can add additional functions to your .bashrc using the functions below as a
##  model.  Most functions are executed in the context of the "current" site,
##  which you set with the setup function.  If you don't call 'setup' or don't
##  pass an argument, your DEFAULT_SITE is used (see Configuration section below).
##
##  Commands useful in both client (laptop) and remote (dev server) contexts:
##
##     sites:
##        Display of the sites configured in the SITES env variable
##
##     setup [<site_name>]:
##        Sets the "current" site, along with GUS_HOME and PROJECT_HOME.  When
##        logged in to a dev server, sets up the environment for the passed site
##        and goes to the site's project_home.  When on a client machine, sets
##        the website to be used when client-based commands are called.  If
##        site_name is omitted, uses DEFAULT_SITE.
##
##     current:
##        displays the current site and environment information
##
##     gitst:
##        runs git status on each git project in $PROJECT_HOME
##
##     getup:
##        runs git pull on each git project in $PROJECT_HOME
##
##  Commands useful in a remote (dev server) context:
##
##     reload:
##        reloads the webapp in the current site
##
##     rebuild_lite:
##        builds and (if successful) reloads the webapp for the current site
##
##     rebuild:
##        calls rebuilder on the current site (undeploy, clean, update, build, configure, redeploy)
##
##     restart:
##        restarts the tomcat instance for the current site (unforced)
##
##     restart_force:
##        forces restart of the tomcat instance for the current site
##
##     log:
##        ongoing display of logs for the current site
##          (in tail -f fashion, calls cattail)
##
##     logall:
##        ongoing display of all logs for the current site
##          (in tail -f fashion, calls cattail -atc)
##
##  Commands useful in a client (laptop) context:
##
##     goto <project_home>:
##        looks for valid directory of $PROJECT_HOME/../<project_home>, then
##        simply <project_home> (i.e. absolute or relative path); if found,
##        sets as new $PROJECT_HOME and visits the directory
##
##     sendFiles <proj_1> <proj_2> ...
##        copies all files that have current git modifications from a remote machine
##        into the current site's project home
##
##     sendFilesAndRebuild <proj_1> <proj_2> ...
##        calls send
##
################################################################################
##
##  Prerequisites/Configuration:
##
##  For full functionality, you should do all the following on both your client
##  machine, and in your user account on your development server (e.g. blender).
##
##  The developer should already have added custom GUS configuration to their
##  .bashrc file for use in sourcing gusEnv.bash.  (At least) the following
##  values should already be defined:
##
##     $PRE_GUS_PATH   - the PATH to put before the GUS part of the PATH
##     $POST_GUS_PATH  - the PATH to put after the GUS part of the PATH
##
##  If you haven't already, you also need to define PROJECT_HOME and GUS_HOME
##  for your local project repository (e.g. /home/rdoherty/projects).  These
##  will be overridden when appropriate.
##
##  There are three additional variables to set in order to use these tools:
##
##  1. Define your dev sites in a bash array.  See example below.  The four
##  values to configure are (colon-delimited):
##
##     site_name: your nickname for that site
##     project:   project type for that site (directories in /var/www)
##     site_url:  url of YOUR site (as seen in /var/www)
##     instance:  instance name (as seen in /var/www/<project>)
##
##  For example:
##     export SITES=( "Crypto:CryptoDB:rdoherty.cryptodb.org:cryptodb.rdoherty"
##                    "Ortho:OrthoMCL:rdoherty.orthomcl.org:orthomcl.rdoherty"
##                    "Plasmo:PlasmoDB:rdoherty.plasmodb.org:plasmo.rdoherty"
##                    "Tritryp:TriTrypDB:rdoherty.tritrypdb.org:tritrypdb.rdoherty" )
##
##  2. Define a default site (by name as you just specified).  For example:
##
##     export DEFAULT_SITE=Plasmo
##
##  3. Define the server that your sites live on (it is expected that you have
##  some sort of authentication mechanism in place that ensures calls to ssh and
##  scp do NOT prompt for your password).  For example:
##
##     export DEV_SERVER=blender.pcbi.upenn.edu
##
##  4. (Optional) Define the account name to login as on the development server.
##  If you do not specify a name as follows, $(logname) will be used.
##
##     export REMOTE_LOGNAME=rdoherty
##
##  Lastly, you must source this file in your .bashrc.  Again, this must be done
##  both on your client machine and on your dev server.
##
################################################################################
##  Warning: 
##     Please note that while this script uses gusEnv.bash, using gusEnv.bash
##     independently of this script will lead to inconsistent state.  To reset
##     the related environment variables, run "setup <site_name>" (see above).
################################################################################

# Constants (should be good for the foreseeable future)
export SITE_REPO=/var/www

function sites() {
    echo "Available sites:"
    echo "  Name: ( Type , URL/Dir , Instance )"
    local dataArray=
    for siteData in ${SITES[@]}; do
        dataArray=( $(echo $siteData | sed 's/:/ /g') )
        echo "  ${dataArray[0]}: ( ${dataArray[1]} , ${dataArray[2]} , ${dataArray[3]} )"
    done
}

function getSiteData() {

    local currentSite=$CURRENT_SITE
    local found=false
    local siteData
    local dataArray
    local key

    if [ "$currentSite" == "" ]; then
        currentSite=$DEFAULT_SITE
    fi
    
    for siteData in ${SITES[@]}; do
        dataArray=( $(echo $siteData | sed 's/:/ /g') )
        key=${dataArray[0]}
        if [ "$key" == "$currentSite" ]; then
            found=true
            echo "${dataArray[@]}";
        fi
    done

    if [ $found == false ]; then
        echo "Error: Invalid site key: ${CURRENT_SITE}.  Unset, or set to valid value." 1>&2
        exit 1
    fi
}

function assignSiteValues() {
    local dataArray=( $(getSiteData) )
    export CURRENT_SITE=${dataArray[0]}
    export SITE_TYPE=${dataArray[1]}
    export SITE_DIR=${dataArray[2]}
    export SITE_ID=${dataArray[3]}
    if [ "$REMOTE_LOGNAME" == "" ]; then
        export REMOTE_LOGNAME=$(logname)
    fi
    #echo "Found site $CURRENT_SITE in site repository.  Will use: $SITE_TYPE $SITE_DIR $SITE_ID" 1>&2
}

function setup() {
    if [ "$1" != "" ]; then
        if [ "$CURRENT_SITE" == "" ]; then
            echo "Setting current site to $1" 1>&2
        else
            echo "Changing current site from $CURRENT_SITE to $1" 1>&2
        fi
        export CURRENT_SITE=$1
    fi

    assignSiteValues

    if [ -d $SITE_REPO/$SITE_DIR ]; then
        export BASE_GUS=$SITE_REPO/$SITE_DIR
        export PROJECT_HOME=$BASE_GUS/project_home
        export GUS_HOME=$BASE_GUS/gus_home
        export PATH=$PROJECT_HOME/install/bin:$GUS_HOME/bin:$NON_GUS_PATH
        cd $SITE_REPO/$SITE_DIR
    else
        echo "--------------- Warning ---------------"
        echo "$SITE_REPO/$SITE_DIR does not exist.  Assuming you are on a client machine (not $DEV_SERVER)."
        echo "Retaining the following values:"
        echo "  GUS_HOME     = $GUS_HOME"
        echo "  PROJECT_HOME = $PROJECT_HOME"
    fi
}

function goto() {
    local newProjectHome=$1
    local changed=0
    if [ -d $PROJECT_HOME/../$newProjectHome ]; then
        cd $PROJECT_HOME/../$newProjectHome
        changed=1
    elif [ -d $newProjectHome ]; then
        cd $newProjectHome
        changed=1
    fi
    if [ "$changed" == "1" ]; then
        echo "\$PROJECT_HOME changed from $PROJECT_HOME to $(pwd)"
        export PROJECT_HOME=$(pwd)
    else
        echo "No action taken. Cannot find directory: $newProjectHome"
    fi
}

function current() {
    assignSiteValues
    echo "Environment:"
    echo "  GUS_HOME:     $GUS_HOME"
    echo "  PROJECT_HOME: $PROJECT_HOME"
    echo "Current Site:"
    echo "  Name:         $CURRENT_SITE"
    echo "  Type:         $SITE_TYPE"
    echo "  URL/Dir:      $SITE_DIR"
    echo "  Instance:     $SITE_ID"
}

# internal function; pass operation to be performed on all your projects
function projectOperation() {
    local operation=$1
    local currentDir=`pwd`
    echo "Performing '$operation' on each project in $PROJECT_HOME"
    for project in `\ls $PROJECT_HOME`; do
        if [ -d $PROJECT_HOME/$project ]; then
            cd $PROJECT_HOME/$project
            if [ -e $2 ]; then
                echo "###################################"
                echo "#####     $project"
                echo "###################################"
                operation=$(echo $operation | sed "s/#project#/${project}/")
                $operation
            else
                echo "Skipping ${project}..."
            fi
        else
            echo "Skipping ${project}..."
        fi
    done
    cd $currentDir
}

function gitst() {
    projectOperation "git status" .git
}

function gitup() {
    projectOperation "git pull" .git
}

# internal function: single argument
#   Arg 1: pass Website or WebService
function getTopLevelProject() {
    local topLevelProjectType=$1
    local numWebsiteProjects=`\ls $PROJECT_HOME | grep "$topLevelProjectType\$" | wc -l`
    local numPresenterProjects=`\ls $PROJECT_HOME | grep "Presenters\$" | wc -l`
    # favor *Presenters projects over *Website projects
    if [[ $numPresenterProjects -eq 1 ]]; then
        local topLevelProject=$(\ls $PROJECT_HOME | grep "Presenters\$")
        echo $topLevelProject
    elif [[ $numWebsiteProjects -eq 1 ]]; then
        local topLevelProject=$(\ls $PROJECT_HOME | grep "$topLevelProjectType\$")
        echo $topLevelProject
    else
        echo "Zero or more than one $topLevelProjectType project detected in $PROJECT_HOME" 1>&2
        ls $PROJECT_HOME | grep "$topLevelProjectType\$" 1>&2
        exit 1
    fi
}

# internal function: two arguments
#   Arg 1: pass Website or WebService
#   Arg 2: pass config file for the given site type, relative to the site_dir
function reloadGeneric() {
    local topLevelProjectType=$1
    local configFile=$2
    assignSiteValues
    local project=$(getTopLevelProject $topLevelProjectType)
    if [ "$project" == "" ]; then
        echo "Cannot determine $topLevelProjectType to reload."
        echo "Please ensure exactly one $topLevelProjectType project exists in $PROJECT_HOME"
    else
        export JAVA_HOME=$DEV_SITE_JAVA_HOME;
        bldw $project $SITE_REPO/$SITE_DIR/$configFile && instance_manager manage $SITE_TYPE reload $SITE_ID
    fi
}

# Note implementation of this is somewhat antiquated
function rebuild_lite() {
    reloadGeneric Website etc/webapp.prop
}

# No longer needed; website and webservice projects are built together
#function rebuild_lite_WS() {
#    reloadGeneric WebService etc/wsf.prop
#}

function restart() {
    assignSiteValues
    sudo instance_manager restart $SITE_TYPE
}

function restart_force() {
    assignSiteValues
    sudo instance_manager stop $SITE_TYPE force && \
        echo "Waiting for tomcat shutdown..." && \
        sleep 5 && \
        sudo instance_manager start $SITE_TYPE
}

function reload() {
    assignSiteValues
    instance_manager manage $SITE_TYPE reload $SITE_ID
}

function rebuild() {
    assignSiteValues
    rebuilder $SITE_DIR
}

function log() {
    assignSiteValues
    cattail $SITE_DIR
}

function logall() {
    assignSiteValues
    cattail -atc $SITE_DIR
}

function sendFilesAndRebuild() {
  sendFiles $*
  echo -n "Building code..."
  ssh $REMOTE_LOGNAME@$DEV_SERVER "setup ${CURRENT_SITE} >& /dev/null; rebuild_lite"
  echo "done."
}

function sendFiles() {

  local currentDir=`pwd`;
  assignSiteValues

  for projectName in $*; do
    echo "Processing $projectName"
    cd $PROJECT_HOME/$projectName
    projectDir="$SITE_REPO/$SITE_DIR/project_home/$projectName"
    remoteProjectDir="$REMOTE_LOGNAME@$DEV_SERVER:$projectDir"

    for fileStatus in $(git status -s | awk '{ print $1 ":" $2 }'); do

      changedFile=( $(echo $fileStatus | sed 's/:/ /g') )
      flag="${changedFile[0]}"
      file="${changedFile[1]}"

      cmd=""
      if [[ "$flag" == "A" || "$flag" == "M" || "$flag" == "??" ]]; then
        if [ -d $file ]; then
          # recursively remove existing dir
          cmd="ssh $REMOTE_LOGNAME@$DEV_SERVER \"\"rm -rf $projectDir/$file\"\""
          echo "  $cmd"
          $cmd
          cmd="rsync -r $file $remoteProjectDir/$file"
        else
          cmd="rsync $file $remoteProjectDir/$file"
        fi
      elif [[ "$flag" == "D" ]]; then
        if [ -d $file ]; then
          cmd="ssh $REMOTE_LOGNAME@$DEV_SERVER \"\"rm -rf $projectDir/$file\"\""
        else
          cmd="ssh $REMOTE_LOGNAME@$DEV_SERVER \"\"rm -f $projectDir/$file\"\""
        fi
      fi

      if [[ "$cmd" != "" ]]; then
        echo "  $cmd"
        $cmd
      else
        echo "  Skipping $file"
      fi
    done
  done

  cd $currentDir
  echo "File transfers complete."
}


