#!/bin/sh

source ./utils.sh

ITERATION="$1"
if [ -z $ITERATION ]; then 
    echo $"*** ITERATION is unset, exiting ..."
    exit 1
fi

prodDir $ITERATION PRODDIR X

echo PRODDIR $PRODDIR
echo X $X