#!/bin/bash
# Version 0.2. Tue Oct  2 02:38:44 DST 2018

if [[ $1 = '-v' || $1 = '--version' ]]; then
   echo -e "Log Analyzer for IBM Spectrum Protection Plus\n\
--------------------------------------------------------\n\
Version 0.2 2018-10-02.\n
Supported versions: 10.1.2, 10.1.1\n\n"
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

DIRNAME="sppAnalyzer$(env TZ=UTC date +%F_%H%M)utc"

echo "Creating a new directory $DIRNAME ."

if [[ ! -d $DIRNAME ]]; then
    mkdir ./$DIRNAME
else
    echo "A directory having the same name already exists. \
Someone may be using this service now. Please retry it later."
    exit 1
fi

exit $?

