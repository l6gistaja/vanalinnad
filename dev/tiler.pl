#!/usr/bin/perl

use XML::Simple;
use Getopt::Std;
use Data::Dumper;
use lib './dev';
use VlHelper qw(gdal_mapindex gdal_tlast);

getopt('s:y:', \%opts);
if(!exists $opts{'s'} || !exists $opts{'y'}) {
  print "\nUsage: dev/tiler.pl -s SITE -y MAPYEAR\n\n";
  exit;
}

%c = qw();
$xml = new XML::Simple;
$c{'dirvector'} = 'vector/places/'.$opts{'s'}.'/';
$c{'filegdal'} = $c{'dirvector'}.'gdal.xml';
$gdal = $xml->XMLin($c{'filegdal'}, ForceArray => 1);
#print Dumper($gdal);

$c{'y'} = gdal_mapindex($gdal, $opts{'y'});

if($c{'y'} < 0) {
  print "\nNo map '".$opts{'y'}."' in ".$c{'filegdal'}."\n\n";
  exit;
}

$c{'tlast'} = gdal_tlast($gdal, $c{'y'});
$c{'dirsrcimg'} = '/home/jux/histmaps/places/'.$opts{'s'}.'/';
$c{'filesrcimg'} = $c{'dirsrcimg'}.$gdal->{'translate'}[$c{'y'}]{'t'}[$c{'tlast'}]{'file'};
$c{'filegeoref'} = $c{'filesrcimg'}.'_georef.png';
$c{'dirraster'} = 'raster/places/'.$opts{'s'}.'/'.$opts{'y'};
$c{'filelayers'} = $c{'dirvector'}.'layers.xml';

$layers = $xml->XMLin($c{'filelayers'}, ForceArray => 1);

$cmd = 'gdal_translate '.$c{'filesrcimg'}.' '.$c{'filegeoref'}.' -of PNG '.$gdal->{'translate'}[$c{'y'}]{'t'}[$c{'tlast'}]{'gcps'};
sheller($cmd);

$cmd = 'rm -rf '.$c{'dirraster'};
sheller($cmd);

$cmd = 'dev/gdal2tiles.py --profile mercator --s_srs \'GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563,AUTHORITY["EPSG","7030"]],AUTHORITY["EPSG","6326"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.01745329251994328,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4326"]]\' --zoom '.$layers->{'minzoom'}[0].'-'.$layers->{'maxzoom'}[0].' --title \''.$opts{'s'}.' '.$opts{'y'}.'\' --tile-format jpeg --webviewer all '.$c{'filegeoref'}.' '.$c{'dirraster'};
sheller($cmd);

$tilemapres = $xml->XMLin($c{'dirraster'}.'/tilemapresource.xml', ForceArray => 1);
# OpenLayers bounds are in order W,S,E,N
$c{'bbox'} = $tilemapres->{'BoundingBox'}[0]{'miny'}.','.$tilemapres->{'BoundingBox'}[0]{'minx'}.','.$tilemapres->{'BoundingBox'}[0]{'maxy'}.','.$tilemapres->{'BoundingBox'}[0]{'maxx'};
$c{'ls'} = scalar(@{$layers->{'layer'}});
$isNewLayer = 1;
for($i = 0; $i < $c{'ls'}; $i++) {
  if($layers->{'layer'}[$i]{'type'} eq 'tms' && $layers->{'layer'}[$i]{'year'} eq $opts{'y'}) {
    $layers->{'layer'}[$i]{'bounds'} = $c{'bbox'};
    $isNewLayer = 0;
    break;
  }
}
if($isNewLayer) {
  push(@{$layers->{'layer'}}, {'type' => 'tms', 'bounds' => $c{'bbox'}, 'year' => $opts{'y'}});
}

print $xml->XMLout($layers, RootName => 'vanalinnadlayers', OutputFile => $c{'filelayers'});

$cmd = 'dev/postproc.bash '.$opts{'s'}.' '.$opts{'y'};
sheller($cmd);

$cmd = $c{'dirvector'}.'rss'.$opts{'y'}.'.xml';
if(! -e $cmd) {
  $cmd = 'cp vector/rsstemplate.xml '.$cmd;
  sheller($cmd);
}

sub sheller {
 print $_[0]."\n";
 system($_[0]);
}