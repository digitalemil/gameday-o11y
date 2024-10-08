#!/bin/sh
export DOCKERHUB_USER=digitalemil
export DOCKERHUB_REPO=sourdough

if [[ "$DEDICATED" == "true" ]]; then
  if [[ -z "${secret_key}" ]]; then
    echo Please verify necessary environment variables are set: secret_key
    exit -1
  fi

  if [[ -z "${cluster_id}" ]]; then
    echo Please verify necessary environment variables are set: cluster_id
    exit -1
  fi

  if [[ -z "${cluster_region}" ]]; then
    echo Please verify necessary environment variables are set: cluster_region
    exit -1
  fi

  if [[ -z "${DATABASE}" ]]; then
    echo Please verify necessary environment variables are set: DATABASE \(e.g. defaultdb\)
    exit -1
  fi

  if [[ -z "${DATABASE_USER}" ]]; then
    echo Please verify necessary environment variables are set: DATABASE_USER 
    exit -1
  fi

  if [[ -z "${DATABASE_PASSWORD}" ]]; then
    echo Please verify necessary environment variables are set: DATABASE_PASSWORD
    exit -1
  fi

  if [[ -z "${DATABASE_URL}" ]]; then
    echo Please verify necessary environment variables are set: DATABASE_URL
    exit -1
  fi
fi

if [[ -z "${SMTPPASSWORD}" ]]; then
  echo Please verify necessary environment variables are set: SMTPPASSWORD
  exit -1
fi

if [[ -z "${EMAILRECIPIENT}" ]]; then
  echo Please verify necessary environment variables are set: EMAILRECIPIENT
  exit -1
fi

if [[ "$DEDICATED" != "true" ]]; then
  DATABASE_URL=127.0.0.1:26257
  DATABASE_USER=root
  DATABASE_PASSWORD=
fi
export SMTPHOST=smtp.strato.de:587
export SMTPUSER=tickets@digitalemil.de




docker kill gameday
docker rm gameday
#docker pull $DOCKERHUB_USER/$DOCKERHUB_REPO:gameday-o11y-vlatest
docker run --name gameday -e DEDICATED=$DEDICATED -e SMTPHOST=$SMTPHOST -e SMTPUSER=$SMTPUSER -e SMTPPASSWORD=$SMTPPASSWORD -eEMAILRECIPIENT=$EMAILRECIPIENT -e DATABASE=$DATABASE -e DATABASE_USER=$DATABASE_USER -e DATABASE_URL=$DATABASE_URL -e DATABASE_PASSWORD=$DATABASE_PASSWORD -e secret_key=$secret_key -e cluster_id=$cluster_id -e cluster_region=$cluster_region -p 7979:7979 -p 8080:8080 -p 8081:8081 -p 8082:8082 -p 8083:8083 -p 8084:8084 -p 38991:38991 $DOCKERHUB_USER/$DOCKERHUB_REPO:gameday-o11y-vlatest