#!/bin/bash

if [ $# -ne 1 ]; then
  echo
  echo 'Usage: '"$0"' "GIT_COMMIT_MESSAGE"'
  echo
  echo 'Current Git status:'
  git status
  exit
fi

dev/listmaps.pl
git add *
git commit -m "$1"
dev/uploader.pl
