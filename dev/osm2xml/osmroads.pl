#!/usr/bin/perl

if(scalar(@ARGV) < 1) {
  print "\nUsage: osmroads.pl SITE\n\n";
  exit;
}

use XML::Simple;

$xml = new XML::Simple;
$mainconf = $xml->XMLin('conf.xml');
$layers = $xml->XMLin($mainconf->{'dirvector'}.$mainconf->{'dirplaces'}.$ARGV[0].'/'.$mainconf->{'filelayers'});
$len = scalar(@{$layers->{'layer'}});
@max = qw(181 91 -181 -91);
for($i=0; $i<=$len; $i++) {
  if($layers->{'layer'}[$i]{'type'} eq 'tms') {
    @c = split(/[,\s]/, $layers->{'layer'}[$i]{'bounds'});
    if($c[0] < $max[0]) { $max[0] = $c[0]; }
    if($c[1] < $max[1]) { $max[1] = $c[1]; }
    if($c[2] > $max[2]) { $max[2] = $c[2]; }
    if($c[3] > $max[3]) { $max[3] = $c[3]; }
  }
}

print 'BBox max '.join(',', @max)."\n";
system($mainconf->{'dirdev'}.'osm2xml/generate_roads.pl '.join(',', @max) .' | bash');
