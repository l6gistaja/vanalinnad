#!/bin/bash

dev/osm2xml/allosmroads.pl
echo "Regenerate other vector files..."
dev/kml2vlgjson.pl 5 vector/places/Tallinn/baltic_mini.kml vector/places/Tallinn/baltic_mini.json
dev/kml2vlgjson.pl 5 vector/places/Narva/Narva_veehoidla.kml vector/places/Narva/Narva_veehoidla.json
dev/kml2vlgjson.pl 5 vector/places/Parnu/baltic.kml vector/places/Parnu/baltic.json
dev/shapeimporter.pl -s Valga -f est-lat
dev/kml2vlgjson.pl 5 vector/places/Valga/est-lat.kml vector/places/Valga/est-lat.json
dev/kml2vlgjson.pl 5 vector/common/rdt.kml vector/common/rdt.json
