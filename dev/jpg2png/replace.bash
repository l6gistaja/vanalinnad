#!/bin/bash

echo

if [ $# -lt 1 ]; then
  echo 'Usage: '"$0"' /directory/where/one-colored/JPGs/will/be/deleted [logfile]'
  echo 'Dependencies: identify (ImageMagick), find'
  echo
  exit
fi

replaced=0

for JPG in $(find $1 -name *.jpg)
do
  colorcount=$(identify -format %k $JPG)
  if [ $colorcount -eq 1 ]; then
      if [ $# -gt 1 ]; then
        echo $JPG >> $2
      fi
      rm $JPG
      replaced=$[$replaced+1]
  fi
done

echo 'Removed '"$replaced"' files.'
echo