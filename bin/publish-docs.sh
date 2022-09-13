#!/bin/bash
set -e

REPO_NAME=$1
NAMESPACE=$2
PAGES_DIR=./gh-pages
DOCS_DIR=./out
if [[ -n "${GITHUB_TOKEN}" ]]; then # If the GITHUB_TOKEN (which is an app token) is not empty we use an app token auth URL
  REPO="https://x-access-token:${GITHUB_TOKEN}@github.com/contentful/${REPO_NAME}.git"
else # Legacy variant
  REPO="https://${GH_TOKEN}@github.com/contentful/${REPO_NAME}.git"
fi


VERSION=`cat package.json|json version`

echo "Publishing docs"

if ! [ -d $DOCS_DIR ] ; then
  echo "Docs can't be found. Maybe you haven't generated them?"
  exit 1
fi

# get the gh-pages branch of the repo
if [ ! -d $PAGES_DIR ] ; then
  git clone --single-branch --branch gh-pages $REPO $PAGES_DIR
fi

if ! [ -d $PAGES_DIR/$NAMESPACE/$VERSION ] ; then
  mkdir $PAGES_DIR/$NAMESPACE/$VERSION
fi
cp -r $DOCS_DIR/* $PAGES_DIR/$NAMESPACE/$VERSION

rm -rf $PAGES_DIR/$NAMESPACE/latest

cp -r $PAGES_DIR/$NAMESPACE/$VERSION $PAGES_DIR/$NAMESPACE/latest

echo "<meta http-equiv=\"refresh\" content=\"0; url=https://contentful.github.io/${REPO_NAME}/${NAMESPACE}/${VERSION}/\">" > $PAGES_DIR/index.html

pushd $PAGES_DIR
git add .
git commit -a -m "Docs update for $VERSION [skip ci]"
if [ $? -eq 1 ] ; then
  echo "Nothing to update"
else
  git push origin gh-pages
fi
popd
