#!/bin/sh

ITERATIONER="$1"
if [ -z $ITERATIONER ]; then 
    echo "*** ITERATIONER is unset, exiting ..."
    exit 1
fi

ITERATIONEE="$2"
if [ -z $ITERATIONEE ]; then 
    echo "*** ITERATIONEE is unset, exiting ..."
    exit 1
fi

source ./utils.sh

ports $ITERATIONER LDAPER LDAPSER HTTPSER
ports $ITERATIONEE LDAPEE LDAPSEE HTTPSEE

prodDir $ITERATIONER DIRER NAMEER
prodDir $ITERATIONEE DIREE NAMEEE

# echo DIRER $DIRER
# echo DIREE $DIREE
# echo NAMEER $NAMEER
# echo NAMEEE $NAMEEE

# echo ldaper $LDAPER
# echo ldapser $LDAPSER
# echo httpser $HTTPSER

# echo ldapee $LDAPEE
# echo ldapsee $LDAPSEE
# echo httpsee $HTTPSEE

# USERSTORE=$THISHOST":$DSLDAP:$LOCATION"

# echo $DIRER
# echo $NAMEEE
# echo $LDAPSEE
# echo $THISHOST
# echo $LDAPER
# echo $BINDDN
# echo $PASSWORD

echo $"\n*** Register $NAMEER with $NAMEEE ...\n"
$DIRER/bin/dsframework register-server \
--serverID $NAMEEE \
--set ldapsport:$LDAPSEE \
--set ldapsEnabled:true \
--set hostname:$THISHOST \
-p $LDAPER \
--bindDN "$BINDDN" \
--bindPassword $PASSWORD \

echo $"\n*** Register $NAMEEE with $NAMEER ...\n"
$DIREE/bin/dsframework register-server \
--serverID $NAMEER \
--set ldapsport:$LDAPSER \
--set ldapsEnabled:true \
--set hostname:$THISHOST \
-p $LDAPEE \
--bindDN "$BINDDN" \
--bindPassword $PASSWORD \
