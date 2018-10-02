#!/bin/bash
# Version 0.1. Mon Sep 17 19:50:32 DST 2018
# 
# Returns a whole record in the virgo log.log of IBM Spectrum Protect Plus
# associated with a given line number. The record may or may not have multiple 
# lines.
# 
# Usage: 
# $ bash ./multilineJobRecordPrinter.sh <FILE> <LINE NUMBER>
# <FILE> ... 

FILE=$1
LN=$2

sed "${LN}q;d" $FILE

IFS_BAK=$IFS # Bash-specific
IFS=$(echo -en "\n\b") # Bash-specific
tail +$(($LN+1)) $FILE | while read line && [[ ! $line =~ ^\[ ]]
do
    echo "$line"
done
IFS=$IFS_BAK # Bash-specific

exit $?

