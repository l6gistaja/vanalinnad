#!/usr/bin/perl

use XML::Simple;

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

  @coords = scalar(@ARGV) < 1 
    ? split(/[,\s]/, $conf->{'Document'}{'Placemark'}[$i]{'LineString'}{'coordinates'})
    : split(/[,]/, $ARGV[0]);
  $bboxs = 'BBox='.join(',',@coords).': ';
  $filebase = $cachedir
    .$conf->{'Document'}{'ExtendedData'}{'v:fileprefix'}
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
  if(scalar(@ARGV) > 1) {
      push(@bash, "echo '".$bboxs."Filter OSM with ".$ARGV[1]."'");
      push(@bash, 'osmfilter '
      .$file
      .' --keep="'.$ARGV[1].'" > '
      .$file.'f');
      $osmfile = $file.'f';
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
  push(@bash, $dirosm.'gen_kml.pl '.$i.(scalar(@ARGV) < 1 ? '' : ' '.$ARGV[0]));


}

print DATA $filebase.$conf->{'Document'}{'ExtendedData'}{'v:kmlfooter'};
close(DATA);

foreach $command (@bash) { print "$command\n"; }
