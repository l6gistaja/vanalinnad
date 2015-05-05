#!/usr/bin/perl

use Getopt::Std;

getopt('d:f:b:', \%opts);
if(!exists $opts{'d'} || !exists $opts{'f'} || !exists $opts{'b'}) {
  print <<EndUsage;

Usage: shapeimporter.pl -d .../ -f ... -b #,#,#,#

-d : directory/
-f : XSLT & KML filename without .extension
-b : boundingbox coordinates in format west,south,east,north

Dependency: xsltproc

Examples:

./dev/shapeimporter.pl -d vector/places/Narva/ -f Narva_veehoidla -b 28.125966536810836,59.27797319386188,28.495546659864296,59.35709560445726
./dev/shapeimporter.pl -d vector/places/Valga/ -f est-lat -b 25.99093122813302,57.73146806644293,26.13795942547541,57.81354983080887

EndUsage
  exit;
}

@coords = split(/,/, $opts{'b'});

$root = './';
$resbase = $root.$opts{'d'}.$opts{'f'};
$cache = $root.'cache/';

$filebase = $cache.'m'.join('_',@coords);

$file = $filebase.'.osm';
if(!(-e $file)) {
  system('wget -O '
    .$file
    .' '
    .'http://overpass-api.de/api/map?bbox='
    .join(',',@coords));
}

$osmfile = $file;
$file = $filebase.'.gml';
if(!(-e $file)) {
  system('xsltproc '.$root.'dev/osm2xml/osm2gml.xslt '
    .$osmfile
    .' > '
    .$file);
}

$gmlfile = $file;
$file = $resbase.'.kml';
system('xsltproc '.$resbase.'.xslt '
    .$gmlfile
    .' > '
    .$file);

system($root.'dev/kml_minify.pl .00001 '.$file.' '.$file);