#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# TODO fail on empty
export DOMAIN=${DOMAIN:-''}
LOCAL_HTTP_PORT=${LOCAL_HTTP_PORT:-8080}
# Use staging to avoid letsencrypt's rate limits!
STAGING=${STAGING:-'false'}
NO_COLOR=${NO_COLOR:-''}
export JAVA_OPTS="-Djava.awt.headless=true -XX:+UseG1GC -Dfile.encoding=UTF-8 -Ddomain=${DOMAIN}" 

BASEDIR=$(dirname $0)
ABSOLUTE_BASEDIR="$( cd ${BASEDIR} && pwd )"

function main() {
    
    # Create self-signed certs in order to not fail on startup
    ${ABSOLUTE_BASEDIR}/createCerts.sh
    
    fetchCerts &
    
    exec /opt/bitnami/scripts/tomcat/entrypoint.sh "$@" 
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