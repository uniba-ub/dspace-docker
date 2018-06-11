#!/bin/bash

set +x -o pipefail
#set -e

# get environment variables
source VERSION

DSPACE_VERSION=${DSPACE_VERSION:-dspace-cris-5.8.0}
DSPACE_VCS_URL=${DSPACE_VCS_URL:-https://github.com/4science/dspace}

DOCKER_TAG_tmp=$(echo $DSPACE_VERSION |cut -d- -f3-)
DOCKER_TAG=${DOCKER_TAG:-$DOCKER_TAG_tmp}

DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME:-4science/dspace-cris}


function build(){
     docker build \
       --label org.label-schema.schema-version="1.0" \
       --label org.label-schema.vendor="DSpace-CRIS Community" \
       --label org.label-schema.build-date=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
       --label org.label-schema.version=${TRAVIS_TAG} \
       --label org.label-schema.vcs-ref=${TRAVIS_COMMIT} \
       --label org.label-schema.vcs-url="https://github.com/4science/dspace-docker" \
       --label org.label-schema.name="dspace-docker" \
       --label it.4science.dspace.version=${DSPACE_VERSION} \
       --label it.4science.dspace.vcs-ref=${DSPACE_VCS_REF} \
       --label it.4science.dspace.vcs-url=${DSPACE_VCS_URL} \
       --tag ${DOCKER_IMAGE_NAME}:${DOCKER_TAG} .
}

function clone(){
    echo "Clone 4science/dspace"
    git clone --depth 1 --branch ${DSPACE_VERSION} ${DSPACE_VCS_URL} dspace
}

if [[ "${1}" == "clone" ]]; then
  clone
elif [[ "${1}" == "build" ]]; then
  if [[ -n ${CI} ]]; then
    echo "Running in CI"
   else
     TRAVIS_COMMIT=$(git rev-parse HEAD)
   fi
    build
fi

if [[ $# -eq 0 ]]; then
  if [[ ! -n ${CI} ]]; then
    echo "no CI and no arguments (exec clone and build)"
    clone
    build
#  else
#    echo "CI without arguments => exiting"
  fi
fi
