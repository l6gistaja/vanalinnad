#!/bin/bash

if [ $# -ne 2 ]; then
  echo 'Usage: '"$0"' SITE YEAR'
  exit
fi

dev/readme/md2html.bash
cd dev
./genbbox.pl ../ $1

VECTORDIR='../vector/places/'"$1"
TILEDIR='../raster/places/'"$1"'/'"$2"

if [ `grep sourcedir "$VECTORDIR"'/bbox'"$2"'.kml' | wc -l` -ne '0' ]; then
  echo 'COMPOSITE MAP '"$1"' '"$2"': will not search for empty tiles'
  exit
fi

MINLOCK="$TILEDIR"'/minified.txt'
if [ -f $MINLOCK ]; then
  echo 'MAP '"$1"' '"$2"' ALREADY MINIFIED'
  exit
fi
echo `date --rfc-3339=seconds`'; '`find $TILEDIR -type f | wc -l`' files; '`du -h --max-depth=0 $TILEDIR` > $MINLOCK

cd jpg2png
EMPTYTILES='../../cache/empty'"$1"''"$2"'.txt'
rm $EMPTYTILES
touch $EMPTYTILES
echo "Searching empty tiles..."
./replace.bash '../'"$TILEDIR" $EMPTYTILES
./emptyjson.pl $EMPTYTILES '../'"$VECTORDIR"'/empty.json'

cd ..
echo `date --rfc-3339=seconds`'; '`find $TILEDIR -type f | wc -l`' files; '`du -h --max-depth=0 $TILEDIR` >> $MINLOCK
echo 'FINISHED'
date