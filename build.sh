#!/bin/bash
CONTAINER_NAME="docker-gocd-agent-debian-10-aniemann"
REGISTRY="registry.olsitec.de:20443/olsitec"
VERSION="`cat ${_workdir}/version`"

_workdir="`dirname $0`"

if [ "$VERSION" == "" ]
then
  echo "VERSION is empty"
  exit 1
fi

docker build -t "${REGISTRY}/${CONTAINER_NAME}:${VERSION}" -t "${REGISTRY}/${CONTAINER_NAME}:latest" "${_workdir}"
docker push "${REGISTRY}/${CONTAINER_NAME}"
