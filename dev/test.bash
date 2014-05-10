#!/bin/bash

if [ `grep sourcedir 'vector/places/'"$1"'/bbox'"$2"'.kml' | wc -l` -ne '0' ]; then
  echo 'FFFFFFFFFFFFFFFFFFFFFFFFFFF'
  exit
fi