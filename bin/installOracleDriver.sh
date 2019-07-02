#!/bin/bash
###########################################################################
##
## This script is meant to be run on UNIX-based development clients to copy
## the appropriate Oracle driver from a dev server into all the locations
## required for EuPathDB software development.  Currently those are as
## follows:
##    1. $ORACLE_HOME/jdbc/lib
##    2. $GUS_HOME/lib/java/db_driver
##    3. The appropriate location in your local maven repository
##
###########################################################################
## constants related to this script (subject to change)
###########################################################################

# dependency definition
groupId=com.oracle
artifactId=ojdbc8
version=12.2.0.1

# dependency location
serverOracleHome=/u01/app/oracle/product/$version/db_12
jarFileName=ojdbc8.jar

###########################################################################

set -e

# derivative globals
localLoc=$HOME/$jarFileName
gusLibDriverDir=$GUS_HOME/lib/java/db_driver
previousVersionPattern=ojdbc*.jar
oraHomeLib=$ORACLE_HOME/jdbc/lib

function getDriver {
  
  # variables created by the constants above (may be subject to change but less likely)
  remoteLogin=$1
  remoteLoc=${remoteLogin}:$serverOracleHome/jdbc/lib/$jarFileName

  # create db_driver dir if not yet present
  mkdir -p $gusLibDriverDir

  # copy file from server to local temp location
  echo "Transferring file from ${remoteLoc}"
  scp ${remoteLoc} ${localLoc}

  # copy into local maven repository
  echo "Installing driver into local maven repository"
  mvn install:install-file -DgroupId=${groupId} -DartifactId=${artifactId} \
      -Dversion=${version} -Dpackaging=jar -Dfile=${localLoc} -DgeneratePom=true

  # copy into GUS_HOME/lib and remove previous driver versions
  echo "Removing the following drivers from GUS HOME:"
  ls -1 ${gusLibDriverDir}/${previousVersionPattern} 2>/dev/null || echo "  No old drivers found."
  rm -f ${gusLibDriverDir}/${previousVersionPattern}
  echo "Installing driver into ${gusLibDriverDir}"
  mv ${localLoc} ${gusLibDriverDir}

  # copy into user's ORACLE_HOME
  if [ -e $oraHomeLib/$jarFileName ]; then
    echo "Oracle driver by name $jarFileName already exists in $oraHomeLib"
  else
    if [ -d $oraHomeLib ]; then
      echo "Installing driver into $oraHomeLib"
      cp ${gusLibDriverDir}/$jarFileName $oraHomeLib
    else
      echo "WARNING: driver could not be copied into \$ORACLE_HOME/jdbc/lib"
      echo "   Please check your environment variable and ensure the directory exists."
    fi
  fi
  
  echo "Done."
}

if [ "$#" != "1" ]; then
  echo "USAGE: installOracleDriver.sh [<user>@]<server>"
  echo "    user  : existing user on the remote EuPathDB server"
  echo "    server: EuPathDB server from which to retrieve the Oracle driver"
  exit 0
fi

if [ "$1" == "-m" ]; then
  echo "Will install driver to GUS_HOME from local Maven repository"
  if [ "$M2_REPO" == "" ]; then
    M2_REPO=~/.m2/repository
  fi
  mvnJarPath=`echo $groupId/$artifactId | sed 's/\./\//g'`
  mvnJarPath=$M2_REPO/$mvnJarPath/$version/$artifactId-${version}.jar
  echo "Copying $mvnJarPath to $gusLibDriverDir/$jarFileName"
  cp $mvnJarPath $gusLibDriverDir/$jarFileName
else
  getDriver $1
fi
