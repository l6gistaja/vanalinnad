#!/usr/bin/perl

if(scalar(@ARGV) < 2) {
  print "\nUsage: ./dev/osm2xml/osmroads.pl SITE PRECISION [OSMFILTER_KEEP]\n";
  print "\nPRECISION examples: 5 = 1.1 m of latitude, 6 = 0.11 m of latitude\n";
  print "\nUse OSMFILTER_KEEP parameter (osmfilter's --keep) if you need only certain objects for some big site.";
  print "\nExample: for Tallinn, load only roads: ./dev/osm2xml/osmroads.pl Tallinn 5 highway\n\n";
  exit;
}

use XML::Simple;
use lib './dev';
use VlHelper qw(get_bbox_from_layers);

$xml = new XML::Simple;
$mainconf = $xml->XMLin('conf.xml');
$conf = $xml->XMLin($mainconf->{'dirdev'}.'osm2xml/roads.kml');
$layers = $xml->XMLin($mainconf->{'dirvector'}.$mainconf->{'dirplaces'}.$ARGV[0].'/'.$mainconf->{'filelayers'});
@max = get_bbox_from_layers($layers);
print 'BBox max '.join(',', @max)."\n";
system($mainconf->{'dirdev'}.'osm2xml/generate_roads.pl -b '.join(',', @max).' -s '.$ARGV[0].(scalar(@ARGV) > 2 ? ' -f '.$ARGV[2] : '').' | bash');
print "\a";

for($i = 0; $i < scalar(@{$layers->{'layer'}}) - 1; $i++) {
  if($layers->{'layer'}[$i]{'type'} eq 'roads') {
    @l = split(/,/, $layers->{'layer'}[$i]{'levels'});
    $source = $mainconf->{'dircache'}.$mainconf->{'fileprefixroads'}.join('',@l).'.kml';
    $destination = $mainconf->{'dirvector'}.$mainconf->{'dirplaces'}.$ARGV[0].'/'.$layers->{'layer'}[$i]{'file'};
    print "Generating $destination\n";
    system("echo '".$conf->{'Document'}{'ExtendedData'}{'v:kmlheader'}."' > ".$source);
    foreach $level (@l) {
	system("cat ".$mainconf->{'dircache'}.$mainconf->{'fileprefixroads'}.$level.".txt >> ".$source);
    }
    system("echo '".$conf->{'Document'}{'ExtendedData'}{'v:kmlfooter'}."' >> ".$source);
    system($mainconf->{'dirdev'}.'kml2vlgjson.pl '.$ARGV[1].' '.$source.' '.$destination);
  }
}

