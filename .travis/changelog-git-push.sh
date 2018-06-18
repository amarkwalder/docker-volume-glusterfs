#!/bin/bash

setup_git() {
    git config --global user.email "andre.markwalder@gmail.com"
    git config --global user.name "amarkwalder"
    git config --global push.default matching
    git config credential.helper "store --file=.git/credentials"
    echo "https://${GITHUB_TOKEN}:@github.com" > .git/credentials
}

make_version() {
    git checkout -- .
    git status
    git add CHANGELOG.md
    git commit -m "Generate CHANGELOG.md [skip ci]"
    git push
}

upload_files() {
    git push origin HEAD:$TRAVIS_BRANCH
    git push --tags
}

changelog-git-push() {
    setup_git
    make_version
    upload_files
}
