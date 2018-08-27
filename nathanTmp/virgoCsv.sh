#!/bin/bash
# Version 0.2. Mon Aug 27 15:15:25 DST 2018
# 
# Creates a job index as a CSV file ./virgoLogIndex.csv .
# 
# Usage: 
# $ bash virgoCsv.sh <virgo log>
# Usually it is virgoLogUnified.log created by virgoLogUnifier.sh.
# But this script also works with virgo/log.log and virgo/log_[1-9].log 
# (uncompressed).
#
# The CSV file is comma (',') separated.  If any of "Job Names" has a comma,
# it will be replaced by '\,'.

if [[ ! -f $1 ]]; then
    echo "Could not find the file $1. Aborting."
    exit 1
fi

# Create a CSV header
echo "Job ID,Timestamp (epoch),Timestamp (UTC-0000),Job Type,Job Name,Success?"\
    > ./virgoLogIndex.csv

# Ensure ./virgoLogIndex.csv can be created.
if [[ ! -f ./virgoLogIndex.csv ]]; then
    echo "Unable to create ./virgoLogIndex.csv . \
Please check the permission of the directory. Aborting."
    exit 1
fi


JOBHEADERS=$(grep " [0-9]\{13\} ===== Starting job for policy " $1)

JOBIDS=$(echo "$JOBHEADERS" | cut -c 128-140 | sort -u)

TIMESTAMP_EPOCH=$(echo "$JOBIDS" | cut -c 1-10)

TIMESTAMP_UTC=$(echo "$JOBHEADERS" | cut -c 2-24)

JOBNAMES=$(echo "$JOBHEADERS" | cut -c 172- | rev | cut -d ' ' -f 14- | rev \
    | sed 's/,/\\,/g')

JOBTYPES=$(echo "$JOBNAMES" | cut -d '_' -f 1)

MSG_DETERMINER=$(grep -o \
    " Job policy .* completed with status .* id [0-9]\{13\}" $1)
MSG_DETERMINER_FAILEDX1=$(grep \
    " Failed job Session [0-9]\{13\} for job name ::: " $1)

JOBSUCCESS=$(echo "$JOBIDS" | while read line
do
    if   echo "$MSG_DETERMINER" | grep -q       " COMPLETED id $line"; then
        echo "COMPLETED"
    elif echo "$MSG_DETERMINER" | grep -q         " PARTIAL id $line"; then
        echo "PARTIAL"
    elif echo "$MSG_DETERMINER" | grep -q " RESOURCE ACTIVE id $line"; then
        echo "RESOURCE ACTIVE"
    elif echo "$MSG_DETERMINER" | grep -q          " FAILED id $line"; then
        echo "FAILED"
    elif echo "$MSG_DETERMINER_FAILEDX1" | grep -q "$line";            then
        echo "FAILED"
    else
        echo "UNKNOWN"
    fi
done)

paste -d ',' \
    <(echo "$JOBIDS") \
    <(echo "$TIMESTAMP_EPOCH") \
    <(echo "$TIMESTAMP_UTC") \
    <(echo "$JOBTYPES")\
    <(echo "$JOBNAMES")\
    <(echo "$JOBSUCCESS")\
    >> ./virgoLogIndex.csv

# echo "$JOBHEADERS" | while read line
# do
#     JOBID=$(printf "$line" | cut -c 128-140)
#     printf "$(printf "$line" | cut -c 128-140)"
#     printf ","
#     printf "$(printf "$line" | cut -c 2-24) UTC"
#     printf ","
#     printf "$(printf "$line" | cut -c 172- | rev | cut -d ' ' -f 14- | rev \
#         | sed 's/,/\,/g')"
#     printf ","
#     if echo "$JOBS_SUCCESS" | grep --quiet "$JOBID"; then
#         printf "1"
#     else
#         printf "0"
#     fi
#     printf "\n"
# done >> ./virgoLogIndex.csv

exit $?

