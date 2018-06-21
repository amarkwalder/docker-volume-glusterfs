#!/bin/bash

install-changelog-generator() {
	gem install rack -v 1.6.4
	gem install github_changelog_generator
}

setup-git() {
    git config --global user.email $CHANGELOG_USER_EMAIL
    git config --global user.name $CHANGELOG_USER_NAME
}

create-and-push-changelog() {
	rev=$(git rev-parse --short HEAD)
	git remote add upstream "https://$GITHUB_TOKEN@github.com/$TRAVIS_REPO_SLUG.git"
	git fetch upstream
	git checkout $TRAVIS_BRANCH

	github_changelog_generator -t $GITHUB_TOKEN --future-release $BUILD_VERSION

	git add -A CHANGELOG.md
	git commit -m "Updated changelog at ${rev} [skip ci]"
	git push upstream $TRAVIS_BRANCH
}

deploy-changelog() {
	install-changelog-generator
	setup-git
	create-and-push-changelog
}

echo "CHANGELOG_USER_NAME  : $CHANGELOG_USER_NAME"
echo "CHANGELOG_USER_EMAIL : $CHANGELOG_USER_EMAIL"
echo "GITHUB_TOKEN         : ( length = ${#GITHUB_TOKEN} )"
echo "TRAVIS_REPO_SLUG     : $TRAVIS_REPO_SLUG"
echo "TRAVIS_PULL_REQUEST  : $TRAVIS_PULL_REQUEST"
echo "BUILD_VERSION        : $BUILD_VERSION"

if [[ ! ${CHANGELOG_USER_NAME+x} ]]; then
	echo "Variable 'CHANGELOG_USER_NAME' not set. Changelog not updated!"
	exit 1
fi
if [[ ! ${CHANGELOG_USER_EMAIL+x} ]]; then
	echo "Variable 'CHANGELOG_USER_EMAIL' not set. Changelog not updated!"
	exit 1
fi
if [[ ! ${GITHUB_TOKEN+x} ]]; then
	echo "Variable 'GITHUB_TOKEN' not set. Changelog not updated!"
	exit 1
fi
if [[ ! ${TRAVIS_REPO_SLUG+x} ]]; then
	echo "Variable 'TRAVIS_REPO_SLUG' not set. Changelog not updated!"
	exit 1
fi
if [[ ! ${TRAVIS_PULL_REQUEST+x} ]]; then
	echo "Variable 'TRAVIS_PULL_REQUEST' not set. Changelog not updated!"
	exit 1
fi
if [[ ! ${BUILD_VERSION+x} ]]; then
	echo "Variable 'BUILD_VERSION' not set. Changelog not updated!"
	exit 1
fi
