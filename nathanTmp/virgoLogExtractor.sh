#!/bin/bash
# Version 0.1. Sun Aug 26 22:15:35 DST 2018
# 
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

if [[ ! -f $1 ]]; then
    echo "Could not find the file $1. Aborting."
    exit 1
fi

JOBID_SYNTAX="[0-9]{13}"
if [[ $2 =~ $JOBID_SYNTAX ]]; then
    RECORDS_ALL_HEAD=$(grep -n "\[20..-..-.. ..:..:......\] .* $2 " $1)
elif [[ $2 == "ALL" ]]; then
    RECORDS_ALL_HEAD=$(grep -n "\[20..-..-.. ..:..:......\] .* "    $1)
elif [[ $2 == "OTHERS" ]]; then
    RECORDS_ALL_HEAD=$(grep -n "\[20..-..-.. ..:..:......\] .* "    $1 \
        | grep -v " [0-9]\{13\} ")
else
    echo "Invalid job ID was given. Please enter a valid 13-digit job ID, \
\"ALL\" to select the whole part of the records, or \"OTHERS\" to select \
all the records that do not have any job ID. Aborting."
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

RECORDS_INFO=$(\
    if [[ "$MODE" == "1" ]] || [[ "$MODE" == "3" ]] || [[ "$MODE" == "5" ]]\
        || [[ "$MODE" == "7" ]]
    then
        echo "$RECORDS_ALL_HEAD" | grep " INFO "
    fi)

RECORDS_WARN=$(\
    if [[ "$MODE" == "2" ]] || [[ "$MODE" == "3" ]] || [[ "$MODE" == "6" ]]\
        || [[ "$MODE" == "7" ]]
    then
        echo "$RECORDS_ALL_HEAD" | grep " WARN "
    fi)

RECORDS_ERROR=$(\
    if [[ "$MODE" == "4" ]] || [[ "$MODE" == "5" ]] || [[ "$MODE" == "6" ]]\
        || [[ "$MODE" == "7" ]]
    then
        echo "$RECORDS_ALL_HEAD" | grep " ERROR "
    fi)

RECORDS_ALL="${RECORDS_INFO}\n${RECORDS_WARN}\n${RECORDS_ERROR}"
echo -e "$RECORDS_ALL" | sort -t ':' -k 1 | cut -d ':' -f 2-

exit $?

