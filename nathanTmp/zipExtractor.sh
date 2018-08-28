#!/bin/bash
# Version 0.1. Sun Aug 26 10:23:36 DST 2018

# Extracts ZIP file
# Checks existence of all the required files
# * <extracted directory name>/virgo/log.log

# Usage: 
# $ bash zipExtractor.sh <system log ZIP file>

if [[ -f $1 ]] && [[ $(unzip -t $1) ]]; then
    echo "Loaded the ZIP file $1."
    DIRNAME_UNZIP=$(unzip -l $1 | sed -n 4p | awk -F '[ /]' {'print $11'})
    if [[ -d $DIRNAME_UNZIP ]]; then
        echo "Drecttory $DIRNAME_UNZIP already exists. Skip extracting."
    else
        echo "Extracting $1."
        unzip -q $1
    fi
elif [[ -d $1 ]]; then
    echo "Loaded the directory $1."
    DIRNAME_UNZIP=$1
else
    echo -e "$1 is not a valid ZIP file.\n"
    echo -e "$USAGE"
    echo "Aborting."
    exit 1
fi

PATH_VIRGO=$(echo "./$DIRNAME_UNZIP/virgo/")

ERR_FILE_NOT_EXIST="Please download a new system log again and retry. \
If you keep seeing this error message, please contact IBM Spectrum Protect \
Plus Cusotmer Support."

REQUIRED_FILE01="$PATH_VIRGO/virgo/log.log"

if [[ ! -f $REQUIRED_FILE01 ]]; then
    echo "Could not find the file '$REQUIRED_FILE01'."
    echo $ERR_FILE_NOT_EXIST
    echo "Aborting."
    exit 1
fi

