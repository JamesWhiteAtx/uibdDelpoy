#!/bin/sh

ITERATION="$1"
if [ -z $ITERATION ]; then 
    echo "*** ITERATION is unset, exiting ..."
    exit 1
fi
LDAP=$ITERATION"389"
LDAPS=$ITERATION"636"
HTTPS="844"$(($ITERATION + 2))

DSITERATION="$2"
if [ -z $DSITERATION ]; then 
    echo "*** DSITERATION is unset, exiting ..."
    exit 1
fi

source ./utils.sh

ibDir $ITERATION IBDIR
ports $ITERATION LDAP LDAPS HTTPS
dsDir $DSITERATION DSDIR
ports $DSITERATION DSLDAP DSLDAPS DSHTTPS

USERSTORE="$THISHOST:$DSLDAP:$LOCATION"
INSTANCENAME=$IBNAME$ITERATION

echo $"*** Removing temp directory - $TEMPDIR"
./clean.sh $ITERATION CLEANED

echo $"*** Removing temp directory - $TEMPDIR"
rm -Rf $TEMPDIR

echo $"*** unzipping and renaming package to $IBDIR"
unzip -qq $PACKAGES/$IBBASE/UnboundID-Broker-*.zip -d $TEMPDIR
mv $TEMPDIR/UnboundID-BROKER $IBDIR

echo $"*** setting up $IBDIR\setup"
$IBDIR/setup --no-prompt --acceptLicense --location Austin \
--rootUserPassword $PASSWORD \
--httpsPort $HTTPS \
--ldapPort $LDAP \
--ldapsPort $LDAPS \
--enableStartTLS --generateSelfSignedCertificate \
--instanceName $INSTANCENAME 

$IBDIR/bin/prepare-external-store --no-prompt --trustAll \
--port $DSLDAP \
--bindDN "$BINDDN" \
--bindPassword $PASSWORD --brokerBindPassword $PASSWORD \
--userStoreBaseDN "ou=people,dc=example,dc=com" \
--brokerTrustStorePath config/truststore --brokerTrustStorePasswordFile config/truststore.pin

$IBDIR/bin/create-initial-broker-config --no-prompt \
--port $LDAP \
--bindDN "$BINDDN" \
--bindPassword $PASSWORD --brokerBindPassword $PASSWORD \
--externalServerConnectionSecurity noSecurity \
--userStore $USERSTORE \
--initialSchema "user-and-ref-app" \
--userStoreBaseDN "ou=people,dc=example,dc=com" \

echo $"*** update tools.properties"
echo "hostname=localhost" >> $IBDIR/config/tools.properties
echo "useNoSecurity=true" >> $IBDIR/config/tools.properties
echo "port=$LDAP" >> $IBDIR/config/tools.properties
echo "bindDN=cn=directory manager" >> $IBDIR/config/tools.properties
echo "bindPassword=$PASSWORD" >> $IBDIR/config/tools.properties
echo "trustAll=true" >> $IBDIR/config/tools.properties

echo $"\n*** Configuring CORS...\n"
#TODO: update the CORS origins 
$IBDIR/bin/dsconfig set-http-servlet-cross-origin-policy-prop --policy-name Restrictive \
--set cors-allowed-methods:GET --set cors-allowed-methods:PUT --set cors-allowed-methods:PATCH \
--set cors-allowed-methods:POST --set cors-allowed-methods:DELETE \
--set cors-allowed-origins:"http://0.0.0.0:8099" \
--set cors-allowed-origins:"http://"$THISHOST":8099" \
--set cors-allowed-origins:"https://localhost:"$HTTPS \
--set cors-allowed-origins:"https://"$THISHOST":"$HTTPS \
--set cors-allowed-headers:Accept --set cors-allowed-headers:Access-Control-Request-Headers \
--set cors-allowed-headers:Access-Control-Request-Method --set cors-allowed-headers:Authorization \
--set cors-allowed-headers:Content-Type --set cors-allowed-headers:Origin \
--set cors-allowed-headers:X-Requested-With --set cors-allow-credentials:true \
-h $THISHOST \
-p $LDAP \
-D "$BINDDN" -w $PASSWORD --useNoSecurity --trustAll -n

