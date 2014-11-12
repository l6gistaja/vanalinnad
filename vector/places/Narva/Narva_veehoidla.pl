#!/usr/bin/perl

#@coords = (27.98978932801672,59.23752273984506,28.495546659864296,59.35709560445726);
@coords = (28.125966536810836,59.27797319386188,28.495546659864296,59.35709560445726);

$root = $root.'../../../';
$resbase = $root.'vector/places/Narva/Narva_veehoidla';
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


