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

$xml = new XML::Simple;
$kml = $xml->XMLin($ARGV[1], ForceArray => 1);
#use Data::Dumper; print Dumper($kml);

%json = {};
$json{x} = 180;
$json{y} = 90;
$json{precision} = 0+int($ARGV[0]);
@{$json{features}} = ();
$c = 0;

foreach $placemark (@{$kml->{'Document'}[0]->{'Placemark'}}) {
  push @{$json{features}}, {};
  foreach $k (keys %{$placemark}) {
    if($k eq 'MultiGeometry') {
      @{$json{features}[$c]{g}} = ();
      foreach $linestr (@{$placemark->{'MultiGeometry'}[0]->{'LineString'}}) {
        @mla = analyze_linestr($linestr->{'coordinates'}[0]);
        push @{$json{features}[$c]{g}}, dclone(\@mla);
      }
    } elsif($k eq 'LineString' || $k eq 'Point') {
      @{$json{features}[$c]{g}} = ();
      @mla = analyze_linestr($placemark->{$k}[0]->{'coordinates'}[0]);
      push @{$json{features}[$c]{g}},  dclone(\@mla);
    } else {
      $json{features}[$c]{substr($k, 0, 1)} = $placemark->{$k}[0];
    }
  }
  $c++;
}

$prec_m = 10**$json{precision};
$prec_x = round($json{x} * $prec_m, 0);
$prec_y = round($json{y} * $prec_m, 0);
$json{x} = round($json{x}, $json{precision});
$json{y} = round($json{y}, $json{precision});

$i = 0;
foreach $feature (@{$json{features}}) {
    $geometry = '';
    foreach $linestring (@{$feature->{g}}) {
        $ls = '';
        $geometry .= $geometry eq '' ? '' : '/';
        $j = 0;
        foreach $cell (@{$linestring}) {
            $int = int(round($cell * $prec_m, 0) - ($j%2 ? $prec_y : $prec_x));
            $vli64 = '';
            do {
                $m = $int % 64;
                $vli64 .= ($m == 44 ? 'p' : chr(48 + $m));
                $int >>= 6;
            } while ($int);
            $ls .= ($ls eq '' ? '' : ',').$vli64; #.lc(encode_base36($int));
            $j++;
        }
        $geometry .= $ls;
    }
    $json{features}[$i]{g} = $geometry;
    $i++;
}

#TODO: smth leaks
foreach $key (keys %json) { if($key =~ /^HASH\(0x/) { delete $json{$key}; } }
$json{precision} = 0+int($json{precision});

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