$IBDIR/dsconfig -n create-http-servlet-cross-origin-policy --policy-name auth-ui \
--set cors-allowed-methods:GET --set cors-allowed-methods:PUT --set cors-allowed-methods:DELETE \
--set cors-allowed-origins:"https://localhost:"$HTTPS \
--set cors-allowed-origins:"https://"$THISHOST":"$HTTPS \
--set cors-allowed-origins:"http://localhost:3000" \
--set cors-allowed-origins:"http://"$THISHOST":3000" \
--set cors-allow-credentials:true

$IBDIR/dsconfig set-http-servlet-extension-prop --extension-name "OAuth2 Servlet" --set cross-origin-policy:auth-ui -n 
$IBDIR/dsconfig set-http-servlet-extension-prop --extension-name "Session Servlet" --set cross-origin-policy:auth-ui -n 

$IBDIR/bin/dsconfig set-http-servlet-extension-prop --extension-name "Configuration" \
--set cross-origin-policy:Restrictive \
-h $THISHOST \
-p $LDAP \
-D "$BINDDN" -w $PASSWORD --useNoSecurity --trustAll -n

$IBDIR/bin/dsconfig set-http-servlet-extension-prop --extension-name "OAuth Servlet" \
--set cross-origin-policy:Restrictive \
-h $THISHOST \
-p $LDAP \
-D "$BINDDN" -w $PASSWORD --useNoSecurity --trustAll -n 

$IBDIR/bin/dsconfig set-http-servlet-extension-prop --extension-name "Policy Decision Point Servlet" \
--set cross-origin-policy:Restrictive \
-h $THISHOST \
-p $LDAP \
-D "$BINDDN" -w $PASSWORD --useNoSecurity --trustAll -n 

$IBDIR/bin/dsconfig set-http-servlet-extension-prop --extension-name "SCIM2" \
--set cross-origin-policy:Restrictive \
-h $THISHOST \
-p $LDAP \
-D "$BINDDN" -w $PASSWORD --useNoSecurity --trustAll -n 

$IBDIR/bin/dsconfig set-http-servlet-extension-prop --extension-name "UserInfo Servlet" \
--set cross-origin-policy:Restrictive \
-h $THISHOST \
-p $LDAP \
-D "$BINDDN" -w $PASSWORD --useNoSecurity --trustAll -n 

echo $"\n*** Installing Sample Applications...\n"
tar -xf $IBDIR/samples/my-account.tar.gz -C $IBDIR/samples/
$IBDIR/bin/dsconfig -n --batch-file $IBDIR/samples/my-account/setup.dsconfig

echo $"\n*** Stopping Broker...\n"
$IBDIR/bin/stop-broker

echo $"\n*** Stopping DS...\n"
$DSDIR/bin/stop-ds

echo $"\n*** Installing Sample Users...\n"
$IBDIR/bin/make-ldif \
--templateFile $IBDIR/resource/starter-schemas/reference-apps-make-ldif.template \
--ldifFile $DSDIR/reference-apps-user-entries.ldif \

$DSDIR/bin/import-ldif --ldifFile $DSDIR/reference-apps-user-entries.ldif \
--includeBranch dc=example,dc=com --rejectFile $DSDIR/reject.ldif -r \

echo $"\n*** Starting DS...\n"
$DSDIR/bin/start-ds

echo $"\n*** Starting Broker...\n"
$IBDIR/bin/start-broker

echo $"\n*** Adding CSR entitlement...\n"
$DSDIR/bin/ldapmodify -p $DSLDAP \
--bindDN "$BINDDN" \
--bindPassword $PASSWORD \
-f $IBDIR/resource/starter-schemas/entitlements-ldap-modify.ldif
