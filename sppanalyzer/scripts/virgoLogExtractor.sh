#!/bin/bash
# Version 0.3. Tue Sep 25 01:46:08 DST 2018
# 
# IBM Spectrum Protect Plus 10.1.1 10.1.2 
# Returns all the records associated with a given job ID.
# 
# Usage: 
# $ bash virgoLogExtractor.sh <virgo log> <job id> <info level>
# <virgo log>
# Usually it is virgoLogUnified.log created by virgoLogUnifier.sh.
# But this script also works with virgo/log.log and virgo/log_[1-9].log 
# (uncompressed).
# <job id>
# Enter a 13-digit job ID. You can also use "ALL" to select the whole part of
# the log or "OTHERS" to select all the records that do not have any job ID.
# <info_level>
# 1: INFO  2: WARN  4: ERROR  (Default: 7: ALL)
# Use a sum of these values to select multiple items (e.g. 6: WARN and ERROR).

if [ -f $1 ]; then
    FILE=$1
else
    echo "$1 is not a vailid file."
    exit 1
fi

if [[ "$2" =~ [0-9]{13} ]]; then
    JOBID=$2
elif [ "$2" == "OTHERS"  ]; then
    JOBID=""
elif [ "$2" == "ALL"     ]; then
    JOBIDS=$(cut -c 128-140 $FILE | grep -o "[0-9]\{13\}" | sort -u)
    echo "$JOBIDS" | while read jobid
    do 
        bash ./virgoLogExtractor.sh $FILE $jobid
    done
else
    echo "Invalid argument."
    exit 1
fi

if [[ -z $3 ]];             then
    MODE="7"
elif [[ "$3" == [1-7] ]];   then
    MODE="$3"
elif [[ "$3" == "INFO" ]];  then
    MODE="1"
elif [[ "$3" == "WARN" ]];  then
    MODE="2"
elif [[ "$3" == "ERROR" ]]; then
    MODE="4"
else
    echo "Invalid mode was given. Aborting."
    exit 1
fi

LNS_INFO=$(
if [[ "$MODE" == "1" ]] || [[ "$MODE" == "3" ]] || [[ "$MODE" == "5" ]]\
    || [[ "$MODE" == "7" ]]
then
    grep -n "^\[20..-..-..[ T]..:..:..\..\{3,4\}\] INFO  .\{93,94\}  $JOBID " \
       $FILE | cut -d ':' -f 1
fi)

LNS_WARN=$(
if [[ "$MODE" == "2" ]] || [[ "$MODE" == "3" ]] || [[ "$MODE" == "6" ]]\
    || [[ "$MODE" == "7" ]]
then
    grep -n "^\[20..-..-..[ T]..:..:..\..\{3,4\}\] WARN  .\{93,94\}  $JOBID " \
       $FILE | cut -d ':' -f 1
fi)

LNS_ERROR=$(
if [[ "$MODE" == "4" ]] || [[ "$MODE" == "5" ]] || [[ "$MODE" == "6" ]]\
    || [[ "$MODE" == "7" ]]
then
    grep -n "^\[20..-..-..[ T]..:..:..\..\{3,4\}\] ERROR .\{93,94\}  $JOBID " \
       $FILE | cut -d ':' -f 1
fi)

LNS_ALL=$(echo -e "${LNS_INFO}\n${LNS_WARN}\n${LNS_ERROR}" \
    | grep "^[0-9]\+$" | sort)

echo "$LNS_ALL" | while read ln
do
    bash ./multilineJobRecordPrinter.sh $FILE $ln
done

exit $?

