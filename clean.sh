#!/bin/sh

ITERATION="$1"
if [ -z $ITERATION ]; then 
    echo "*** ITERATION is unset, exiting ..."
    exit 1
fi

source ./utils.sh
clean $ITERATION CLEANED
echo $"*** Clean returned $CLEANED ..."