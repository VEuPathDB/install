@echo off 

rem A wrapper around the perl wrapper around ant.  Avoids assumptions of perl's
rem location.

if not defined PROJECT_HOME (
  echo "PROJECT_HOME is not defined, build failed."
  goto end
)
if not defined GUS_HOME (
  echo "GUS_HOME is not defined, build failed."
  goto end
)

perl %PROJECT_HOME%/install/bin/build.pl %*

:end