#!/bin/sh

ITERATION="$1"
if [ -z $ITERATION ]; then 
    echo "*** ITERATION is unset, exiting ..."
    exit 1
fi

source ./utils.sh

syDir $ITERATION SYDIR
echo $"*** SYDIR - $SYDIR"
ports $ITERATION LDAP LDAPS HTTPS
echo $"*** LDAP - $LDAP"
echo $"*** LDAPS - $LDAPS"
echo $"*** HTTPS - $HTTPS"

# stop and remove 
clean $ITERATION CLEANED

echo $"*** Removing temp directory - $TEMPDIR"
rm -Rf $TEMPDIR

echo $"*** Unzipping and renaming package to $PACKAGES/$SYBASE/UnboundID-Sync-*.zip"
unzip -qq $PACKAGES/$SYBASE/UnboundID-Sync-*.zip -d $TEMPDIR
mv $TEMPDIR/UnboundID-Sync $SYDIR

echo $"*** Setting up sync in $SYDIR"
$SYDIR/setup --cli --no-prompt --acceptLicense \
--rootUserPassword $PASSWORD  \
--httpsPort $HTTPS \
--ldapPort $LDAP \
--ldapsPort $LDAPS \
--enableStartTLS --generateSelfSignedCertificate 

echo $"*** update tools.properties"
echo "hostname=localhost" >> $SYDIR/config/tools.properties
echo "useNoSecurity=true" >> $SYDIR/config/tools.properties
echo "port=$LDAP" >> $SYDIR/config/tools.properties
echo "bindDN=cn=directory manager" >> $SYDIR/config/tools.properties
echo "bindPassword=$PASSWORD" >> $SYDIR/config/tools.properties
echo "trustAll=true" >> $SYDIR/config/tools.properties