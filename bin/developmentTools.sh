#!/bin/bash
################################################################################
##
##  file:    developmentTools.sh
##  author:  Ryan Doherty
##  purpose: provide a variety of tools for assisting EuPath developers
##
##  For a new EuPath front-end developer, there can be a challenge in
##  efficiently interacting with SVN, deploying your code modifications to the
##  development server (e.g. blender), reloading sites, checking logs, etc.  It
##  can be hard to remember which scripts to use and what arguments to pass.
##  The goal of this file is to provide the most common actions with minimal
##  configuration (or things to remember).
##
################################################################################
##
##  Functionality
##
##  When you source this file, you will get a set of default functionality.  You
##  can add additional functions to your .bashrc using the functions below as a
##  model.  Most functions are executed in the context of the "current" site,
##  which you set with the setup function.  If you don't use setup or don't pass
##  an argument, your DEFAULT_SITE is used (set configuration below).  The basic
##  tools are:
##
##     sites:
##        Shows a list of the sites configured in the SITES env variable
##
##     setup [<site_name>]:
##        Sets the "current" site, along with GUS_HOME and PROJECT_HOME.  When
##        logged in to a dev server, sets up the environment for the passed site
##        and goes to the site's project_home.  If site_name is omitted, uses
##        DEFAULT_SITE.
##
##     goto <project_home>:
##        looks for valid directory of $PROJECT_HOME/../<project_home>, then
##        simply <project_home> (i.e. absolute or relative path); if found,
##        sets as new $PROJECT_HOME and visits the directory
##
##     current:
##        displays the current site information
##
##     svnup:
##        updates all subversion projects in the current site's project_home
##
##     svnupnohg:
##        updates all non-mercurial subversion projects in the current site's
##        project_home
##
##     svnst:
##        displays svn status of all projects in the current site's project_home
##
##     hgup:
##        updates local (client) contents to match that in the hg repo for all
##        hg projects in the current site's project_home
##
##     hgst:
##       displays hg status of all projects in the current site's project_home
##
##     reload:
##        builds and (if successful) reloads the website in the current site
##
##     reloadWS:
##        builds and (if successful) reloads the web service in the current site
##
##     restart:
##        restarts the tomcat instance for the current site (unforced)
##
##     restart_force:
##        forces restart of the tomcat instance for the current site
##
##     rebuild:
##        calls rebuilder on the current site (which also reloads)
##
##     gbrowse_install:
##        reinstalls gbrowse on the current site
##
##     log:
##        displays logs for the current site (in tail -f fashion, using cattail)
##
##     pullProject <proj_1> <proj_2> ...
##        zips projects passed and copies from the current site on the dev
##        server to the PROJECT_HOME on the client machine
##
##     pushProject <proj_1> <proj_2> ...
##        zips projects passed, copies them to the current site on the dev
##        server, then executes a reload (i.e. build plus reload) on that site
##
##     pushHg <proj_1> <proj_2> ...
##        commits and pushes changes from client hg projects to your hg repo,
##        then pulls and updates those changes on the current site, and reloads
##        the current site.  An effort is made to only recompile Java code when
##        necessary* (*not yet functional!).
##
##     pushFiles <proj_1> <proj_2> ...
##        copies all files that have current SVN changes from a remote machine
##        into the current site's project home; then reloads the current site
##
##     sendFiles <proj_1> <proj_2> ...
##        copies all files that have current SVN changes from a remote machine
##        into the current site's project home
##
##     deployProject <site_dir> <project_name>
##        (not to be called directly!) This utility is called remotely by
##        pushProject. It unzips a project placed on the server and deploys it
##        to the appropriate project_home.  It also backs up (up to) the
##        previous versions of the project with .old and .older suffixes.
##
################################################################################
##
##  Prerequisites/Setup:
##
##  For full functionality, you should do all the following on both your client
##  machine, and in your user account on your development server (e.g. blender).
##
##  The develper should already have added custom GUS configuration to their
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
##  5. (Optional) Define your Mercurial repository if you are using one to
##  quickent changeset deploytment on your dev server.  The value is an absolute
##  path or one relative to your home directory on the server.  For example:
##
##     export 
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
export DEV_SITE_JAVA_HOME=/usr/java/jdk1.7.0
export ZIPD_PROJ_TMP_FILE=".tmpProject.zip" # will be written to you home dir

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
        export PROJECT_HOME=$SITE_REPO/$SITE_DIR/project_home
        export GUS_HOME=$PROJECT_HOME/../gus_home
        export PATH=$PRE_GUS_PATH:$PROJECT_HOME/install/bin:$GUS_HOME/bin:$POST_GUS_PATH
        cd $SITE_REPO/$SITE_DIR
        source project_home/install/bin/gusEnv.bash
        cd project_home
    else
        echo "--------------- Warning ---------------"
        echo "$SITE_REPO/$SITE_DIR does not exist!  Assuming you are on a client machine (not $DEV_SERVER)."
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
    echo "Current Site:"
    echo "  Name:     $CURRENT_SITE"
    echo "  Type:     $SITE_TYPE"
    echo "  URL/Dir:  $SITE_DIR"
    echo "  Instance: $SITE_ID"
}

