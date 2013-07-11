#!/bin/bash

force_overwrite=0

stand="/data/Videos/tmp/stand.dv"
schnitt="/data/Videos/tmp/schnitt.dv"
all="/data/Videos/tmp/all.dv"

inf="$1"
out="$2"
ss="$3"
t="$4"

outpath=`echo $out| sed "s/\/[^\/]*$//"`;
out=`echo $out| sed "s/xvid/msmpeg4v2/g"`;
mkdirhier "$outpath"
outfile=`echo $out| sed "s/.*\///g"`;
force_overwrite=0

encoding=`exiftool "$inf" | grep "Video\ Codec\ Name\|Compression" | sed "s/.*: //g"` ;
width=`exiftool "$inf" | grep Image\ Width | sed "s/.*: //g"` ;
height=`exiftool "$inf" | grep Image\ Height | sed "s/.*: //g"` ;

if [[ "$encoding" = "" ]]
then
    encoding="dv-avi"
fi

if [[ $width == 0 ]] ; then
    width=720
fi  
if [[ $height == 0 ]] ; then
    height=576
fi

outopts="-vcodec msmpeg4v2 -s $width:$height -b 2000k -acodec libmp3lame -ab 128k"

function cut {
    inf="$1"
    out="$2"
    ss="$3"
    t="$4"
    negative_starttime=0

    if [[ "$ss" =~ .*-.* ]]
    then
        negative_starttime=1
        ss=`echo $ss| sed "s/-//g"`;
        echo "negative start time!"
    fi

    shiftout=`echo $out| sed "s/\.avi/.avi/g"`;

    if [[ $negative_starttime -eq 1 ]]; then
        standdur=$ss
        ss=0
    else
        standdur="1"
    fi


    NrSeconds=$standdur
    dvopts="-target dv"
    echo "converting $inf from $ss for duration $t with still image of $standdur. Target: $out"

    ## still image w/o sound
    NrChannels=2
    SampleRate=44100
    ffmpeg -ar $SampleRate -acodec pcm_s16le -f s16le -ac $NrChannels -i <(dd if=/dev/zero) -loop_input -t $standdur -i Standbild640.480.png $dvopts -y $stand > "log/$outfile.stand.log" 2> "log/$outfile.stand.err"

    ## cut from video
    ffmpeg -i "$inf" -ss $ss -t $t $dvopts -y $schnitt  > "log/$outfile.schnitt.log" 2> "log/$outfile.schnitt.err"

    ## merge still image and cut
    cat $stand $schnitt > $all
    ffmpeg -i "$all" $outopts -y $shiftout  > "log/$outfile.nts.log" 2> "log/$outfile.nts.err"

    chgrp samba "$shiftout"
    chmod g+w  "$shiftout"

    rm $stand $schnitt $all
}

if [[ $force_overwrite -eq 1 ]]; then
    rm -f $out
fi

if [[ ! -f $out  ]]; then
    cut $inf $out $ss $t
else
    echo "Schnitt $out wurde schon erstellt.  Falls neu geschnitten werden soll, löschen Sie diese Datei."
fi
