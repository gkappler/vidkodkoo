#!/bin/bash

# Check if the PID is running
PID_FILE=$HOME/`basename $0`.pid
if [ -f "$PID_FILE" ]
then
    MYPID=`head -n 1 "$PID_FILE"`
    TEST_RUNNING=`ps -p ${MYPID} | grep ${MYPID}`

    if [ -z "${TEST_RUNNING}" ]
    then
        echo "PID file exists but PID [$MYPID] is not running... creating new PID file [$PID_FILE]"
        echo $$ > "$PID_FILE"
    else
        echo "`basename $0` is already running [${MYPID}]... quitting"
        exit -1
fi
else
    echo "`basename $0` not running... creating new PID file [$PID_FILE]"
    echo $$ >> "$PID_FILE"
fi

cd $HOME/vidkodkoo/src/R/
Rscript recode-videos.R
