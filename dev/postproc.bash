#!/bin/bash

if [ $# -ne 2 ]; then
  echo 'Usage: '"$0"' SITE YEAR'
  exit
fi

dev/readme/md2html.bash
cd dev
./genbbox.pl ../ $1
cd jpg2png
EMPTYTILES='../../cache/empty'"$1"''"$2"'.txt'
rm $EMPTYTILES
touch $EMPTYTILES
echo "Searching empty tiles..."
./replace.bash '../../raster/places/'"$1"'/'"$2"'/tiles' $EMPTYTILES
./emptyjson.pl $EMPTYTILES '../../vector/places/'"$1"'/empty.json'
echo 'FINISHED'
date