#!/bin/bash

echo "Basing build on $PROJECT_HOME/install"
cd $PROJECT_HOME/install

fgpUtilVersion=`grep "<fgputil.version>" pom.xml | sed 's/fgputil\.version>//g' | sed 's/[<\/ ]//g'`
echo "Found FgpUtil version $fgpUtilVersion"

echo "Making fresh .fgputil-tmp"
rm -rf .fgputil-tmp
mkdir .fgputil-tmp
cd .fgputil-tmp

echo "Cloning FgpUtil from source"
git clone https://github.com/VEuPathDB/FgpUtil.git
cd FgpUtil

echo "Checking out tags/v$fgpUtilVersion"
git checkout tags/v$fgpUtilVersion

echo "Building FgpUtil"
mvn package

echo "Creating if necessary $GUS_HOME/lib/java"
mkdir -p $GUS_HOME/lib/java

echo "Copying built FgpUtil jars into \$GUS_HOME/lib/java"
echo $(ls -1 */target/*.jar)
cp */target/*.jar $GUS_HOME/lib/java

echo "Copying FgpUtil dependencies into \$GUS_HOME/lib/java"
mvn dependency:copy-dependencies -DoutputDirectory=$GUS_HOME/lib/java

echo "Cleaning up"
cd ../..
rm -rf .fgputil-tmp/FgpUtil

echo "Done"
