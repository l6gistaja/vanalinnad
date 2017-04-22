#!/usr/bin/perl

if(scalar(@ARGV) < 1) {
  print "\nUsage: osmroads.pl SITE [OSMFILTER_KEEP]\n";
  print "\nUse OSMFILTER_KEEP parameter (osmfilter's --keep) if you need only certain objects for some big site.";
  print "\nExample: for Tallinn, load only roads: osmroads.pl Tallinn highway\n\n";
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

if(exists $layers->{'roadbounds'}) {
    if(exists $layers->{'roadbounds'}{'n'} && $max[3] > $layers->{'roadbounds'}{'n'}) {$max[3] = $layers->{'roadbounds'}{'n'};}
    if(exists $layers->{'roadbounds'}{'e'} && $max[2] > $layers->{'roadbounds'}{'e'}) {$max[2] = $layers->{'roadbounds'}{'e'};}
    if(exists $layers->{'roadbounds'}{'s'} && $max[1] < $layers->{'roadbounds'}{'s'}) {$max[1] = $layers->{'roadbounds'}{'s'};}
    if(exists $layers->{'roadbounds'}{'w'} && $max[0] < $layers->{'roadbounds'}{'w'}) {$max[0] = $layers->{'roadbounds'}{'w'};}
}

print 'BBox max '.join(',', @max)."\n";
system($mainconf->{'dirdev'}.'osm2xml/generate_roads.pl '.join(',', @max) .(scalar(@ARGV) > 1 ? ' '.$ARGV[1] : '').' | bash');
print "\a";
