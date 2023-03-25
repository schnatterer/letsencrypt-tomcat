Let's encrypt Tomcat!
========

[![](https://img.shields.io/docker/image-size/schnatterer/letsencrypt-tomcat)](https://hub.docker.com/r/schnatterer/letsencrypt-tomcat)

Showcase Tomcat Docker Image that automatically fetches and renews certificates via letsencrypt. 

Uses 
* [dehydrated](http://dehydrated.io/) to manage certs, 
* [tomcat-reloading-connector](https://github.com/schnatterer/tomcat-reloading-connector) for reloading images without 
  restarting tomcat. 
* and either
  * [bitmai's Tomcat Docker image](https://hub.docker.com/r/bitnami/tomcat) or
  * spring-boot.
  
Try out by [running examples](#Run-Examples).

# Build your own image

The building blocks are conveniently packaged into a docker image: `schnatterer/letsencrypt-tomcat`.
This image is neither intended to be used as base image nor to be run itself.
It's a mere container were you can copy the components needed for your app.

It contains the following directories:

* `/letsencrypt` necessary for all apps:
  * [`dehydrated`](http://dehydrated.io/) for cert retrival
  * [`dumb-init`](https://github.com/Yelp/dumb-init) for properly handling your main process and the certificate process
  * `meta-entrypoint.sh` for launching the processes
* `[/tomcat-reloading-connector](https://github.com/schnatterer/tomcat-reloading-connector)` necessary for standalone 
  tomcat instances, so they can reload the certificate at runtime  
  See [standalone example](examples/standalone).
* `/lib` - pre-compiled version of Apache Portable Runtime (APR) and JNI wrappers for APR used by Tomcat (libtcnative).  
  Requires glibc and openssl (works with debian images, for example).  
  For other libc libraries see [here](https://tomcat.apache.org/tomcat-9.0-doc/apr.html) for compiling your own APR libs.
  See [spring-boot example](examples/spring-boot) or [embedded tomcat example](examples/embedded-tomcat).  

So in your Dockerfile just copy what you need as shown in examples.
For the whole process to work, your container requires the following packages:

* bash,
* openssl and
* curl

Your tomcat server must be configured to
 * serve static content from `/static/.well-known/acme-challenge` on `http://${DOMAIN}/static/.well-known/acme-challenge` 
   in order for to be able to answer to the letsencrypt challenges,
 * serve traffic via port 80 (externally), in order to succeed in letsencrypt's http-01 challenge,
 * respond with HTTP return code less than 400, on `http://localhost:${LOCAL_HTTP_PORT}/` (default port 8080).

If successful, the certificate files will be stored here:
  * Certificate file: `${CERT_DIR}/${DOMAIN}/cert.pem`
  * Certificate private key file: `${CERT_DIR}/${DOMAIN}/privkey.pem`
  * Certificate chain file: `${CERT_DIR}/${DOMAIN}/fullchain.pem`

# Configuration at runtime

* Mandatory: Env var `DOMAIN` that passes the TLD to be used for requesting certificates for
* Optional Env vars: 
  * `LOCAL_HTTP_PORT` - (default 8080). Once this (internal) port is ready to receive traffic, the certificate challenge will begin.
  * `STAGING` - If set to `true` creates certs against letsencrypt staging, which has no rate limit but 
    is not accepted by your browser.
  * `ENABLE_LETSENCRYPT` - if set to `false` the letsencrypt process is not started 
  * `CREATE_SELFSIGNED` - if set to `false` no selfsigned certifcate is generated at start up.  
     Depending on your setup this might result in failing startup of the tomcat connectors
  * `DEHYDRATED_BASEDIR` - defaults to `/dehydrated` for compatibility with letsencrypt-tomcat <= 0.40.
  * `CERT_DIR` - if `DEHYDRATED_BASEDIR` is set, defaults to `$DEHYDRATED_BASEDIR/certs`, which is the default of dehydrated. If `DEHYDRATED_BASEDIR` is not set, defaults to `/certs` to be compatible with older letsencrypt-tomcat releases <=0.4.0.
  * `DEHYDRATED_WELLKNOWN` - path where dehydrated will place ACME challenge files. Should usually be the document root of a webserver with `/.well-known/acme-challenge` appended.

Note: if you want to save certificates and accounts in persistent storage it is highly recommended to set `DEHYDRATED_BASEDIR` env variable as described below.

`DEHYDRATED_BASEDIR` and `CERT_DIR` interact:
  * default (<=0.4.0) if `DEHYDRATED_BASEDIR` is not set:
    * `DEHYDRATED_BASEDIR="/dehydrated" CERT_DIR="/certs"`
    * `/dehydrated` is not stored in persistent storage and will be deleted with the container (including the letsencrypt account)
  * recommended (>0.4.0):
    * set `DEHYDRATED_BASEDIR="/certs/dehydrated"`. This will set `CERT_DIR="$DEHYDRATED_BASEDIR/certs"`. This allows all the certificates and dehydrated state (most importantly, accounts) to be stored in one directory, usually a volume mounted at `/certs`.

It is possible to set environment variables in any place Docker supports, and will make them set in the container. This is: in a Dockerfile, as run parameters, as docker-compose.yml configuration, or in an .env file.

# Run Examples

First, make sure to set the DNS record to match your IP address and that port 80 and 443 are available.  

Note that:
- `-v...` Persists your cert in a volume `certs` if left out an anonymous volume is used

```bash
sudo docker run --rm -it \
  -p80:8080 -p443:8443 \
  -eDOMAIN=example.com \
  -v certs:/certs/ \
  -eSTAGING=true \
  schnatterer/letsencrypt-tomcat:standalone
# or
# schnatterer/letsencrypt-tomcat:spring-boot
# schnatterer/letsencrypt-tomcat:embedded-tomcat
```

# Building

```bash
# First build the base image ( packages the building blocks for letsencrypt tomcat)
docker build -t schnatterer/letsencrypt-tomcat .
# Build the examples 
docker build -t schnatterer/letsencrypt-tomcat:standalone --file=examples/standalone/Dockerfile .
docker build -t schnatterer/letsencrypt-tomcat:spring-boot --file=examples/spring-boot/Dockerfile .
docker build -t schnatterer/letsencrypt-tomcat:embedded-tomcat --file=examples/embedded-tomcat/Dockerfile .
```
