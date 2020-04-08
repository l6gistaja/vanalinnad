#!/usr/bin/perl

if(scalar(@ARGV) < 3) {
  print "\nUsage: kml2vlgson.pl PRECISION SOURCE_KML_FILE_PATH RESULT_JSON_FILE_PATH";
  print "\nPRECISION examples: 5 = 1.1 m of latitude, 6 = 0.11 m of latitude\n\n";
  exit;
}

use utf8;
use XML::Simple;
use Storable qw(dclone);
use JSON;
use Math::Base36 'encode_base36';

$precision = int($ARGV[0]);
$xml = new XML::Simple;
$kml = $xml->XMLin($ARGV[1], ForceArray => 1);
#use Data::Dumper; print Dumper($kml);

%json = {};
$json{x} = 180;
$json{y} = 90;
$json{precision} = int($precision);
@{$json{f}} = ();
$c = 0;

foreach $placemark (@{$kml->{'Document'}[0]->{'Placemark'}}) {
  push @{$json{f}}, {};
  foreach $k (keys %{$placemark}) {
    if($k eq 'MultiGeometry') {
      @{$json{f}[$c]{g}} = ();
      foreach $linestr (@{$placemark->{'MultiGeometry'}[0]->{'LineString'}}) {
        @mla = analyze_linestr($linestr->{'coordinates'}[0]);
        push @{$json{f}[$c]{g}}, dclone(\@mla);
      }
    } elsif($k eq 'LineString') {
      @{$json{f}[$c]{g}} = ();
      @mla = analyze_linestr($placemark->{'LineString'}[0]->{'coordinates'}[0]);
      push @{$json{f}[$c]{g}},  dclone(\@mla);
    } else {
      $json{f}[$c]{substr($k, 0, 1)} = $placemark->{$k}[0];
    }
  }
  $c++;
}

foreach $key (keys %json) { if($key =~ /^HASH\(0x/) { delete $json{$key}; } } #TODO: smth leaks
$prec_m = 10**$json{precision};
$prec_x = round($json{x} * $prec_m, 0);
$prec_y = round($json{y} * $prec_m, 0);
$json{x} = round($json{x}, $json{precision});
$json{y} = round($json{y}, $json{precision});

$i = 0;
foreach $feature (@{$json{f}}) {
    $geometry = '';
    foreach $linestring (@{$feature->{g}}) {
        $ls = '';
        $geometry .= $geometry eq '' ? '' : ';';
        $j = 0;
        foreach $cell (@{$linestring}) {
            $ls .= ($ls eq '' ? '' : ',')
                .lc(encode_base36(int(round($cell * $prec_m, 0) - ($j%2 ? $prec_y : $prec_x))));
            $j++;
        }
        $geometry .= $ls;
    }
    $json{f}[$i]{g} = $geometry;
    $i++;
}

open(FILE, '>'.$ARGV[2]) or die "Can't open file '".$ARGV[2]."' for writing: $!\n";
print FILE JSON->new->ascii(1)->encode(\%json);
close (FILE);

sub round { return 0+sprintf("%.".$_[1]."f", $_[0]); }

sub analyze_linestr {
    @coords = split(/[,\s]+/, $_[0]);
    $l = scalar @coords;
    for($i = 0; $i < $l; $i++) {
        $coords[$i] = 0 + $coords[$i];
        if($i%2 == 0) {
            if($json{x} > $coords[$i]) { $json{x} = $coords[$i]; }
        } else {
            if($json{y} > $coords[$i]) { $json{y} = $coords[$i]; }
        }
    }
    return @coords;
};


