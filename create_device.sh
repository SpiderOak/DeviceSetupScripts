#!/bin/bash
#####
## Creates a device using the computer hostname.
#####

function installdev
{
    echo "{\"username\": \"$OURUSER\",\"password\": \"$OURPASS\",\"device_name\": \"$1\",\"reinstall\": false}">$SETUPFILE
    echo "Setting up SpiderOak as device $1 (this may take a while)..."
    $SPIDEROAK --setup=$SETUPFILE > $APPOUT
    
    ## Check if everything ran OK.
    if grep -q "batchmode run complete: shutting down" $APPOUT; then
        echo "Device setup OK"
        RESULT=0
    ## If everything did not complete, was it because of a
    ## duplicate name?
    elif grep -q "Device name already exists" $APPOUT; then
        echo "Device already exists"
        RESULT=1
    ## Or was it because of a different error?
    else
        echo "Error in setup"
        RESULT=2
    fi
}

## Get the device ID from the device number.
## Expects the name of the device as a parameter.
## Sets $DEVNUM variable
function devnumForName
{
    $SPIDEROAK --userinfo > $APPOUT
    DEVNUM=`cat $APPOUT | grep "$1 on" | grep -v "(REMOVED)" | grep -oP '(?<=#)[0-9]+'`
}

## Creates the old device name
## Does not require any parameters
## Produces a string with HOSTNAME-old-DATETIME
function olddevname
{
    THEDATE=`date +%Y%m%d%I%M%S`
    OLDDEV="$HOSTNAME-old-$THEDATE"
}

## Renames a device
## Expects two parameters... old device name and new device name.
function renamedev
{
    devnumForName $1
    echo "Renaming current $1 to $2"
    $SPIDEROAK -d $DEVNUM --rename-device=$2
}


#####
## Main Script
#####

SYSTEM=`uname`

## Set path to SpiderOak
if [[ $SYSTEM == 'Linux' ]]; then
	SPIDEROAK="/usr/bin/SpiderOak"
else
	SPIDEROAK="/Applications/SpiderOak.app/Contents/MacOS/SpiderOak"
fi

OURUSER=$1
OURPASS=$2

if [[ -z "$3" ]]; then
    OURUSER+="$3"
fi

APPOUT="/tmp/spiderout.txt"
SETUPFILE="/tmp/setupfile.json"

## Try to install the device using the hostname.
## The following sets the $RESULT variable.
installdev $HOSTNAME

## If the device did not exist and was created
## or if the creation failed for something other
## than a duplicate name then finish.
## Otherwise rename the old device and create the new one.
if [[ $RESULT != 1 ]]; then
    echo "Script complete."
    exit
else
    echo "Renaming devices to fit."
    olddevname
    installdev "$HOSTNAME-new"
    renamedev $HOSTNAME $OLDDEV
    renamedev "$HOSTNAME-new" $HOSTNAME
fi
