#!/bin/bash
# Version 0.5. Tue Oct  2 11:20:43 DST 2018
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
echo "JobID,StartDateTime,JobType,SLA,Result,Targets"\
    > ./virgoLogIndex.csv

# Ensure ./virgoLogIndex.csv can be created.
if [[ ! -f ./virgoLogIndex.csv ]]; then
    echo "Unable to create ./virgoLogIndex.csv . \
Please check the permission of the directory. Aborting."
    exit 1
fi

JOBHEADERS=$(grep -o "[0-9]\{13\} ===== Starting job for policy .*\.  id " \
$FILE | cut -d ' ' -f 1,7-)

JOBIDS=$(echo "$JOBHEADERS" | cut -c 1-13)

# JOBTS=$(echo "$JOBHEADERS" | rev | cut -d ' ' -f 4-10 | rev | tr -d '.,')

JOBID_VMS_RAW=$(grep -o "  [0-9]\{13\} vmWrapper .* type vm $" $FILE | rev \
    | cut -d ' ' -f 4- | rev | cut -d ' ' -f 3,5-)
JOBID_APPS_RAW=$(grep -o "  [0-9]\{13\} Options for database [^:]*" $FILE \
    | cut -d ' ' -f 3,7- )

jobid_items_unifier () {
    jobid_item=$1

    echo "$jobid_item" | cut -d ' ' -f 1 | sort -u | while read jobid
do
    items=$(echo "$jobid_item" | grep "^$jobid " | cut -d ' ' -f 2- \
        | tr '\n' ':' | sed "s/:$/\n/g")
    echo "$jobid $items"
done
}

JOBID_VMS=$( jobid_items_unifier "$JOBID_VMS_RAW")
JOBID_APPS=$(jobid_items_unifier "$JOBID_APPS_RAW")

JOBNAMES=$(echo "$JOBHEADERS" | rev | cut -d ' ' -f 12- | rev)

jobdetails_printer () {
    jobnames_line=$1
    job_item_list=$2
    job_type=$3
    
    jobid=$(cut -d ' ' -f 1 <<< $jobnames_line)
    items=$(echo "$job_item_list" | grep -m 1 "$jobid" | cut -d ' ' -f 2-)
    slaname=$(cut -d '_' -f 2- <<< $line)
    echo "$job_type|$slaname|$items"
}
    
JOBDETAILS=$(echo "$JOBNAMES" | while read line
do
    if   [[ $line =~ " catalog"         ]]; then
        echo "SPP|Catalog"
    elif [[ $line =~ " onDemandRestore" ]]; then
        echo "SPP|On-Demand Restore"
    elif [[ $line =~ " Maintenance"     ]]; then
        echo "SPP|Maintenance"
    elif [[ $line =~ " vmware_"          ]]; then
        jobdetails_printer "$line" "$JOBID_VMS"  "VMware"
    elif [[ $line =~ " hyperv_"          ]]; then
        jobdetails_printer "$line" "$JOBID_VMS"  "Hyper-V"
    elif [[ $line =~ " oracle_"          ]]; then
        jobdetails_printer "$line" "$JOBID_APPS" "Oracle"
    elif [[ $line =~ " sql_"             ]]; then
        jobdetails_printer "$line" "$JOBID_APPS" "SQL"
    elif [[ $line =~ " db2_"             ]]; then
        jobdetails_printer "$line" "$JOBID_APPS" "DB2"
    else
        slaname=$(echo "$line" | sed "s/^[0-9]\{13\} //g")
        echo "SPP|$slaname"
    fi
done)

JOBTYPES=$(echo "$JOBDETAILS" | cut -d '|' -f 1)
SLANAMES=$(echo "$JOBDETAILS" | cut -d '|' -f 2 | tr -d ',')
TARGETS=$( echo "$JOBDETAILS" | cut -d '|' -f 3 | tr -d ',')

RESULT_RECORDS=$(grep -o "[0-9]\{13\} .* completed.*with status .*" $FILE | tac)
RESULT=$(echo "$JOBIDS" | while read jobid
do
    result=$(echo "$RESULT_RECORDS" | grep "$jobid" \
        | grep -o -m 1 "\(COMPLETED\|PARTIAL\|FAILED\|RESOURCE ACTIVE\)")
    if [[ -z $result ]]; then
        echo "UNKNOWN"
    else
        echo "$result"
    fi
done)

paste -d ',' \
    <(echo "$JOBIDS") \
    <(echo "$JOBIDS" | cut -c 1-10) \
    <(echo "$JOBTYPES") \
    <(echo "$SLANAMES")\
    <(echo "$RESULT")\
    <(echo "$TARGETS")\
    >> ./virgoLogIndex.csv

#    <(echo "$JOBTS") \
exit $?

