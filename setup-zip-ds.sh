#!/bin/sh

ITERATION="$1"
if [ -z $ITERATION ]; then 
    echo "*** ITERATION is unset, exiting ..."
    exit 1
fi

source ./utils.sh

dsDir $ITERATION DSDIR
ports $ITERATION LDAP LDAPS HTTPS

# stop and remove 
clean $ITERATION CLEANED

echo $"*** Removing temp directory - $TEMP"
rm -Rf $TEMPDIR

echo $"*** Unzipping and renaming package to $DSDIR"
unzip -qq $PACKAGES/$DSBASE/UnboundID-DS-*.zip -d $TEMPDIR
mv $TEMPDIR/UnboundID-DS $DSDIR

echo $"*** Setting up ds in $DSDIR"
$DSDIR/setup --cli --no-prompt --acceptLicense \
--rootUserPassword $PASSWORD  \
--httpsPort $HTTPS \
--ldapPort $LDAP \
--ldapsPort $LDAPS \
--enableStartTLS --generateSelfSignedCertificate --sampleData 2000 \

echo $"*** update tools.properties"
echo "hostname=localhost" >> $DSDIR/config/tools.properties
echo "useNoSecurity=true" >> $DSDIR/config/tools.properties
echo "port=$LDAP" >> $DSDIR/config/tools.properties
echo "bindDN=cn=directory manager" >> $DSDIR/config/tools.properties
echo "bindPassword=$PASSWORD" >> $DSDIR/config/tools.properties
echo "trustAll=true" >> $DSDIR/config/tools.properties