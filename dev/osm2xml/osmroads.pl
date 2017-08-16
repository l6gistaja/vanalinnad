#!/usr/bin/perl

if(scalar(@ARGV) < 2) {
  print "\nUsage: ./dev/osm2xml/osmroads.pl SITE PRECISION [OSMFILTER_KEEP]\n";
  print "\nPRECISION examples: .00001 = 1.1 m of latitude, .000001 = 0.11 m of latitude\n";
  print "\nUse OSMFILTER_KEEP parameter (osmfilter's --keep) if you need only certain objects for some big site.";
  print "\nExample: for Tallinn, load only roads: ./dev/osm2xml/osmroads.pl Tallinn .00001 highway\n\n";
  exit;
}

use XML::Simple;

$xml = new XML::Simple;
$mainconf = $xml->XMLin('conf.xml');
$conf = $xml->XMLin($mainconf->{'dirdev'}.'osm2xml/roads.kml');
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
system($mainconf->{'dirdev'}.'osm2xml/generate_roads.pl '.join(',', @max) .(scalar(@ARGV) > 2 ? ' '.$ARGV[2] : '').' | bash');
print "\a";

for($i=0; $i<=$len; $i++) {
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
    system($mainconf->{'dirdev'}.'kml_minify.pl '.$ARGV[1].' '.$source.' '.$destination);
  }
}

