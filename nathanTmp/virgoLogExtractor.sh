#!/bin/bash
# Version 0.1. Sun Aug 26 22:15:35 DST 2018
# 
# Returns all the records associated with a given job ID.
# 
# Usage: 
# $ bash virgoLogExtractor.sh <virgo log> <job id> <info level>
# Usually it is virgoLogUnified.log created by virgoLogUnifier.sh.
# But this script also works with virgo/log.log and virgo/log_[1-9].log 
# (uncompressed).
# <info_level>...
# 1: INFO  2: WARN  4: ERROR  (Default: 7: ALL)
# Use a sum of these values to select multiple items
# (e.g. 6: WARN and ERROR).

if [[ ! -f $1 ]]; then
    echo "Could not find the file $1. Aborting."
    exit 1
fi

echo "$2"

JOBID_SYNTAX="[0-9]{13}"
if [[ ! $2 =~ $JOBID_SYNTAX ]]; then
    echo "Invalid job ID was given. Aborting."
    exit 1
fi


if [[ -z $3 ]]; then
    MODE="7"
elif [[ "$3" == "INFO" ]]; then
    MODE="1"
elif [[ "$3" == "WARN" ]]; then
    MODE="2"
elif [[ "$3" == "ERROR" ]]; then
    MODE="4"
elif [[ "$3" == [1-7] ]]; then
    MODE="$3"
else
    echo "Invalid mode was given. Aborting."
    exit 1
fi

echo "$MODE"

RECORDS_INFO=$(\
    if [[ "$MODE" == "1" ]] || [[ "$MODE" == "3" ]] || [[ "$MODE" == "5" ]]
    then
        grep " INFO "  $1
    fi)

RECORDS_WARN=$(\
    if [[ "$MODE" == "2" ]] || [[ "$MODE" == "3" ]] || [[ "$MODE" == "6" ]]
    then
        grep " WARN "  $1
    fi)

RECORDS_ERROR=$(\
    if [[ "$MODE" == "4" ]] || [[ "$MODE" == "5" ]] || [[ "$MODE" == "7" ]]
    then
        grep " ERROR " $1
    fi)

RECORDS_ALL="${RECORDS_INFO}\n${RECORDS_WARN}\n${RECORDS_ERROR}"
echo "$RECORDS_ALL" | sort -k 2 | sort -k 1

exit $?

