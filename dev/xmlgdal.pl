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
$xmls = '';

$ls = scalar(@{$layers->{'layer'}});
for($i = 0; $i < $ls; $i++) {
  if($layers->{'layer'}[$i]{'type'} eq 'tms') {
    $compositebbox = $xml->XMLin($vdir.'bbox'.$layers->{'layer'}[$i]{'year'}.'.kml', ForceArray => 1);
    if(exists $compositebbox->{'Document'}[0]{'ExtendedData'}) {
      $xmls .= "\n<composite id=\"".$layers->{'layer'}[$i]{'year'}.'" maps="'.$compositebbox->{'Document'}[0]{'ExtendedData'}[0]{'Data'}{'maps'}{'value'}[0].'"';
      if(exists $compositebbox->{'Document'}[0]{'ExtendedData'}[0]{'Data'}{'montage'}) {
        $xmls .= " montage=\"yes\"";
      }
      $xmls .= "/>\n";
      foreach $map (split(/,/, $compositebbox->{'Document'}[0]{'ExtendedData'}[0]{'Data'}{'maps'}{'value'}[0])) {
        $xmls .= txtfile2xml($vdir.'gdal'.$map.'.txt', $map, $layers->{'layer'}[$i]{'year'});
      }
    } else {
      $xmls .= txtfile2xml($vdir.'gdal'.$layers->{'layer'}[$i]{'year'}.'.txt', $layers->{'layer'}[$i]{'year'}, '');
    }
  }
}

print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<vanalinnadgdal xmlns=\"http://juks.alkohol.ee/vanalinnad\">\n".$xmls."\n</vanalinnadgdal>";

sub txtfile2xml {
  open(INFO, $_[0]) or return "\n<!-- Could not open file ".$_[0]." -->\n";
  $y = "\n<translate map=\"".$_[1].'"'.($_[2] ne '' ? ' composite="'.$_[2].'"' : '').'>';
  foreach $line (<INFO>) { if($line =~ /gdal_translate/) {
    $line =~ s/^\s+//;
    @cl = split(/\s+/, $line);
    @sf = split(/\//, $cl[1]);
    $y .= "\n    <t file=\"".$sf[scalar(@sf)-1]."\"";
    $al = scalar(@cl);
    @gcps = qw();
    for($ii = 0; $ii < $al; $ii++) {
      if($cl[$ii] eq '-gcp') {
        for($j = 0; $j < 5; $j++) {
          push(@gcps, $cl[$ii+$j]);
        }
      }
    }
    $y .= ' gcps="'.join(' ', @gcps)."\"/>";
  } }
  close(INFO);
  return $y."\n</translate>\n";
}