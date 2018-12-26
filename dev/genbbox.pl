#!/usr/bin/perl

if(scalar(@ARGV) < 2) {
  print "\nUsage: genbbox.pl VANALINNAD_ROOT_DIR SITE_ID\n\n";
  exit;
}

use File::Basename;
use lib dirname(__FILE__);
use VlHelper qw(bbox_fragment kml_envelope gdal_mapindex gdal_tlast bbox_box bbox_points);
use XML::Simple;
use Data::Dumper;

$gdaltxtformat = 0;

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

    if($gdaltxtformat) {
      $bboxdata = print bbox_fragment(
        $ARGV[0].$mainconf->{'dirvector'}.$mainconf->{'dirplaces'}.$ARGV[1].'/gdal'.$year.'.txt',
        '', join(',', @c)
      );
    } else {
      $gdal = $xml->XMLin($ARGV[0].$mainconf->{'dirvector'}.$mainconf->{'dirplaces'}.$ARGV[1].'/'.$mainconf->{'filegdal'}, ForceArray => 1);
      %gx = qw();
      $gx{'y'} = gdal_mapindex($gdal, $year);
      $gx{'tlast'} = gdal_tlast($gdal, $gx{'y'});
      $bboxdata = bbox_box('', join(',', @c)).bbox_points($gdal->{'translate'}[$gx{'y'}]{'t'}[$gx{'tlast'}]{'gcps'}, '');
    }
    open (DATA, '>'.$filebbox) or die("Could not open file ".$filebbox);
    binmode DATA, ":utf8";
    print DATA kml_envelope($bboxdata);
    close(DATA);
  }
}

print 'BBox max '.join(',', @max)."\n";
