#!/usr/local/bin/dumb-init /bin/bash
set -o errexit -o nounset -o pipefail

export DOMAIN=${DOMAIN:-''}
LOCAL_HTTP_PORT=${LOCAL_HTTP_PORT:-8080}
STAGING=${STAGING:-'false'}
NO_COLOR=${NO_COLOR:-''}
SELF_SIGNED_CERT_VALIDITY_DAYS=${SELF_SIGNED_CERT_VALIDITY_DAYS:-30}
CERT_DIR=${CERT_DIR:-"/certs/${DOMAIN}"}
export JAVA_OPTS="-Djava.awt.headless=true -XX:+UseG1GC -Dfile.encoding=UTF-8 -Ddomain=${DOMAIN}" 


function main() {
    
    [[ -z ${DOMAIN} ]] && >&2 echo "Mandatory Env Var DOMAIN not set. Exiting." && return 1
     
    # Create self-signed certs in order to not fail on startup
    createSelfSignedCert
    
    fetchCerts &
    
    export LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    exec "$@" 
}

createSelfSignedCert() {
    
    certDir=${CERT_DIR}
    cert=cert.pem
    pk=privkey.pem
    ca=fullchain.pem
    host=localhost
    ipAddress=$(hostname -i | awk '{print $1}')

    mkdir -p ${certDir}
    cd "${certDir}"
    
    if [[ ! -f "${cert}" ]]; then

        echo "Creating and trusting self-signed certificate for host ${host}"

        # Create CA
        openssl req -newkey rsa:4096 -keyout ca.pk.pem -x509 -new -nodes -out ${ca} \
          -subj "/OU=Unknown/O=Unknown/L=Unknown/ST=unknown/C=DE"  -days "${SELF_SIGNED_CERT_VALIDITY_DAYS}"

        subjectAltName="$(printf "subjectAltName=IP:127.0.0.1,IP:%s,DNS:%s" "${ipAddress}" "${host}")"
        openssl req -new -newkey rsa:4096 -nodes -keyout ${pk} -out csr.pem \
               -subj "/CN=${host}/OU=Unknown/O=Unknown/L=Unknown/ST=unknown/C=DE" \
               -config <(cat /etc/ssl/openssl.cnf <(printf "\n[SAN]\n%s" "${subjectAltName}"))

        # Sign Cert
        # Due to a bug in openssl, extensions are not transferred to the final signed x509 cert
        # https://www.openssl.org/docs/man1.1.0/man1/x509.html#BUGS
        # So add them while signing. The one added with "req" will probably be ignored.
        openssl x509 -req -in csr.pem -CA ${ca} -CAkey ca.pk.pem -CAcreateserial -out ${cert} -days "${SELF_SIGNED_CERT_VALIDITY_DAYS}" \
                -extensions v3_ca -extfile <(printf "\n[v3_ca]\n%s" "${subjectAltName}")
    else
       echo "Certificate found, skipping creation (cert location: ${CERT_DIR}/${cert})"
    fi
    cd -
}

function fetchCerts() {

   if [[ "${STAGING}" == "true" ]]; then
     echo 'CA="https://acme-staging-v02.api.letsencrypt.org/directory"' >> /etc/dehydrated/config
   fi
   
   green "Waiting for tomcat to become ready on localhost:${LOCAL_HTTP_PORT}"
   while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' localhost:${LOCAL_HTTP_PORT})" -ge 500 ]]; do sleep 1; done
   green "Tomcat is ready."

    trap 'SIG_INT_RECEIVED="true" && green "Stopping certificate process"' INT 
    
    SIG_INT_RECEIVED='false'
    
    while [[ "${SIG_INT_RECEIVED}" == 'false' ]]; do
        green "Trying to fetch certificates"
        dehydrated --domain ${DOMAIN} --cron --accept-terms && exitCode=$? || exitCode=$?
        if [[ "${exitCode}" > 0 ]]; then
            red "Fetching certificates failed"
        fi
        green "Waiting for a day before checking on certificate again."
        sleep 86400
    done
}

function green() {
    if [[ -z ${NO_COLOR} ]]; then
        echo -e "${GREEN}$@${DEFAULT_COLOR}"
    else 
        echo "$@"
    fi
}

function red() {
    if [[ -z ${NO_COLOR} ]]; then
        echo -e "${RED}$@${DEFAULT_COLOR}"
    else 
        echo "$@"
    fi
}

GREEN='\033[0;32m'
RED='\033[0;31m'
DEFAULT_COLOR='\033[0m'


main "$@"