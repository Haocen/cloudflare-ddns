FROM alpine:latest

LABEL maintainer=Haocen.xu@gmail.com

RUN apk add --no-cache curl
RUN apk add --no-cache bash

WORKDIR /usr/scripts

COPY update_ddns.sh ./

ENV IP_DETECTOR_ENDPOINT https://check.torproject.org/
ENV ZONE_ID z1415926535897932384626433
ENV DNS_RECORD_ID d1415926535897932384626433
ENV API_TOKEN k1415926535897932384626433
ENV TTL 1
ENV DEBUG false

RUN chmod 555 update_ddns.sh

CMD while /bin/true; do ./update_ddns.sh; /bin/sleep 60; done
