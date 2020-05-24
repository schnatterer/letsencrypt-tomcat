Let's encrypt Tomcat!
========

[![](https://img.shields.io/docker/image-size/schnatterer/letsencrypt-tomcat)](https://hub.docker.com/r/schnatterer/letsencrypt-tomcat)

Showcase Tomcat Docker Image that automatically fetches and renews certificates via letsencrypt. 

Uses 
* [bitmai's Tomcat Docker image](https://hub.docker.com/r/bitnami/tomcat) as base,
* [dehydrated](http://dehydrated.io/) to manage certs, and
* [tomcat-reloading-connector](https://github.com/schnatterer/tomcat-reloading-connector) for reloading images without 
  restarting tomcat. 
  
# Usage

Make sure to set the DNS record to match your IP address first.

```bash
docker build -t schnatterer/letsencrypt-tomcat
sudo docker run --rm -it \
  -p80:8080 -p443:8443 \
  -eDOMAIN=example.com \
  # You might want to persist your certs
  -v certs:/etc/dehydrated/certs/
  # Avoid letsencrypt rate limit for testing
  -eSTAGING=true \ 
  schnatterer/letsencrypt-tomcat
```

