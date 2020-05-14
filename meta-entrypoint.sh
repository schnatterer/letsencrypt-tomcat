#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# TODO fail on empty
export DOMAIN=${DOMAIN:-''}
# Use staging to avoid letsencrypt's rate limits!
STAGING=${STAGING:-'false'}
export JAVA_OPTS="-Djava.awt.headless=true -XX:+UseG1GC -Dfile.encoding=UTF-8 -Ddomain=${DOMAIN}" 

BASEDIR=$(dirname $0)
ABSOLUTE_BASEDIR="$( cd ${BASEDIR} && pwd )"

function main() {
    
    # Create self-signed certs in order to not fail on startup
    ${ABSOLUTE_BASEDIR}/createCerts.sh
    
    fetchCerts &
    
    exec authbind --deep /opt/bitnami/scripts/tomcat/entrypoint.sh "$@" 
}

function fetchCerts() {

   if [[ "${STAGING}" == "true" ]]; then
     echo 'CA="https://acme-staging-v02.api.letsencrypt.org/directory"' >> /etc/dehydrated/config
   fi
   
   green "Waiting for tomcat to become ready"
   while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' localhost:80)" != "404" ]]; do sleep 1; done
   green "Tomcat is ready."

    trap 'SIG_INT_RECEIVED="true" && green "Stopping certifcate process"' INT 
    
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
    echo -e "${GREEN}$@${NO_COLOR}"
}

function red() {
    echo -e "${RED}$@${NO_COLOR}"
}

GREEN='\033[0;32m'
RED='\033[0;31m'
NO_COLOR='\033[0m'


main "$@"