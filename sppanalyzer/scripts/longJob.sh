#!/bin/bash
# Version 0.3. Tue Sep 25 05:03:23 DST 2018
# IBM Spectrum Protect Plus 10.2, 10.1
# 
# Returns a list of job records in the virgo log.log of IBM Spectrum Protect 
# Plus. Specify the threshold in second(s) and it only returns the job 
# record that took more than that and the next job record.
# 
# Usage: 
# $ bash ./longJob.sh <FILE> <JOBID/ALL> <THRESHOLD (default: 30)>
#
# <FILE> ... a virgo log.log file.  To use GZ archived log files, extract (and 
# concatenate) them first.
# <JOBID/ALL> ... Use either a job session ID or "ALL" to use all the job IDs 
# appeared in the log file. Using the option "ALL" may take over an hour to 
# complete.
# <THRESHOLD> ... Specify a threshold in second and the script only returns
# a list of job record that took longer than that period of time.
# Default: 30 (seconds).
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

LN_TSTAMP=$(grep -n \
    "^\[20..-..-..[ T]..:..:..\..\{3,4\}] .\{99,100\}  $JOBID " $FILE)

LN_ESTAMP=$(echo "$LN_TSTAMP" | while read line
do
    awk -F '[][]|:|-|T| |Z' '{\
        estamp = $8 + $7 * 60 + $6 * 60 * 60 + $5 * 60 * 60 * 24 \
        + $4 * 60 * 60 * 24 * 30 + $3 * 60 * 60 * 24 * 30 * 12
    printf ("%d,%f\n", $1, estamp) }'
done)

LN_ESTAMP_PAIR=$(paste -d ',' \
    <(echo "$LN_ESTAMP" | head -n -1) <(echo "$LN_ESTAMP" | tail -n +2))

echo "$LN_ESTAMP_PAIR" | while read line
do
    read -r line1 line2 diff \
        <<<$(echo "$line" | awk -F ',' -v threshold="$THRESHOLD" '{\
        line1 = $1; estamp1 = $2; line2 = $3; estamp2 = $4
    diff = estamp2 - estamp1
    if( diff > threshold ) {print line1" "line2" "diff}}')

        if [ ! -z $diff ]; then
            echo "----- $diff seconds - lines $line1 $line2 -----"
            bash ./multilineJobRecordPrinter.sh $FILE "$line1"
            bash ./multilineJobRecordPrinter.sh $FILE "$line2"
        fi
done

exit $?

