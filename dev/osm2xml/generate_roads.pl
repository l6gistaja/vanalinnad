#!/usr/bin/perl

use XML::Simple;

$xml = new XML::Simple;
$conf = $xml->XMLin('roads.kml');
$mainconf = $xml->XMLin($conf->{'Document'}{'ExtendedData'}{'v:dirbase'}.'conf.xml');
$len = scalar(@{$conf->{'Document'}{'Placemark'}});
@bash = qw();
$cachedir = $conf->{'Document'}{'ExtendedData'}{'v:dirbase'}
    .$mainconf->{'dircache'};
push(@bash, "echo 'Generating road networks'");
push(@bash, "echo 'Cache at: ".$cachedir."'");
push(@bash, "echo 'Coordinates order: W,S,E,N'");

$file = $conf->{'Document'}{'ExtendedData'}{'v:dirbase'}
  .$mainconf->{'dircache'}
  .$conf->{'Document'}{'ExtendedData'}{'v:areasfile'};
open (DATA, '>'.$file);
binmode DATA, ":utf8";
print DATA $filebase.$conf->{'Document'}{'ExtendedData'}{'v:kmlheader'};

for($i=0; $i<$len-1; $i++) {

  @coords = split(/[,\s]/,$conf->{'Document'}{'Placemark'}[$i]{'LineString'}{'coordinates'});
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

  $file = $filebase.$conf->{'Document'}{'ExtendedData'}{'v:filextosm'};
  push(@bash, "echo '".$bboxs."Fetch OSM'");
  if(!(-e $file)) {
    push(@bash, 'wget -O '
      .$file
      .' '
      .$conf->{'Document'}{'ExtendedData'}{'v:osmexporturl'}
      .join(',',@coords));
  }
  
  $osmfile = $file;
  $file = $filebase.$conf->{'Document'}{'ExtendedData'}{'v:filextgml'};
  push(@bash, "echo '".$bboxs."Convert OSM 2 GML'");
  if(!(-e $file)) {
    push(@bash, 'xsltproc osm2gml.xslt '
      .$osmfile
      .' > '
      .$file);
  }

  $gmlfile = $file;
  $file = $filebase.$conf->{'Document'}{'ExtendedData'}{'v:filextxml'};
  push(@bash, "echo '".$bboxs."Convert GML 2 XML'");
  if(!(-e $file)) {
    push(@bash, 'xsltproc xml_mini.xslt '
      .$gmlfile
      .' > '
      .$file);
  }
  
  push(@bash, "echo '".$bboxs."Convert XML 2 KML'");
  push(@bash, './gen_kml.pl '.$i);

  if(0) {
  push(@bash, "echo '".$bboxs."Copy KMLs'");
  @layers = split(/,/,$conf->{'Document'}{'Placemark'}[$i]{'ExtendedData'}{'v:copylayers'});
  foreach $level (@layers) {
    push(@bash, "mv "
      .$conf->{'Document'}{'ExtendedData'}{'v:dirbase'}
      .$mainconf->{'dircache'}
      .$mainconf->{'fileprefixroads'}
      .$level
      .$conf->{'Document'}{'ExtendedData'}{'v:filextkml'}
      .' '
      .$conf->{'Document'}{'ExtendedData'}{'v:dirbase'}
      .$mainconf->{'dirvector'});
  }
  }

}

print DATA $filebase.$conf->{'Document'}{'ExtendedData'}{'v:kmlfooter'};
close(DATA);

foreach $command (@bash) { print "$command\n"; }
