#!/bin/bash
# Version 0.1.  Mon Aug 27 15:19:03 DST 2018
# 
# Creates a backup target index as a CSV file ./virgoBackupIndex.csv .
# 
# Usage: 
# $ bash virgoBackupCsv.sh <virgo log> <backup type (optional)>
# 
# <virgo log>
# Usually it is virgoLogUnified.log created by virgoLogUnifier.sh.
# But this script also works with virgo/log.log and virgo/log_[1-9].log 
# (uncompressed).
#
# <backup type (optional: Default - ALL)>
# Enter "VM", "APP", "ALL" or leave it empty which is same as ALL.
#
# The CSV file is comma (',') separated.  If any of "Job Names" has a comma,
# it will be replaced by '\,'.

# Check the arguments
if [[ ! -f $1 ]]; then
    echo "Could not find the file $1. Aborting."
    exit 1
fi

if   [[ -z "$2" ]] || [[ "$2" == "ALL" ]]; then
    ENABLE_VM=true
    ENABLE_APP=true
elif [[ "$2" == "VM"  ]]; then
    ENABLE_VM=true
    ENABLE_APP=false
elif [[ "$2" == "APP" ]]; then
    ENABLE_VM=false
    ENABLE_APP=true
else
    echo "Invalid argument. Please use VM, APP, ALL or leave it blank \
(for ALL). Aborting."
    exit 1
fi

# Create a CSV header
if $ENABLE_VM; then
    echo "Job ID,BackupTarget" > ./virgoBackupVmIndex.csv
    if [[ ! -f ./virgoBackupVmIndex.csv  ]]; then
        echo "Unable to create ./virgoBackupVmIndex.csv . \
Please check the permission of the directory. Aborting."
        exit 1
    fi
fi

if $ENABLE_APP; then
    echo "Job ID,BackupTarget" > ./virgoBackupAppIndex.csv
    if [[ ! -f ./virgoBackupAppIndex.csv ]]; then
        echo "Unable to create ./virgoBackupAppIndex.csv . \
Please check the permission of the directory. Aborting."
        exit 1
    fi
fi

# Print the records
if $ENABLE_VM; then
    COLUMN12=$(grep -o " [0-9]\{13\} vmWrapper .* type vm"    $1 \
        | cut -d ' ' -f 2,4- | rev | cut -d ' ' -f 3- | rev)
    COLUMN1=$(echo "$COLUMN12" | cut -d ' ' -f 1 )
    COLUMN2=$(echo "$COLUMN12" | cut -d ' ' -f 2-)
    paste -d ',' <(echo "$COLUMN1") <(echo "$COLUMN2") \
        >> ./virgoBackupVmIndex.csv
fi

if $ENABLE_APP; then
    COLUMN12=$(grep -o " [0-9]\{13\} Options for database .*" $1 \
        | cut -d ':' -f 1 | cut -d ' ' -f 2,6- | sed 's/,/\\,/g')
    COLUMN1=$(echo "$COLUMN12" | cut -d ' ' -f 1 )
    COLUMN2=$(echo "$COLUMN12" | cut -d ' ' -f 2-)
    paste -d ',' <(echo "$COLUMN1") <(echo "$COLUMN2") \
        >> ./virgoBackupAppIndex.csv
fi

exit $?

