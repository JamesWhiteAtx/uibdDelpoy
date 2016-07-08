ITERATION="$1"
if [ -z $ITERATION ]; then 
    echo "*** ITERATION is unset, exiting ..."
    exit 1
fi

source ./utils.sh
stop $ITERATION STOPPED
echo $"*** Stopped returned $STOPPED ..."
