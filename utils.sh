#!/bin/sh

DEPLOY=$(pwd)
DSBASE=ds
IBBASE=ib
SYBASE=sy
DSNAME=Directory
IBNAME=Broker

PASSWORD=password
BINDDN="cn=Directory Manager"
THISHOST="localhost"
# $(hostname)
#"mybox"
LOCATION="Austin"

PARENTDIR="$(dirname "$DEPLOY")"
PACKAGES=$PARENTDIR/packages
TEMPDIR=$DEPLOY/temp

USERSTORE=$THISHOST":$DSLDAP:$LOCATION"
INSTANCENAME=Broker$ITERATION

function dsDir() {
    local _iteration=$1
    local _outvar=$2

	local _result=$DEPLOY/$DSBASE$_iteration

    eval $_outvar=\$_result
}

function ibDir() {
    local _iteration=$1
    local _outvar=$2

	local _result=$DEPLOY/$IBBASE$_iteration

    eval $_outvar=\$_result
}

function syDir() {
    local _iteration=$1
    local _outvar=$2

	local _result=$DEPLOY/$SYBASE$_iteration

    eval $_outvar=\$_result
}

function ports() {
    local _iteration=$1
    local _outvar1=$2
    local _outvar2=$3
    local _outvar3=$4

	local _result1=$_iteration"389"
    local _result2=$_iteration"636"
    local _result3="844"$(($_iteration + 2))

    eval $_outvar1=\$_result1
    eval $_outvar2=\$_result2
    eval $_outvar3=\$_result3
}

function prodDir() {
    local _iteration=$1
    local _outvar1=$2
    local _outvar2=$3
    local _result1
    local _result2

    _result1=$DEPLOY/$DSBASE$_iteration
    _result2=$DSNAME$_iteration
    if [ ! -d "$_result1" ]; then
        _result1=$DEPLOY/$IBBASE$_iteration
        _result2=$IBNAME$_iteration
    fi
    if [ ! -d "$_result1" ]; then
        _result1=$DEPLOY/$SYBASE$_iteration
        _result2=$SYNAME$_iteration
    fi
    if [ ! -d "$_result1" ]; then
        _result1=''
        _result2=''
    fi

    eval $_outvar1=\$_result1 
    if [ ! -z "$_outvar2" ]; then
        eval $_outvar2=\$_result2
    fi
}

function prodStopper() {
   local _dir=$1
   local _outvar=$2
   local _result 

   _result=$_dir/bin/stop-ds

	if [ ! -f "$_result" ]; then
        _result=$_dir/bin/stop-broker
    fi
	if [ ! -f "$_result" ]; then
        _result=$_dir/bin/stop-sync-server
    fi
	if [ ! -f "$_result" ]; then
        _result=''
    fi
    
    eval $_outvar=\$_result 
}

function stop() {
    local _iteration=$1
    local _outvar=$2
    local _result=0
    local _prodDir
    local _stopper

    prodDir $_iteration _prodDir
    if [ -n "${_prodDir}" ]; then
        prodStopper $_prodDir _stopper
        if [ -n "${_stopper}" ]; then
            $_stopper
            _result=1
        fi
    fi
    eval $_outvar=\$_result    
}

function clean() {
    local _iteration=$1
    local _outvar=$2
    local _result=0
    local _prodDir

    prodDir $_iteration _prodDir
    if [ -n "${_prodDir}" ]; then
        prodStopper $_prodDir _stopper
        if [ -n "${_stopper}" ]; then
            echo $"*** Stopping with - $_stopper"
            $_stopper
        else    
            echo $"*** No stopper found for $_prodDir"
        fi        
        echo $"*** removing - $_prodDir"
        rm -Rf $_prodDir
        if [ ! -d "$_prodDir" ]; then
            echo $"*** $_prodDir is gone"
            _result=1
        else 
            echo $"***!!!! $_prodDir is remains"
        fi
    else 
    	echo $"*** No prod dir found for $_iteration"
    fi
    eval $_outvar=\$_result      
}
