#!/bin/bash

echo

if [ $# -lt 1 ]; then
  echo 'Usage: '"$0"' /directory/where/one-colored/JPGs/will/be/replaced/with/transparent/PNGs [logfile]'
  echo 'Dependencies: identify (ImageMagick), du, cut, find'
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
      cp none.png $JPG
      replaced=$[$replaced+1]
  fi
done

echo 'Replaced '"$replaced"' files.'
echo