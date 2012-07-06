#!/bin/bash
################################################################################
##
##  file:    deploymentTools.sh
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
##        logged in to blender, sets up the environment for the passed site and
##        goes to the site's project_home.  If site_name is omitted, uses
##        DEFAULT_SITE.
##
##     current:
##        displays the current site information
##
##     svnup:
##        updates all subversion projects in the current site's project_home
##
##     svnst:
##        displays svn status of all projects in the current site's project_home
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
##        calls rebuilder on the current site (but does not reload)
##
##     log:
##        displays logs for the current site (using cattail)
##
##     pullProject <proj_1> <proj_2> ...
##        zips projects passed and copies from the current site on the dev
##        server to the PROJECT_HOME on the client machine
##
##     pushProject <proj_1> <proj_2> ...
##        zips projects passed, copies them to the current site on blender, then
##        executes a reload (build plus deploy) on that site
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
##     project:   project for that site (directories in /var/www)
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
##  Lastly, you must source this file in your .bashrc.  Again, this must be done
##  both on your client machine and on your dev server.
##
################################################################################
##  Warning: 
##     Please note that while this script uses gusEnv.bash, using gusEnv.bash
##     independently of this script will lead to inconsistent state.  To reset
##     the related environment variables, run setup <site_name> (see below).
################################################################################

# Constants (should be good for the foreseeable future)
export SITE_REPO=/var/www
export BLENDER_JAVA_HOME=/usr/java/jdk1.7.0
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

function current() {
    assignSiteValues
    echo "Current Site:"
    echo "  Name:     $CURRENT_SITE"
    echo "  Type:     $SITE_TYPE"
    echo "  URL/Dir:  $SITE_DIR"
    echo "  Instance: $SITE_ID"
}

# internal function; pass svn operation to be performed on all your projects
function svnOperation() {
    local operation=$1
    local currentDir=`pwd`
    echo "Performing 'svn $operation' on each project in $PROJECT_HOME"
    for project in `ls $PROJECT_HOME`; do
        cd $PROJECT_HOME/$project
        echo "###################################"
        echo "#####     $project"
        echo "###################################"
        svn $operation
    done
    cd $currentDir
}

function svnst() {
    svnOperation status
}

function svnup() {
    svnOperation update
}

# internal function: single argument
#   Arg 1: please pass Website or WebService
function getTopLevelProject() {
    local topLevelProjectType=$1
    local numWebsiteProjects=`ls $PROJECT_DIR | grep "$topLevelProjectType\$" | wc -l`
    if [ $numWebsiteProjects == 1 ]; then
        echo $(ls $PROJECT_DIR | grep "$topLevelProjectType\$")
    else
        echo "More than one $topLevelProjectType project detected in $PROJECT_DIR" 1>&2
        ls $PROJECT_DIR | grep "$topLevelProjectType\$" 1>&2
        exit 1
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
        exit 1
    else
        export JAVA_HOME=$BLENDER_JAVA_HOME;
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
    sudo instance_manager stop $SITE_TYPE force && sudo instance_manager start $SITE_TYPE
}

function rebuild() {
    assignSiteValues
    rebuilder $SITE_DIR
}

function log() {
    assignSiteValues
    cattail $SITE_DIR
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
        ssh $DEV_SERVER "cd $remoteProjHome; zip -q -r $remoteTmpFile $projectName"
        echo "  Copying zipped project to client..."
        scp $DEV_SERVER:$remoteTmpFile $tmpFile
        ssh $DEV_SERVER "rm -f $remoteTmpFile"

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
            scp $tmpFile $DEV_SERVER:$remoteTmpFile

            # unzip on server and deploy
            echo "  Deploying project $projectName to $SITE_DIR"
            ssh $DEV_SERVER "deployProject $SITE_DIR $projectName"

        else
            echo "  ERROR: project $projectName does not exist; skipping...";
        fi

        rm -f $tmpFile
    done

    echo "Compiling and deploying web app..."
    ssh $DEV_SERVER "setup ${CURRENT_SITE}; reload"

    if [ "$rebuildWebService" == "true" ]; then
        echo "Compiling and deploying web service..."
        ssh $DEV_SERVER "setup ${CURRENT_SITE}; reloadWS"
    fi

    cd $currentDir
}

function deployProject() {

    local tmpFile=~/$ZIPD_PROJ_TMP_FILE
    local projectHome=$SITE_REPO/$1/project_home
    local projectDir=$projectHome/$2

    # set java home and confirm version
    export JAVA_HOME=$BLENDER_JAVA_HOME
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