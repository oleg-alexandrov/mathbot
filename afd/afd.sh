#!/bin/bash

runDir=$0 # exec name
runDir=$(dirname $runDir)

# Must prepare a virtual env in /data/project/mathbot/pwbvenv

cd $HOME
echo activating the env
source pwbvenv/bin/activate

echo Will run in $runDir
cd $runDir

# Must set the bot login info in $PYWIKIBOT_DIR

export PYWIKIBOT_DIR=/data/project/mathbot
export PYTHONIOENCODING=utf8

echo Running the afd script

./afd.cgi

# TODO(oalexan1): Figure out why temporary files do not get wiped out
# For now, wipe them by hand
/bin/rm -fv *tmp*

# Move the logs. This will ensure logs do not get
# appended, but rather only latest log is kept 
mkdir -p $HOME/logs
/bin/mv -fv $HOME/afd.out $HOME/afd.err $HOME/logs



