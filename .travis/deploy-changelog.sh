#!/bin/bash

if [ "$TRAVIS_PULL_REQUEST" != "false" -o "$TRAVIS_BRANCH" != "$CHANGELOG_BRANCH" ]; then
	echo "This commit was made against the $TRAVIS_BRANCH and not $CHANGELOG_BRANCH! Changelog not updated!"
	exit 0
fi

gem install rack -v 1.6.4
gem install github_changelog_generator

rev=$(git rev-parse --short HEAD)

CHANGELOG_EMAIL=${CHANGELOG_EMAIL:='travis@github.com'}

git config user.name "Travis CI"
git config user.email $CHANGELOG_EMAIL

CHANGELOG_BRANCH=${CHANGELOG_BRANCH:='master'}

git remote add upstream "https://$GITHUB_TOKEN@github.com/$TRAVIS_REPO_SLUG.git"
git fetch upstream
git checkout $CHANGELOG_BRANCH

github_changelog_generator

git add -A CHANGELOG.md
git commit -m "updated changelog at ${rev}"
git push upstream $CHANGELOG_BRANCH
