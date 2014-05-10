#!/bin/bash

if [ $# -ne 2 ]; then
  echo 'Usage: '"$0"' SITE YEAR'
  exit
fi

dev/readme/md2html.bash
cd dev
./genbbox.pl ../ $1

if [ `grep sourcedir '../vector/places/'"$1"'/bbox'"$2"'.kml' | wc -l` -ne '0' ]; then
  echo 'COMPOSITE MAP '"$1"' '"$2"': will not search for empty tiles'
  exit
fi

cd jpg2png
EMPTYTILES='../../cache/empty'"$1"''"$2"'.txt'
rm $EMPTYTILES
touch $EMPTYTILES
echo "Searching empty tiles..."
./replace.bash '../../raster/places/'"$1"'/'"$2"'' $EMPTYTILES
./emptyjson.pl $EMPTYTILES '../../vector/places/'"$1"'/empty.json'
echo 'FINISHED'
date