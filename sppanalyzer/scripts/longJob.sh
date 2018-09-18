#!/bin/bash
# Version 0.1. Tue Sep 18 05:51:48 DST 2018
# 
# Returns a list of job records in the virgo log.log of IBM Spectrum Protect 
# Plus. Specify the threshold in second(s) and it only returns the job 
# record that took more than that and the next job record.
# 
# Usage: 
# $ bash ./longJob.sh <FILE> <JOBID/ALL> <THRESHOLD (default: 30)>
#
# <FILE> ... a virgo log.log file.  To use GZ arhived log files, extract (and 
# concatenate) them first.
# <JOBID/ALL> ... Use either a job session ID or "ALL" to use all the job IDs 
# appeared in the log file. Using the opton "ALL" may take over an hour to 
# complete.
# <THRESHOLD> ... Specify a threshold in second and the script only returns
# a list of job record that took longer than that period of time.
# Defualt: 30 (seconds).
#
# Example:
# $ bash ./longJob.sh ./virgo/log.log 1535346000093 20
#
# The command above will return a list of job records which is (1) associated 
# with the job ID 1535346000093 and also (2) took over 20 seconds.
# 
# Dependency:
#  - multilineJobRecordPrinter.sh

if [ -f $1 ]; then
    FILE=$1
else
    echo "$1 is not a vailid file."
    exit 1
fi

if [[ -z $3 ]]; then
    THRESHOLD=30
elif [[ "$3" =~ [0-9]{1,4} ]]; then
    THRESHOLD=$3
else
    echo "$3 is not a valid argument for the threshold. \
Use an integer 0-9999 [seconds]."
    exit 1
fi

if [[ "$2" =~ [0-9]{13} ]]; then
    JOBID=$2
elif [ "$2" == "ALL" ]; then
    JOBID=$(cut -c 128-140 $FILE | grep -o "[0-9]\{13\}" | sort -u)
    echo "$JOBID" | while read jobid
    do 
        bash ./longJob.sh $FILE $jobid $THRESHOLD
    done
else
    echo "Invalid argument."
    exit 1
fi

LN_TSTAMP=$(grep -n "^\[....-..-.. ..:..:......\] .\{100\} $JOBID " $FILE \
    | cut -d '.' -f 1 | sed "s/:\[/,/g")

ETSTAMP=$(echo "$LN_TSTAMP" | cut -d ',' -f 2 \
    | while read timestamp
do
    date -d "$timestamp" +%s
done)

LN_TSTAMP_ETSTAMP=$(\
    paste <(echo "$LN_TSTAMP") <(echo "$ETSTAMP") -d ',')

LN_TSTAMP_ETSTAMP_PAIR=$(paste -d ',' \
    <(echo "$LN_TSTAMP_ETSTAMP" | head -n -1) \
    <(echo "$LN_TSTAMP_ETSTAMP" | tail -n +2))

echo "$LN_TSTAMP_ETSTAMP_PAIR" | while read line
do
    line1=$(echo $line | cut -d ',' -f 1)
    etstamp1=$(echo $line | cut -d ',' -f 3)
    line2=$(echo $line | cut -d ',' -f 4)
    etstamp2=$(echo $line | cut -d ',' -f 6)
    if [[ $((${etstamp2}-${etstamp1})) -gt $THRESHOLD ]]; then
        echo "----- $((${etstamp2}-${etstamp1})) -----"
        bash ./multilineJobRecordPrinter.sh $FILE "$line1"
        bash ./multilineJobRecordPrinter.sh $FILE "$line2"
    fi
done

exit $?

