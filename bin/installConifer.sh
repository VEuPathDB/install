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
if (( $# != 3 )); then
  >&2 echo "USAGE: installConifer.sh <gus_home> <project_home> <build_target>"
  >&2 echo "     gus_home:     where scripts, code, and compiled artifacts will be placed"
  >&2 echo "     project_home: location of GUS projects to be built"
  >&2 echo "     build_target: top-level project submitted to bld/bldw/build (needed to determine cohort)"
  exit 1
fi

# name arguments
gus_home=$1
project_home=$2
build_target=$3

# log args
echo "installConifer.sh called with: $gus_home $project_home $build_target"

# check gus_home existence
if ! [ -d "$gus_home" ]; then
  >&2 echo "ERROR: Missing directory for gus_home: $gus_home"
  exit 1
fi

# check project_home existence
if ! [ -d "$project_home" ]; then
  >&2 echo "ERROR: Missing directory for project_home: $project_home"
  exit 1
fi

# check build target project existence
if ! [ -d "$project_home/$build_target" ]; then
  >&2 echo "ERROR: Requested build target $build_target does not exist in $project_home"
  exit 1
fi

# Defines a mapping from:
#    top level build project --> cohort name --> cohort root (for conifer)
#
# Note 1: the top-level build projects must match the cohort mapping in rebuilder
# Note 2: the cohort names and roots must match the cohort mapping in the conifer script
#
cohorts=( "ApiCommonPresenters:ApiCommon:ApiCommonWebsite"
          "OrthoMCLWebsite:OrthoMCL:OrthoMCLWebsite"
          "ClinEpiPresenters:ClinEpi:ClinEpiWebsite"
          "MicrobiomePresenters:Microbiome:MicrobiomeWebsite"
          "WDKTemplateSite:WDKTemplate:WDKTemplateSite"
          "EuPathDBIrods:EuPathDBIrods:EuPathDBIrods" )

# search for cohort with one representing a single cohort; skip conifer if >1 or none
for entry in ${cohorts[@]}; do
  pair=( $(echo $entry | sed 's/:/ /g') )
  if [ "$build_target" = "${pair[0]}" ]; then
    cohort=${pair[1]}
    cohortRoot=${pair[2]}
  fi
done

if [ "$cohort" == "" ]; then
  >&2 echo ""
  >&2 echo "WARN: Skipping conifer installation.  Target project does not represent a conifer cohort's top level build project."
  >&2 echo ""
  exit 0
fi

echo "Found ${cohort} cohort"

$project_home/conifer/bin/conifer install \
  --gus-home $gus_home \
  --project-home $project_home \
  --cohort $cohort \
  --cohort-root $cohortRoot
