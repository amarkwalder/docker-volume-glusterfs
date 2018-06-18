#!/bin/bash

generate_build_version_no() { 
    if [ "${TRAVIS_TAG}" == "" ]; then
        export BUILD_VERSION="SNAPSHOT_${BUILD_TS}"
    else
        export BUILD_VERSION="${TRAVIS_TAG:1}"
    fi
}

generate_build_no() {
    export BUILD_COMMIT_REF=`git rev-parse HEAD`;
}

generate_build_date() {
    export BUILD_TS=`date +%Y%m%d_%H%M%S%Z`
    export BUILD_DATE=`date +%FT%T%Z`
}

generate_build_date
generate_build_version_no
generate_build_no

echo "BUILD_VERSION      : ${BUILD_VERSION}"
echo "BUILD_COMMIT_REF   : ${BUILD_COMMIT_REF}"
echo "BUILD_DATE         : ${BUILD_DATE}"

unset -f generate_build_version_no
unset -f generate_build_no
unset -f generate_build_date
