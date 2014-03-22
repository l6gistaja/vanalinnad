#!/bin/bash

if [ $# -ne 2 ]; then
  echo 'Usage: '"$0"' SITE YEAR'
  exit
fi

dev/readme/md2html.bash
cd dev
./genbbox.pl ../ $1
cd jpg2png
./replace.bash '../../raster/places/'"$1"'/'"$2"'/tiles'