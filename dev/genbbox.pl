#!/usr/bin/perl

if(scalar(@ARGV) < 2) {
  print "\nUsage: genbbox.pl VANALINNAD_ROOT_DIR SITE_ID\n\n";
  exit;
}

use lib './dev';
use VlHelper qw(bbox_fragment);

use XML::Simple;
$xml = new XML::Simple;
$mainconf = $xml->XMLin($ARGV[0].'conf.xml');
$layers = $xml->XMLin($ARGV[0].$mainconf->{'dirvector'}.$mainconf->{'dirplaces'}.$ARGV[1].'/'.$mainconf->{'filelayers'});
$len = scalar(@{$layers->{'layer'}});
@max = qw(181 91 -181 -91);
for($i=0; $i<=$len; $i++) {
  if($layers->{'layer'}[$i]{'type'} eq 'tms') {

    $year = $layers->{'layer'}[$i]{'year'};
    $filebbox = $ARGV[0].$mainconf->{'dirvector'}.$mainconf->{'dirplaces'}.$ARGV[1].'/bbox'.$year.'.kml';
    print 'BBox & GCP '.$ARGV[1].' '.$year;

    @c = split(/[,\s]/, $layers->{'layer'}[$i]{'bounds'});
    if($c[0] < $max[0]) { $max[0] = $c[0]; }
    if($c[1] < $max[1]) { $max[1] = $c[1]; }
    if($c[2] > $max[2]) { $max[2] = $c[2]; }
    if($c[3] > $max[3]) { $max[3] = $c[3]; }

    if(!(`cat $filebbox | grep sourcedir | wc -l` =~ /^0\s*$/)) {
      print " IGNORED: composite\n";
      next;
    }
    print "\n";
    open (DATA, '>'.$filebbox) or die("Could not open file ".$filebbox);
    binmode DATA, ":utf8";
    print DATA $filebase.$conf->{'Document'}{'ExtendedData'}{'v:kmlheader'};
    print DATA <<EndHeader;
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://earth.google.com/kml/2.2">
<Document>
EndHeader
    
    print DATA bbox_fragment(
      $ARGV[0].$mainconf->{'dirvector'}.$mainconf->{'dirplaces'}.$ARGV[1].'/gdal'.$year.'.txt',
      '', join(',', @c));
    print DATA <<EndHeader;
</Document>
</kml>
EndHeader
    close(DATA);
  }
}

print 'BBox max '.join(',', @max)."\n";