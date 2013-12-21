#!/bin/bash

echo

if [ $# -ne 1 ]; then
  echo 'Usage: '"$0"' /directory/where/one-colored/JPGs/will/be/replaced/with/transparent/PNGs'
  echo 'Dependencies: identify (ImageMagick), du, cut, find'
  echo
  exit
fi

replaced=0

for JPG in $(find $1 -name *.jpg)
do
  colorcount=$(identify -format %k $JPG)
  if [ $colorcount -eq 1 ]; then
      actualsize=$(du -b "$JPG" | cut -f 1)
      if [ -e "$actualsize".png ]; then
        rm $JPG
        cp "$actualsize"'.png' $JPG
        replaced=$[$replaced+1]
      else
        echo 'Cant find '"$actualsize"'.png for replacing '"$JPG"
      fi
  fi
done

echo 'Replaced '"$replaced"' files.'
echo