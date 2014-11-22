#!/usr/bin/perl

use XML::Simple;
use Data::Dumper;

if(scalar(@ARGV) < 1) {
  print "\nUsage: dev/newsite/newsite.pl SITE\n\n";
  exit;
}

$root = '';
$site = $ARGV[0];

$xml = new XML::Simple;
$mainconf= $xml->XMLin('conf.xml');
#print Dumper($mainconf);

$dirvector = $root.$mainconf->{'dirvector'}.$mainconf->{'dirplaces'}.$site.'/';
$dirnewsite = $root.$mainconf->{'dirdev'}.'newsite/';
@commands = (
'mkdir -p '.$dirvector,
'cp '.$dirnewsite.'empty.json '.$dirvector,
'cp '.$dirnewsite.'gdal.xml '.$dirvector,
'cat '.$dirnewsite.'layers.xml | sed "s/<city><\/city>/<city>'.$site.'<\/city>/" > '.$dirvector.'layers.xml',
'mkdir -p '.$root.$mainconf->{'dirraster'}.$mainconf->{'dirplaces'}.$site.'/',
'mkdir -p '.$root.$mainconf->{'dirlegends'}.$mainconf->{'dirplaces'}.$site.'/',
'mkdir -p '.$mainconf->{'dirsource'}.$site.'/'.$mainconf->{'dircomposite'}
);

foreach $command (@commands) {
  print $command."\n";
  system($command);
}