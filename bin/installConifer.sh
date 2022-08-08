#!/bin/bash
#####################################################################
###
###  Installs conifer from project_home/conifer to gus_home
###
###  To do this, finds the cohort represented by the projects
###  in project_home and then calls conifer install with that cohort
###
#####################################################################

# ensure correct number of arguments
if (( $# != 2 )); then
  >&2 echo "USAGE: installConifer.sh <gus_home> <project_home>"
  exit 1
fi

# name arguments
gus_home=$1
project_home=$2

# check gus_home
if ! [ -d "$gus_home" ]; then
  >&2 echo "ERROR: Missing directory for gus_home: $gus_home"
  exit 1
fi

# check project_home
if ! [ -d "$project_home" ]; then
  >&2 echo "ERROR: Missing directory for project_home: $project_home"
  exit 1
fi

# Define the supported cohorts based on presence of a certain project
# Note: these must match the cohort mapping in the conifer script
cohorts=( "ApiCommonWebsite:ApiCommon"
          "OrthoMCLWebsite:OrthoMCL"
          "ClinEpiWebsite:ClinEpi"
          "MicrobiomeWebsite:Microbiome"
          "WDKTemplateSite:WDKTemplate"
          "EuPathDBIrods:EuPathDBIrods" )

# search projects for one representing a single cohort; skip conifer if >1 or none
for siteData in ${cohorts[@]}; do
  map=( $(echo $siteData | sed 's/:/ /g') )
  if [ -d "$project_home/${map[0]}" ]; then
    if [ "$cohort" == "" ]; then
      cohortRoot=${map[0]}
      cohort=${map[1]}
    else
      >&2 echo "WARN: Skipping conifer installation.  More than one cohort root projectfound: $cohort, ${map[1]}"
      exit 0
    fi
  fi
done

if [ "$cohort" == "" ]; then
  >&2 echo "WARN: Skipping conifer installation.  No cohort root project found."
  exit 0
fi

echo "Found ${cohort} cohort"

$project_home/conifer/bin/conifer install \
  --gus-home $gus_home \
  --project-home $project_home \
  --cohort $cohort \
  --cohort-root $cohortRoot
