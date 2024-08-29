#!/bin/sh
export DOCKERHUB_USER=digitalemil
export DOCKERHUB_REPO=sourdough

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

docker kill gameday
docker rm gameday
docker run --name gameday -e secret_key=$secret_key -e cluster_id=$cluster_id -e cluster_region=$cluster_region -p 8080:8080 $DOCKERHUB_USER/$DOCKERHUB_REPO:gameday-o11y-vlatest