#!/bin/bash
# Version 0.1. Sun Aug 26 11:42:47 DST 2018

# Creates virgoLogUnified.log by concatenating /virgo/log.log and 
# log_[0-9].log.gz .

# Usage: 
# $ bash virgoLog.sh <path to the extracted system log directory>
#
# The directory path may or may not contain '/' at the end.

# If the given directory path contains '/' at the end, remove it.

if [ "${1: -1}" == "/" ]; then
    PATH_LOG=${1: : -1}
    echo $PATH_LOG
else
    PATH_LOG=$1
    echo $PATH_LOG
fi

if [[ -f $PATH_LOG/virgo/log.log ]]; then
    echo "Extracting the virgo log file(s):"
    echo "log.log"
    find $PATH_LOG/virgo/ -name log_[0-9]\.log.gz -type f -printf "%f\n"
else
    echo "Could not find $PATH_LOG/virgo/log.log. Aborging."
    exit 1
fi

# Copy log.log as ./virgoLogUnified.log and ensure it exists
cat $PATH_LOG/virgo/log.log > ./virgoLogUnified.log

if [[ ! -f ./virgoLogUnified.log ]]; then
    echo "Failed to create ./virgoLogUnified.log. \
Please check the directory permission. Aborting."
    exit 1
fi

# Append contents in log_[0-9].log.gz to ./virgoLogUnified.log
zcat $PATH_LOG/virgo/log_[0-9].log.gz >> ./virgoLogUnified.log

exit $?

