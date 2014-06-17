#!/usr/bin/perl


if(scalar(@ARGV) < 3) {
  print "\nUsage: kml_minify.pl PRECISION SOURCE_KML_FILE_PATH RESULT_KML_FILE_PATH";
  print "\nPRECISION examples: .00001 = 1.1 m of latitude, .000001 = 0.11 m of latitude\n\n";
  exit;
}

use XML::Simple;
use Math::Round;

$br = "";
$precision = $ARGV[0];

$xml = new XML::Simple;
$kml = $xml->XMLin($ARGV[1], ForceArray => 1);
#use Data::Dumper; print Dumper($kml);

open (KML, '>'.$ARGV[2]) or die("Could not open file ".$ARGV[2]);
binmode KML, ":utf8";

print KML <<EndHeader;
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://earth.google.com/kml/2.2">
<Document>
EndHeader

foreach $placemark (@{$kml->{'Document'}[0]->{'Placemark'}}) {
  print KML '<Placemark>'.$br;
  foreach $k (keys %{$placemark}) {
    if($k eq 'MultiGeometry') {
      print KML '<MultiGeometry>'.$br;
      foreach $linestr (@{$placemark->{'MultiGeometry'}[0]->{'LineString'}}) {
        print KML '<LineString><coordinates>'.
          format_coords($linestr->{'coordinates'}[0], $precision).
          '</coordinates></LineString>'.$br;
      }
      print KML '</MultiGeometry>'.$br;
    } elsif($k eq 'LineString') {
      print KML '<LineString><coordinates>'.
          format_coords($placemark->{'LineString'}[0]->{'coordinates'}[0], $precision).
          '</coordinates></LineString>'.$br;
    } else {
      $v = $placemark->{$k}[0];
      $v =~ s/&/&amp;/g;
      $v =~ s/</&lt;/g;
      $v =~ s/>/&gt;/g;
      print KML '<'.$k.'>'.$v.'</'.$k.'>'.$br;
    }
  }
  print KML '</Placemark>'.$br;
}

print KML <<EndHeader;

</Document>
</kml>
EndHeader


close(KML) or die("Could not close file ".$ARGV[1]);

sub format_coords {
  $y = $_[0];
  $y =~ s/\s+$//g;
  @coords = split(/[,\s]+/, $y);
  $l = scalar(@coords);
  $y = '';
  for($i = 0; $i < $l; $i++) {
    if($i > 0) { $y .= $i%2 ? ',' : " "; }
    $y .= nearest($_[1], $coords[$i]);
  }
  return $y;
}
