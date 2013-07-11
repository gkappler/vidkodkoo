#!/bin/bash

cd $HOME
autodir="/data/Videos/komprimiert/"

processLine(){
 echo $logfile
    r="video=([a-zA-ZüöäßÖÄÜ0-9._]*) dipl=([a-zA-ZüöäßÖÄÜ]*) ticket=#?([0-9]*) cut.start=(-?[0-9]{2}:-?[0-9]{2}:-?[0-9]{2}) cut.dur=(-?[0-9]{2}:-?[0-9]{2}:-?[0-9]{2})"
    l=`echo "$1" | awk '{print tolower($0)}'`;
#    echo $l
    kompdir="$2"
    outdir="$2/Schnitt-$3"
    if [[ ! -d "$outdir" ]]; then
       mkdir "$outdir"
    fi
    if [[ "$l" =~ $r ]]; then
        video="${BASH_REMATCH[1]}"
        dipl="${BASH_REMATCH[2]}"
        tick="${BASH_REMATCH[3]}"
        start="${BASH_REMATCH[4]}:00"
        dur="${BASH_REMATCH[5]}:00"

        infile=`find $kompdir -maxdepth 1 -iname "${video}*"`;
        video=`echo "$video" | sed 's/\.msmpeg4v2.avi//g'`;
        if [[ ! -f $infile  ]]; then
            echo >> $logfile
            echo "Zeile $lno richtig, aber kein (oder mehrere) Videos gefunden. Alles richtig geschrieben?: $l \nfound: $infile" >> $logfile
            find $kompdir -iname "${video}*"
        else
            outfile="$outdir/${video}_${dipl}_${tick}.xvid.avi"
            echo >> $logfile
            echo "Schneide \"$infile\" und speichere in \"$outfile\" ab $start, Länge $dur" | sed 's/\/mnt\/hgfs\/videos\///g' >> $logfile
            $HOME/vidkodkoo/src/ffmpeg_xvid.sh "$infile" "$outfile" $start $dur >> $logfile
        fi
    else
        echo "Zeile $lno falsch: $l" >> $logfile
        echo "Zeile $lno falsch: $l" 
    fi
}

PID_FILE=$HOME/`basename $0`.pid

# Check if the PID is running
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

find $autodir -name "*.txt.txt" | while read f
do
    ff=`echo $f | sed 's/\.txt$//g'`;
    mv "$f" "$ff"
done

find $autodir -name "autoschnitt.*.txt" | while read f
do
    ## allow editing of txt file for all users in samba group (accessing windows share)
    ## chgrp samba "$f"
    ## chmod g+w "$f"

    schnitttype=`echo $f | sed 's/.*autoschnitt\.//g'`;
    schnitttype=`echo $schnitttype | sed 's/\.txt//g'`;

    fdir=`echo $f | sed 's/\/[^/]*$//g'`;
    fname=`echo $f | sed 's/.*\///g'`;
    logfile="$fdir/Schnitt-$schnitttype/schnitt.log"
    infofile="$fdir/SCHNITT_LAEUFT_GERADE"

    echo
    echo
    echo "Schneide Videos in $fname ($f)"
    date >> $infofile

    rm -f $logfile
    echo "Schneide Videos in $f" > $logfile
    lno=1
    iconv -f iso8859-1 -t utf8 $f | while read line
    do
        if [[ ! "$line" =~ ^[[:space:]]*$ ]]; then      
            echo "       processing '$line'"
            processLine "$line" "$fdir" $schnitttype
        fi
        lno=$(( $lno+1 ))
    done

    iconv -f utf8 -t iso8859-1 $logfile > /tmp/log.tmp
    cp /tmp/log.tmp $logfile
    todos $logfile
    rm -f $infofile
done
