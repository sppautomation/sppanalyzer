#!/bin/bash
# Version 0.1. Sun Aug 26 09:16:55 DST 2018

if [[ $1 = '-v' || $1 = '--version' ]]; then
   echo -e "Log Analyzer for IBM Spectrum Protection Plus\n\
--------------------------------------------------------\n\
Version 0.1. 2018-08-20.\n\n"
   exit 0
fi

USAGE="USAGE\n\
-----\n\
-v, --version: to show the version of this script.\n\
-h, --help:    to show this help message.\n\n"

if [[ $1 = '-h' || $1 = '--help' ]]; then
    echo -e "$USAGE"
    exit 0
fi

DIRNAME="sppAnalyer$(env TZ=UTC date +%F_%H%M)utc"

echo "Creating a new directory $DIRNAME ."

if [[ ! -d $DIRNAME ]]; then
    mkdir ./$DIRNAME
else
    echo "A directory having the same name already exists. \
Someone may be using this service now. Please retry it later."
    exit 1
fi

exit $?