# internal function; pass svn operation to be performed on all your projects
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

function svnst() {
    projectOperation "svn status" .svn
}

function svnup() {
    projectOperation "svn update" .svn
}

function svnupnohg() {
    projectOperation "svnupnohg_proj" .svn
}

function svnupnohg_proj() {
    if [ ! -e .hg ]; then
        svn update
    else
        echo "Skipping, as this project contains .hg"
    fi
}

function hgst() {
    projectOperation "hg status" .hg
}

function hgup() {
    projectOperation "hg pull ssh://$REMOTE_LOGNAME@$DEV_SERVER//home/$REMOTE_LOGNAME/hgrepo/#project# && hg update" .hg
}

# internal function: single argument
#   Arg 1: please pass Website or WebService
function getTopLevelProject() {
    local topLevelProjectType=$1
    local numWebsiteProjects=`\ls $PROJECT_HOME | grep "$topLevelProjectType\$" | wc -l`
    if [[ $numWebsiteProjects -eq 1 ]]; then
        local topLevel=$(\ls $PROJECT_HOME | grep "$topLevelProjectType\$")
        if [[ "$topLevel" == "ApiCommonWebsite" ]]; then
          topLevel="EuPathPresenters";
        fi
        echo $topLevel
    else
        echo "Zero or more than one $topLevelProjectType project detected in $PROJECT_HOME" 1>&2
        ls $PROJECT_HOME | grep "$topLevelProjectType\$" 1>&2
    fi
}

# internal function: two arguments
#   Arg 1: please pass Website or WebService
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

function reload() {
    reloadGeneric Website etc/webapp.prop
}

function reloadWS() {
    reloadGeneric WebService etc/wsf.prop
}

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

function pullProject() {
    local currentDir=`pwd`
    cd $PROJECT_HOME

    assignSiteValues
    
    local tmpFile=~/$ZIPD_PROJ_TMP_FILE
    local remoteTmpFile=/home/$LOGNAME/$ZIPD_PROJ_TMP_FILE
    local remoteProjHome=$SITE_REPO/$SITE_DIR/project_home

    echo "Retrieving project(s) from $CURRENT_SITE"

    for projectName in $*; do

        echo "Processing $projectName"
        echo "  Zipping up project on $DEV_SERVER"
        ssh $REMOTE_LOGNAME@$DEV_SERVER "cd $remoteProjHome; zip -q -r $remoteTmpFile $projectName"
        echo "  Copying zipped project to client..."
        scp $REMOTE_LOGNAME@$DEV_SERVER:$remoteTmpFile $tmpFile
        ssh $REMOTE_LOGNAME@$DEV_SERVER "rm -f $remoteTmpFile"

        # check to see if project was successfully transferred
        if [ -e $tmpFile ]; then
        
            # see if local project versions exist and back up if so
            if [ -d ${projectName}.old ]; then
                echo "  Moving ${projectName}.old to ${projectName}.older"
                mv ${projectName}.old ${projectName}.older
            fi
            if [ -d $projectName ]; then
                echo "  Moving $projectName to ${projectName}.old"
                mv $projectName ${projectName}.old
            fi

            # move local zip file to project home and unzip
            echo "  Extracting $projectName from zip file into $(pwd)"
            unzip -q -d . $tmpFile
            rm $tmpFile
        else
            echo "  Unable to successfully transfer project ${projectName}.  Skipping."
        fi
        
    done
    cd $currentDir
}

function gbrowse_install() {
  assignSiteValues
  $SITE_REPO/$SITE_DIR/project_home/ApiCommonWebsite/Model/bin/install_gbrowse2 $SITE_REPO/$SITE_DIR/etc/webapp.prop build_install_patch
}

function pushFiles() {
  sendFiles $*
  echo -n "Building code..."
  ssh $REMOTE_LOGNAME@$DEV_SERVER "setup ${CURRENT_SITE} >& /dev/null; reload"
  echo "done."
}

function sendFiles() {

  local currentDir=`pwd`;
  assignSiteValues

  for projectName in $*; do
    echo "Processing $projectName"
    cd $PROJECT_HOME/$projectName
    for file in $(svn st | awk '{ if ($1 != "D") { print $NF; } }'); do
      cmd="scp $file $REMOTE_LOGNAME@$DEV_SERVER:$SITE_REPO/$SITE_DIR/project_home/$projectName/$file"
      echo "  Running $cmd"
      $cmd
    done
  done

  cd $currentDir
  echo "File transfers complete."
}

