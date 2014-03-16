#!/bin/bash

if [ $# -ne 2 ]; then
  echo 'Usage: '"$0"' SITE YEAR'
  exit
fi

cd dev
./genbbox.pl ../ $1
cd jpg2png
./replace.bash '../../raster/places/'"$1"'/'"$2"'/tiles'