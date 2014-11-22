#!/usr/bin/perl

if(scalar(@ARGV) < 1) {
  print "\nUsage: dev/xmlgdal.pl SITE\n\n";
  exit;
}

use Data::Dumper;
use XML::Simple;

$rootdir = '';
$site = $ARGV[0];
$xml = new XML::Simple;
$mainconf = $xml->XMLin($rootdir.'conf.xml');
$gdaldir = $rootdir.$mainconf->{'dirvector'}.$mainconf->{'dirplaces'}.$site.'/';
#print Dumper($bboxdata);
$vdir = $mainconf->{'dirvector'}.$mainconf->{'dirplaces'}.$site.'/';
$layers = $xml->XMLin($vdir.$mainconf->{'filelayers'}, ForceArray => 1);
%xml = qw();
$xml{'xmlns'} = 'http://juks.alkohol.ee/vanalinnad';
$xml{'composite'} = qw();

$xmls = '';


$ls = scalar(@{$layers->{'layer'}});
for($i = 0; $i < $ls; $i++) {
  if($layers->{'layer'}[$i]{'type'} eq 'tms') {
    $compositebbox = $xml->XMLin($vdir.'bbox'.$layers->{'layer'}[$i]{'year'}.'.kml', ForceArray => 1);
    if(exists $compositebbox->{'Document'}[0]{'ExtendedData'}) {
      $xmls .= '<composite id="'.$layers->{'layer'}[$i]{'year'}.'" maps="'.$compositebbox->{'Document'}[0]{'ExtendedData'}[0]{'Data'}{'maps'}{'value'}[0].'"';
      if(exists $compositebbox->{'Document'}[0]{'ExtendedData'}[0]{'Data'}{'montage'}) {
        $xmls .= " montage=\"yes\"";
      }
      $xmls .= "/>\n";
    }
  }
}

print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<vanalinnadgdal xmlns=\"http://juks.alkohol.ee/vanalinnad\">\n".$xmls."</vanalinnadgdal>";

