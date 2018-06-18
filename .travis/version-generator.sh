#!/bin/bash

generate_version_no() { 
    if [ "${TRAVIS_TAG}" == "" ]; then
        export VERSION="SNAPSHOT-`git rev-parse --abbrev-ref HEAD`"
    else
        export VERSION="${TRAVIS_TAG:1}"
    fi

    if [ "${VERSION}" == "HEAD" ]; then
        export VERSION="SNAPSHOT-`git rev-parse --abbrev-ref HEAD`"
    fi
}

generate_build_no() {
    export BUILD=`git rev-parse HEAD`;
}

generate_version_no
generate_build_no

echo "VERSION : ${VERSION}"
echo "BUILD   : ${BUILD}"

unset -f generate_version_no
unset -f generate_build_no