function pushHg() {
  local currentDir=`pwd`
  assignSiteValues

  for projectName in $*; do

    cd $PROJECT_HOME/$projectName

    echo; echo "%%%%% Committing ${projectName}..."
    hg commit -m "checkpoint commit"
    echo; echo "%%%%% Pushing ${projectName}..."
    hg push
    echo; echo "%%%%% Pulling ${projectName}..."
    ssh $REMOTE_LOGNAME@$DEV_SERVER "setup ${CURRENT_SITE} >& /dev/null; cd $projectName; hg pull"
    echo; echo "%%%%% Updating ${projectName}..."
    ssh $REMOTE_LOGNAME@$DEV_SERVER "setup ${CURRENT_SITE} >& /dev/null; cd $projectName; hg update"

  done
  
  local numJava=$(hg status | grep ".java" | wc -l | awk '{ print $1 }');
  local loadCmd
  #if [ "$numJava"=="0" ]; do
  #  Example: bldw WDK/View <your_webapp.prop>; bldw ApiCommonWebsite/Site <your_webapp.prop>
  #  loadCmd="reload" # <-- FIX ME TO ONLY MOVE FILES, NOT BUILD JAVA!!
  #else
    loadCmd="reload"
  #fi
  
  echo; echo -n "Building code..."
  ssh $REMOTE_LOGNAME@$DEV_SERVER "setup ${CURRENT_SITE} >& /dev/null; $loadCmd"
  cd $currentDir
  echo "done."
}

function pushProject() {
    local currentDir=`pwd`

    assignSiteValues
    local tmpFile=~/$ZIPD_PROJ_TMP_FILE
    local remoteTmpFile=/home/$LOGNAME/$ZIPD_PROJ_TMP_FILE
    local projectHome=$PROJECT_HOME
    local projectDir=

    echo "Deploying project(s) to $CURRENT_SITE"

    local rebuildWebService=false
    for projectName in $*; do

        echo "Processing $projectName"

        if [[ $projectName =~ .*WebService ]]; then
            echo "  Turning on Web Service flag"
            rebuildWebService=true
        fi

        projectDir=$projectHome/$projectName

        if [ -e $projectDir ]; then
        
            # zip project for import
            rm -f $tmpFile
            cd $projectDir

            echo "  Cleaning .class files from project"
            find . -name "*.class" | xargs rm
            cd ..

            echo "  Zipping $projectName for copy"
            zip -q -r $tmpFile $projectName

            # copy zip file to server
            echo "  Transferring file"
            scp $tmpFile $REMOTE_LOGNAME@$DEV_SERVER:$remoteTmpFile

            # unzip on server and deploy
            echo "  Deploying project $projectName to $SITE_DIR"
            ssh $REMOTE_LOGNAME@$DEV_SERVER "deployProject $SITE_DIR $projectName"

        else
            echo "  ERROR: project $projectName does not exist; skipping...";
        fi

        rm -f $tmpFile
    done

    echo "Compiling and deploying web app..."
    ssh $REMOTE_LOGNAME@$DEV_SERVER "setup ${CURRENT_SITE}; reload"

    if [ "$rebuildWebService" == "true" ]; then
        echo "Compiling and deploying web service..."
        ssh $REMOTE_LOGNAME@$DEV_SERVER "setup ${CURRENT_SITE}; reloadWS"
    fi

    cd $currentDir
}

function deployProject() {

    local tmpFile=~/$ZIPD_PROJ_TMP_FILE
    local projectHome=$SITE_REPO/$1/project_home
    local projectDir=$projectHome/$2

    # set java home and confirm version
    export JAVA_HOME=$DEV_SITE_JAVA_HOME
    echo "  Java Version: $($JAVA_HOME/bin/java -version 2>&1 | grep version | sed 's/.*\"\(.*\)\"/\1/g')"

    if [ $# != 2 ]; then
        echo "USAGE: deployProject <site_dir> <project_name>";
        exit 1;
    elif [ -d $projectDir ]; then
        if [ -e $tmpFile ]; then
            # move old versions
            if [ -e ${projectDir}.older ]; then
                echo "  Removing ${projectDir}.older";
                rm -rf ${projectDir}.older
            fi
            if [ -e ${projectDir}.old ]; then
                echo "  Moving ${projectDir}.old to ${projectDir}.older";
                mv ${projectDir}.old ${projectDir}.older
            fi
            echo "  Moving $projectDir to ${projectDir}.old";
            mv $projectDir ${projectDir}.old

            # extract project
            echo "  Extracting project to $projectDir";
            unzip -q $tmpFile -d $projectHome
        else
            echo "ERROR: No files have been sent (looking for $tmpFile)";
            exit 3;
        fi
    else
        echo "ERROR: $1 is not a project";
        exit 2;
    fi
}
