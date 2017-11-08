#!/usr/bin/perl

use XML::Simple;
use Data::Dumper;
use lib './dev';
use VlHelper qw(json_file_read);

if(scalar(@ARGV) < 1) {
  print "\nUsage: dev/newsite/newsite.pl SITE\n\n";
  exit;
}

$root = '';
$site = $ARGV[0];

$xml = new XML::Simple;
$mainconf= $xml->XMLin('conf.xml');
#print Dumper($mainconf);
%localdata = json_file_read($mainconf->{'dircache'}.$mainconf->{'filelocal'});

$dirvector = $root.$mainconf->{'dirvector'}.$mainconf->{'dirplaces'}.$site.'/';
$dirnewsite = $root.$mainconf->{'dirdev'}.'newsite/';
@commands = (
'mkdir -p '.$dirvector,
'cp '.$dirnewsite.$mainconf->{'fileemptytiles'}.' '.$dirvector,
'cp '.$dirnewsite.$mainconf->{'filegdal'}.' '.$dirvector,
'cat '.$dirnewsite.$mainconf->{'filelayers'}.' | sed "s/<city><\/city>/<city>'.$site.'<\/city>/" > '.$dirvector.$mainconf->{'filelayers'},
'mkdir -p '.$root.$mainconf->{'dirraster'}.$mainconf->{'dirplaces'}.$site.'/',
'mkdir -p '.$root.$mainconf->{'dirlegends'}.$mainconf->{'dirplaces'}.$site.'/',
'mkdir -p '.$localdata{'dirsource'}.$site.'/'.$mainconf->{'dircomposite'}
);

foreach $command (@commands) {
  print $command."\n";
  system($command);
}