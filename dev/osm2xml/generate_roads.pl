#!/usr/bin/perl

use XML::Simple;
use Getopt::Std;

getopt('b:f:s:h', \%opts);
if(exists $opts{'h'}) {
  print "\nUsage: dev/osm2xml/generate_roads.pl -b W,S,E,N (-f FILTERWORD) (-s SITE)\n\n";
  exit;
}

$xml = new XML::Simple;
$dirbase = '';
$mainconf = $xml->XMLin($dirbase.'conf.xml');
$dirosm = $dirbase.$mainconf->{'dirdev'}.'osm2xml/';
$conf = $xml->XMLin($dirosm.'roads.kml');
$len = scalar(@{$conf->{'Document'}{'Placemark'}});
@bash = qw();
$cachedir = $dirbase.$mainconf->{'dircache'};
push(@bash, "echo 'Generating road networks'");
push(@bash, "echo 'Cache at: ".$cachedir."'");
push(@bash, "echo 'Coordinates order: W,S,E,N'");

$file = $dirbase
  .$mainconf->{'dircache'}
  .$conf->{'Document'}{'ExtendedData'}{'v:areasfile'};
open (DATA, '>'.$file);
binmode DATA, ":utf8";
print DATA $filebase.$conf->{'Document'}{'ExtendedData'}{'v:kmlheader'};

for($i=0; $i<$len-1; $i++) {

  @coords = !exists $opts{'b'} 
    ? split(/[,\s]/, $conf->{'Document'}{'Placemark'}[$i]{'LineString'}{'coordinates'})
    : split(/[,]/, $opts{'b'});
  $bboxs = 'BBox='.join(',',@coords).': ';
  $filebase = $cachedir
    .$conf->{'Document'}{'ExtendedData'}{'v:fileprefix'}
    .'_'.(exists $opts{'s'}  ? $opts{'s'} : 'NOSITE').'_'
    .join('_',@coords);

  print DATA '<Placemark><name>'
    .$conf->{'Document'}{'Placemark'}[$i]{'name'}
    .'</name><Polygon><outerBoundaryIs><LinearRing><coordinates>'
    .$coords[0].', '.$coords[1].', 0. '
    .$coords[0].', '.$coords[3].', 0. '
    .$coords[2].', '.$coords[3].', 0. '
    .$coords[2].', '.$coords[1].', 0. '
    ."</coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark>\n";

  $file = $filebase.'.osm';
  push(@bash, "echo '".$bboxs."Fetch OSM'");
  if(!(-e $file)) {
    push(@bash, 'wget -O '
      .$file
      .' '
      .$conf->{'Document'}{'ExtendedData'}{'v:osmexporturl'}
      .join(',',@coords));
  }
  
  $osmfile = $file;
  if(exists $opts{'f'}) {
      push(@bash, "echo '".$bboxs."Filter OSM with ".$opts{'f'}."'");
      $filterfile = $filebase.'_filtered.osm';
      if(!(-e $filterfile)) {
	  push(@bash, 'osmfilter '
	  .$file
	  .' --keep="'.$opts{'f'}.'" > '
	  .$filterfile);
      }
      $osmfile = $filterfile;
  }
  
  $file = $filebase.'.gml';
  push(@bash, "echo '".$bboxs."Convert OSM 2 GML'");
  if(!(-e $file)) {
    push(@bash, 'xsltproc '.$dirosm.'osm2gml.xslt '
      .$osmfile
      .' > '
      .$file);
  }

  $gmlfile = $file;
  $file = $filebase.'.xml';
  push(@bash, "echo '".$bboxs."Convert GML 2 XML'");
  if(!(-e $file)) {
    push(@bash, 'xsltproc '.$dirosm.'xml_mini.xslt '
      .$gmlfile
      .' > '
      .$file);
  }
  
  push(@bash, "echo '".$bboxs."Convert XML 2 KML'");
  push(@bash, $dirosm.'gen_kml.pl -b '.$opts{'b'}.' -s '.$opts{'s'});


}

print DATA $filebase.$conf->{'Document'}{'ExtendedData'}{'v:kmlfooter'};
close(DATA);

foreach $command (@bash) { print "$command\n"; }
