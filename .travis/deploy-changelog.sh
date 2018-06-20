#!/bin/bash

check-vars() {
	[[ ! ${CHANGELOG_USER_NAME+x} ]]  && { echo "Variable 'CHANGELOG_USER_NAME' not set. Changelog not updated!";  exit 1; }
	[[ ! ${CHANGELOG_USER_EMAIL+x} ]] && { echo "Variable 'CHANGELOG_USER_EMAIL' not set. Changelog not updated!"; exit 1; }
	[[ ! ${GITHUB_TOKEN+x} ]]         && { echo "Variable 'GITHUB_TOKEN' not set. Changelog not updated!";         exit 1; }
	[[ ! ${TRAVIS_REPO_SLUG+x} ]]     && { echo "Variable 'TRAVIS_REPO_SLUG' not set. Changelog not updated!";     exit 1; }
	[[ ! ${TRAVIS_PULL_REQUEST+x} ]]  && { echo "Variable 'TRAVIS_PULL_REQUEST' not set. Changelog not updated!";  exit 1; }
}

install-changelog-generator() {
	gem install rack -v 1.6.4
	gem install github_changelog_generator
}

setup-git() {
    git config --global user.email $CHANGELOG_USER_EMAIL
    git config --global user.name $CHANGELOG_USER_NAME
    git config --global push.default matching
    git config credential.helper "store --file=.git/credentials"
    echo "https://${GITHUB_TOKEN}:@github.com" > .git/credentials
}

create-and-push-changelog() {
	rev=$(git rev-parse --short HEAD)

	git remote add upstream "https://$GITHUB_TOKEN@github.com/$TRAVIS_REPO_SLUG.git"
	git fetch upstream
	git checkout $TRAVIS_BRANCH
}

deploy-changelog() {
	if [[ "$TRAVIS_PULL_REQUEST" != "false" || "$TRAVIS_BRANCH" == "$TRAVIS_TAG" ]]; then
		echo "The build was triggered by a 'Pull Request' or it is a tag'ed build! Changelog not updated!"
		exit 0
	fi
	install-changelog-generator
	setup-git
	create-and-push-changelog
}

check-vars
