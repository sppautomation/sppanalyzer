#!/bin/bash
# Version 0.3. Tue Oct  2 06:41:42 DST 2018
# 
# IBM Spectrum Protect Plus 10.1.1 10.1.2 
# Creates a job index as a CSV file ./virgoLogIndex.csv .
# 
# Usage: 
# $ bash virgoCsv.sh <virgo log>
# Usually it is virgoLogUnified.log created by virgoLogUnifier.sh.
# But this script also works with virgo/log.log and virgo/log_[1-9].log 
# (uncompressed).
#
# The CSV file is comma (',') separated.  All commas in the field "SLA names"
# will be removed.

if [[ -f $1 ]]; then
    FILE=$1
else
    echo "Could not find the file $1. Aborting."
    exit 1
fi

# Create a CSV header
echo "Job ID,Start Date,Job Type,SLA Name,Success?"\
    > ./virgoLogIndex.csv

# Ensure ./virgoLogIndex.csv can be created.
if [[ ! -f ./virgoLogIndex.csv ]]; then
    echo "Unable to create ./virgoLogIndex.csv . \
Please check the permission of the directory. Aborting."
    exit 1
fi

JOBHEADERS=$(grep -o "[0-9]\{13\} ===== Starting job for policy .*\.  id " \
$FILE | cut -d ' ' -f 1,7-)
# echo "$JOBHEADERS"

JOBIDS=$(echo "$JOBHEADERS" | cut -c 1-13)
# echo "$JOBIDS"

JOBTS=$(echo "$JOBHEADERS" | rev | cut -d ' ' -f 4-10 | rev | tr -d '.,')

JOBNAMES=$(echo "$JOBHEADERS" | cut -c 15- | rev | cut -d ' ' -f 12- | rev)
# echo "$JOBNAMES"

SLANAMES=$(echo "$JOBNAMES" | while read line
do
    if   [[ $line =~ ^catalog         ]]; then
        echo "IBM Spectrum Protect Plus|Catalog"
    elif [[ $line =~ ^onDemandRestore ]]; then
        echo "IBM Spectrum Protect Plus|On-Demand Restore"
    elif [[ $line =~ ^Maintenance     ]]; then
        echo "IBM Spectrum Protect Plus|Maintenance"
    elif [[ $line =~ ^vmware          ]]; then
        echo "Hypervisor - VMware|$( cut -d '_' -f 2- <<< $line)"
    elif [[ $line =~ ^hyperv          ]]; then
        echo "Hypervisor - Hyper-V|$(cut -d '_' -f 2- <<< $line)"
    elif [[ $line =~ ^oracle          ]]; then
        echo "Application - Oracle|$(cut -d '_' -f 2- <<< $line)"
    elif [[ $line =~ ^sql             ]]; then
        echo "Application - SQL|$(   cut -d '_' -f 2- <<< $line)"
#   elif [[ $line =~ ^db2             ]]; then
#       echo "Application - Db2|$(   cut -d '_' -f 2- <<< $line)"
    else
        echo "IBM Spectrum Protect Plus|$line"
    fi
done)

JOBTYPES=$(echo "$SLANAMES" | cut -d '|' -f 1)
SLANAMES=$(echo "$SLANAMES" | cut -d '|' -f 2- | tr -d ',')

RESULT_RECORDS=$(grep -o "completed.*with status .* id [0-9]\{13\}" $FILE)
RESULT=$(echo "$JOBIDS" | while read jobid
do
    result=$(echo "$RESULT_RECORDS" | grep "$jobid" \
        | grep -m 1 -o "\(COMPLETED\|PARTIAL\|FAILED\|RESOURCE ACTIVE\)")
    if [[ -z $result ]]; then
        echo "UNKNOWN"
    else
        echo "$result"
    fi
done)

paste -d ',' \
    <(echo "$JOBIDS") \
    <(echo "$JOBTS") \
    <(echo "$JOBTYPES") \
    <(echo "$SLANAMES")\
    <(echo "$RESULT")\
    >> ./virgoLogIndex.csv

exit $?

