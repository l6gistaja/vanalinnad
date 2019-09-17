#!/usr/bin/perl

use Getopt::Std;

getopt('s:f:b:', \%opts);
if(!exists $opts{'s'} || !exists $opts{'f'}) {
  print <<EndUsage;

Usage: shapeimporter.pl -d SITE -f ... [-b #,#,#,#]

-s : site
-f : XSLT & KML filename without .extension
-b : boundingbox coordinates in format west,south,east,north; if omitted, bounds will be taken from layers.xml

Dependency: xsltproc

Examples:

./dev/shapeimporter.pl -s Narva -f Narva_veehoidla -b 28.125966536810836,59.27797319386188,28.495546659864296,59.35709560445726
./dev/shapeimporter.pl -s Valga -f est-lat -b 25.99093122813302,57.73146806644293,26.13795942547541,57.81354983080887
./dev/shapeimporter.pl -s Valga -f est-lat

EndUsage
  exit;
}

use XML::Simple;
use lib './dev';
use VlHelper qw(get_bbox_from_layers);
$xml = new XML::Simple;
$mainconf = $xml->XMLin($root.'conf.xml');

if(exists $opts{'b'}) {
    @coords = split(/,/, $opts{'b'});
} else {
    $layers = $xml->XMLin($root.$mainconf->{'dirvector'}.$mainconf->{'dirplaces'}.$opts{'s'}.'/'.$mainconf->{'filelayers'});
    @coords = get_bbox_from_layers($layers);
}
print 'BBox '.join(',', @coords)."\n";

$root = './';
$resbase = $root.$mainconf->{'dirvector'}.$mainconf->{'dirplaces'}.$opts{'s'}.'/'.$opts{'f'};
$cache = $root.$mainconf->{'dircache'};

$filebase = $cache.'m_'.$opts{'s'}.'_'.join('_',@coords);

$file = $filebase.'.osm';
if(!(-e $file)) {
  system('wget -O '
    .$file
    .' '
    .'http://overpass-api.de/api/map?bbox='
    .join(',',@coords));
    print 'Wrote to '.$file."\n";
}

$osmfile = $file;
$file = $filebase.'.gml';
if(!(-e $file)) {
  system('xsltproc '.$root.'dev/osm2xml/osm2gml.xslt '
    .$osmfile
    .' > '
    .$file);
  print 'Wrote '.$osmfile.' to '.$file."\n";
}

$gmlfile = $file;
$file = $resbase.'.kml';
system('xsltproc '.$resbase.'.xslt '
    .$gmlfile
    .' > '
    .$file);
system($root.'dev/kml_minify.pl .00001 '.$file.' '.$file);
print 'Wrote to '.$file."\n";
