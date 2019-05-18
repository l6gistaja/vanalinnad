#!/bin/bash

rm ~/Downloads/histmaps.tar
cd ~/histmaps/places/
find ./ -name '*.jpg' -type f ! -path '*/composed/*/*/*/*/*' | tar -cf ~/Downloads/histmaps.tar -T -
