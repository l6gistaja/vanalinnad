#!/usr/bin/perl

if(scalar(@ARGV) < 2) {
  print "\nUsage: genbbox.pl VANALINNAD_ROOT_DIR SITE_ID\n\n";
  exit;
}

use XML::Simple;
$xml = new XML::Simple;
$mainconf = $xml->XMLin($ARGV[0].'conf.xml');
$layers = $xml->XMLin($ARGV[0].$mainconf->{'dirvector'}.$mainconf->{'dirplaces'}.$ARGV[1].'/'.$mainconf->{'filelayers'});
$len = scalar(@{$layers->{'layer'}});
@max = qw(181 91 -181 -91);
for($i=0; $i<=$len; $i++) {
  if($layers->{'layer'}[$i]{'type'} eq 'tms') {

    $year = $layers->{'layer'}[$i]{'year'};
    print 'BBox & GCP '.$ARGV[1].' '.$year."\n";
    open (DATA, '>'.$ARGV[0].$mainconf->{'dirvector'}.$mainconf->{'dirplaces'}.$ARGV[1].'/bbox'.$year.'.kml');
    binmode DATA, ":utf8";
    print DATA $filebase.$conf->{'Document'}{'ExtendedData'}{'v:kmlheader'};
    print DATA <<EndHeader;
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://earth.google.com/kml/2.2">
<Document>
<Placemark id="bbox">
<name>BBox</name>
<LineString>
EndHeader
    @c = split(/[,\s]/, $layers->{'layer'}[$i]{'bounds'});
    print DATA '<coordinates>'.$c[0].','.$c[1].' '.$c[0].','.$c[3].' '.$c[2].','.$c[3].' '.$c[2].','.$c[1].' '.$c[0].','.$c[1];
    print DATA <<EndHeader;
</coordinates>
</LineString>
</Placemark>
EndHeader

    if($c[0] < $max[0]) { $max[0] = $c[0]; }
    if($c[1] < $max[1]) { $max[1] = $c[1]; }
    if($c[2] > $max[2]) { $max[2] = $c[2]; }
    if($c[3] > $max[3]) { $max[3] = $c[3]; }

    $file = $ARGV[0].$mainconf->{'dirvector'}.$mainconf->{'dirplaces'}.$ARGV[1].'/gdal'.$year.'.txt';
    if(-e $file) {
      @c = qw();
      open(INFO, $file) or die("Could not open file.");
      foreach $line (<INFO>) { if($line =~ /gdal_translate/) { @c = split(/\s+/, $line); } }
      close(INFO);
      if(scalar(@c) > 5) {
        $j = 0;
        for($gi=0; $gi<scalar(@c); $gi++) {
          if($c[$gi] eq '-gcp') {
            $j++;
            print DATA  '<Placemark id="gcp'.$j.'"><name>'.$j.'</name><description>'.$c[1+$gi].' '.$c[2+$gi].'</description><Point><coordinates>'.$c[3+$gi].','.$c[4+$gi]."</coordinates></Point></Placemark>\n";
          }
        }
      }
    }
    print DATA <<EndHeader;
</Document>
</kml>
EndHeader
    close(DATA);
  }
}

print 'BBox '.join(',', @max)."\n";