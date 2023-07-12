#!/bin/bash

echo ""
echo ""
#temp for container version
cd /scriptrun


# default directories
TOMCFG=config/tomcat
TOMCERT=credentials/tomcat
TOMWWWROOT=wwwroot
SHBCFG=config/shib-idp/conf
SHBCREDS=credentials/shib-idp
SHBMSGS=config/shib-idp/messages
SHBMD=config/shib-idp/metadata

# logs
LOGFILE=${PWD}/setup.log

# script variables (do not edit)
ORACLE_JAVA_APPROVAL=None
FQDN=None
SCOPE=None
LDAPURL=None
LDAPBASEDN=None
LDAPDN=None
LDAPPWD=None
SEALERPWD=None
TIER_TESTBED=None
BURNMOUNT=None
USESECRETS=None


#####################################################
### ask setup questions to aid in config building ###
#####################################################
#
# Get the FQDN of the server
#
echo ""
echo ""
echo "Please supply the Fully Qualified Domain Name (FQDN) of your Shibboleth IdP."
echo "We will use the information you enter here to configure your IdP."
echo "Note: for testing without DNS support (a common case), simply enter"
echo "      the IPv4 address of your VM at the prompt below"
echo ""
while [ ${FQDN} == "None" ]; do
    echo -n "Enter the FQDN or IP address of your server: "
    read response
    if [ ${#response} -lt 8  ]; then
        echo "Remember, you need a FQDN or IP address"
        continue
    fi
    echo -n "You entered: ${response}    Is this correct [Yes/No]? "
    read yesno
    case $yesno in
        Yes|yes|Y|y)
            FQDN=$response
            ;;
    esac
done
#echo "FQDN is: $FQDN"

#
# Get the Scope used for this IdP
#
echo ""
echo ""
echo "Please supply the correct scope for this IdP."
echo "This is typically your base domain: domain.edu"
echo "Enter your IP address if you are just testing."
echo ""
echo "We will use the information you enter here to configure your IdP."
echo ""
while [ ${SCOPE} == "None" ]; do
    echo -n "Enter the Scope for your IdP [`expr "$FQDN" | cut -f2- -d.`]: "
    read response
    TMPSCOPE=${response:-`expr "$FQDN" | cut -f2- -d.`}
    if [ ${#TMPSCOPE} -lt 5  ]; then
        echo "Remember, you need domain - domain.edu or similar"
        continue
    fi
    echo -n "You entered: ${TMPSCOPE}    Is this correct [Yes/No]? "
    read yesno
    case $yesno in
        Yes|yes|Y|y)
            SCOPE=$TMPSCOPE
            ;;
    esac
done
#echo "Scope is: $SCOPE"

#
# Get the LDAP URL for this deployment
#
echo ""
echo ""
echo "Please supply the full LDAP URL for your backend authentication and/or "
echo "attribute store used by your Shibboleth IdP. (e.g. ldap://myldap.domain.edu)"
echo "We will use the information you enter here to configure your IdP."
echo ""
while [ ${LDAPURL} == "None" ]; do
    echo -n "Enter the LDAP URL used for your IdP: "
    read response
    if [ ${#response} -lt 10  ]; then
        echo "Remember, you need a full LDAP URL (starts with ldap:// or ldaps://)"
        continue
    fi
    echo -n "You entered: ${response}    Is this correct [Yes/No]? "
    read yesno
    case $yesno in
        Yes|yes|Y|y)
            LDAPURL=$response
            ;;
    esac
done
#echo "LDAP URL is: $LDAPURL"

#
# Get the LDAP BaseDN for this deployment
#
echo ""
echo ""
echo "Please supply the LDAP Base DN for your LDAP Server "
echo "   (e.g. ou=people,dc=example,dc=org)."
echo "We will use the information you enter here to configure your IdP."
echo ""
while [ ${LDAPBASEDN} == "None" ]; do
    echo -n "Enter the LDAP Base DN used for your LDAP Server: "
    read response
    if [ ${#response} -lt 10  ]; then
        echo "Remember, you need the full LDAP Base DN."
        continue
    fi
    echo -n "You entered: ${response}    Is this correct [Yes/No]? "
    read yesno
    case $yesno in
        Yes|yes|Y|y)
            LDAPBASEDN=$response
            ;;
    esac
done

#
# Get the LDAP DN for this deployment
#
echo ""
echo ""
echo "Please supply the full LDAP DN (DistinguishedName) for the account "
echo "used to access your LDAP (only read access is necessary). "
echo "(e.g. uid=myservice,ou=system)"
echo "We will use the information you enter here to configure your IdP."
echo ""
while [ ${LDAPDN} == "None" ]; do
    echo -n "Enter the LDAP DN for the service account used by your IdP: "
    read response
    if [ ${#response} -lt 8  ]; then
        echo "Remember, you need the full LDAP DN"
        continue
    fi
    echo -n "You entered: ${response}    Is this correct [Yes/No]? "
    read yesno
    case $yesno in
        Yes|yes|Y|y)
            LDAPDN=$response
            ;;
    esac
done

#
# Get the LDAP PWD for this deployment
#
echo ""
echo ""
echo "Please supply the password for the LDAP DN just specified "
echo "for access your LDAP"
echo ""
echo "We will use the information you enter here to configure your IdP."
echo ""
while [ ${LDAPPWD} == "None" ]; do
    echo -n "Enter the password for the account just specified: "
    read response
    if [ ${#response} -lt 2  ]; then
        echo "You should use a stronger password."
        continue
    fi
    echo -n "You entered: ${response}    Is this correct [Yes/No]? "
    read yesno
    case $yesno in
        Yes|yes|Y|y)
            LDAPPWD=$response
            ;;
    esac
done


#######################################
## support for secrets is deprecated ##
#######################################
USESECRETS=NO
BURNMOUNT=burn


############################################################
### generate credentials/certs for tomcat and shibboleth ###
############################################################

# ensure openssl
command -v openssl >/dev/null 2>&1 || { echo >&2 "ERROR: openssl is required, but doesn't appear to be installed.  Aborting..."; exit 1; }

echo ""
echo "Generating credentials..."
echo ""
#
mkdir -p crypto-work-tmp
cd crypto-work-tmp
#IdP Signing key/cert
openssl req -new -nodes -newkey rsa:2048 -subj "/commonName=${FQDN}" -batch -keyout idp-signing.key -out idp-signing.csr >> ${LOGFILE} 2>&1
echo '[SAN]' > extensions
echo "subjectAltName=DNS:${FQDN},URI:https://${FQDN}/idp/shibboleth" >>extensions
echo "subjectKeyIdentifier=hash" >> extensions
openssl x509 -req -days 1825 -in idp-signing.csr -signkey idp-signing.key -extensions SAN -extfile extensions -out idp-signing.crt >> ${LOGFILE} 2>&1
#
# IdP Encryption Key
openssl req -new -nodes -newkey rsa:2048 -subj "/commonName=${FQDN}" -batch -keyout idp-encryption.key -out idp-encryption.csr >> ${LOGFILE} 2>&1
openssl x509 -req -days 1825 -in idp-encryption.csr -signkey idp-encryption.key -extensions SAN -extfile extensions -out idp-encryption.crt >> ${LOGFILE} 2>&1
#
cp *.key *.crt ../${SHBCREDS}

# build self-signed cert for Tomcat to use with https
#
# ensure keytool
command -v keytool >/dev/null 2>&1 || { echo >&2 "ERROR: keytool is required, but doesn't appear to be installed.  Aborting..."; exit 1; }

if test -f ssl_keystore.jks; then
    mv ssl_keystore.jks ssl_keystore.jks.old
fi

cat > data.conf << EOF
${FQDN}
SUBJ_OU
SUBJ_O
SUBJ_CITY
SUBJ_STATE
SUBJ_COUNTRY
yes
EOF

apt-get install uuid-runtime

STOREPWD=$(uuidgen)
keytool -genkey -keyalg RSA -alias selfsigned -keystore ssl_keystore.jks -storepass $STOREPWD -validity 360 -keysize 2048 < data.conf >> ${LOGFILE} 2>&1
cp ssl_keystore.jks ../${TOMCERT}/keystore.jks

#
# OK, next build the shibboleth sealer java keystore
#
echo ""
echo "Creating Shibboleth sealer keystore"
echo ""
#
rm -f mysealer.jks
SEALERPWD=$(uuidgen)
keytool -genseckey -storetype jceks -alias secret1 -providername SunJCE -keyalg AES -keysize 256 -storepass ${SEALERPWD} -keypass ${SEALERPWD} -keystore mysealer.jks >> ${LOGFILE} 2>&1
cp mysealer.jks ../${SHBCREDS}/sealer.jks


# return to previous work directory
cd ..
#remove work dir
rm -rf crypto-work-tmp/*
rmdir crypto-work-tmp


#############################
### generate new metadata ###
#############################
CERTFILE=${SHBCREDS}/idp-signing.crt
CERT="$(grep -v '^-----' $CERTFILE)"
ENTITYID=https://${FQDN}/idp/shibboleth
BASEURL=https://${FQDN}

cat > ${SHBMD}/idp-metadata.xml <<EOF
<EntityDescriptor entityID="$ENTITYID" xmlns="urn:oasis:names:tc:SAML:2.0:metadata" xmlns:shibmd="urn:mace:shibboleth:metadata:1.0" xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
  <IDPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
    <Extensions>
      <shibmd:Scope regexp="false">$SCOPE</shibmd:Scope>
    </Extensions>
    <KeyDescriptor use="signing">
      <ds:KeyInfo>
        <ds:X509Data>
          <ds:X509Certificate>
$CERT
          </ds:X509Certificate>
        </ds:X509Data>
      </ds:KeyInfo>
    </KeyDescriptor>
    <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="$BASEURL/idp/profile/SAML2/Redirect/SSO"/>
    <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="$BASEURL/idp/profile/SAML2/POST/SSO"/>
    <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST-SimpleSign" Location="$BASEURL/idp/profile/SAML2/POST-SimpleSign/SSO"/>
    <SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP" Location="$BASEURL/idp/profile/SAML2/SOAP/ECP"/>
  </IDPSSODescriptor>
</EntityDescriptor>
EOF



##############################################################################
### make needed adjustments to IdP config and Dockerfile and Tomcat config ###
##############################################################################
#
#ensure sed
command -v sed >/dev/null 2>&1 || { echo >&2 "ERROR: sed is required, but doesn't appear to be installed.  Aborting..."; exit 1; }

# set entityID, sealer pwd in idp.properties
echo ""
echo "Updating your IdP config and Dockerfile to match the info"
echo "  you supplied and with the auto-generated key password."
echo ""
IDP_PROP=${SHBCFG}/idp.properties

if test \! -f ${IDP_PROP}.dist; then
    cp ${IDP_PROP} ${IDP_PROP}.dist
fi

sed "s/idp.example.org\/idp\/shibboleth/${FQDN}\/idp\/shibboleth/" ${IDP_PROP}.dist > ${IDP_PROP}.tmp
sed "s/=example.org/=${SCOPE}/" ${IDP_PROP}.tmp > ${IDP_PROP}
rm -f ${IDP_PROP}.tmp
#

# set ldap URL, baseDN, svcDN, pwd in ldap.properties
LDAP_PROP=${SHBCFG}/ldap.properties
if test \! -f ${LDAP_PROP}.dist; then
    cp ${LDAP_PROP} ${LDAP_PROP}.dist
fi

sed "s/#idp.authn.LDAP.authenticator/idp.authn.LDAP.authenticator/" ${LDAP_PROP}.dist > ${LDAP_PROP}.tmp
sed "s/= anonSearchAuthenticator/= bindSearchAuthenticator/" ${LDAP_PROP}.tmp > ${LDAP_PROP}.tmp2
sed "s#ldap://localhost:10389#${LDAPURL}#" ${LDAP_PROP}.tmp2 > ${LDAP_PROP}.tmp3
sed "s#uid=myservice,ou=system#${LDAPDN}#" ${LDAP_PROP}.tmp3 > ${LDAP_PROP}.tmp4
sed "s#ou=people,dc=example,dc=org#${LDAPBASEDN}#" ${LDAP_PROP}.tmp4 > ${LDAP_PROP}
rm -f ${LDAP_PROP}.tmp
rm -f ${LDAP_PROP}.tmp2
rm -f ${LDAP_PROP}.tmp3
rm -f ${LDAP_PROP}.tmp4


#################################
## generate secrets.properties ##
#################################
cat > ./${SHBCREDS}/secrets.properties << EOF
# This is a reserved spot for most properties containing passwords or other secrets.
# Created by install at $(date)
# Access to internal AES encryption key
idp.sealer.storePassword = ${SEALERPWD}
idp.sealer.keyPassword = ${SEALERPWD}
# Default access to LDAP authn and attribute stores. 
idp.authn.LDAP.bindDNCredential              = ${LDAPPWD}
idp.attribute.resolver.LDAP.bindDNCredential = %{idp.authn.LDAP.bindDNCredential:undefined}
# Salt used to generate persistent/pairwise IDs, must be kept secret
#idp.persistentId.salt = changethistosomethingrandom
EOF


# configure SSL keystore password in tomcat's config file: 
#    conf/tomcat/server.xml replace: keystorePass="password"
#
echo "Updating Tomcat's server.xml with the generated password"

if test \! -f ${TOMCFG}/server.xml.dist; then
    cp ${TOMCFG}/server.xml ${TOMCFG}/server.xml.dist
fi
sed "s#keystorePass=\"password\"#keystorePass=\"${STOREPWD}\"#" ${TOMCFG}/server.xml.dist > ${TOMCFG}/server.xml



############################################################################################################################
### notify user of next steps (docker build and docker run commands, based on burn/mount and chosen directory locations) ###
############################################################################################################################
echo ""
echo "Your initial configuration has been successfully built."
echo ""
echo ""



echo config saved to configured local directory
echo ""
echo ""
