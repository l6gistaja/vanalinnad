#!/usr/bin/perl

use lib '..';
use VlHelper qw(minify_empty_tiles_json add_empty_tiles_json);

%json = qw();

open(INFO, $ARGV[0]) or die("Could not open file.");

foreach $line (<INFO>)  {
  $line =~ s/\.[a-z]+\s*$//i;
  @coords = split(/\//,$line);
  $z = ''.$coords[-3];
  if(!exists $json{$z}) { $json{$z} = qw(); }
  $x = ''.$coords[-2];
  $y = 0 + $coords[-1];
  if(!exists $json{$z}{$x}) {
    $json{$z}{$x} = [$y];
  } else {
    # if not duplicate
    if ( !($y ~~ @{$json{$z}{$x}}) ) {
      push(@{$json{$z}{$x}}, $y);
    }
  }
}

close(INFO);

%json = minify_empty_tiles_json(\%json);
add_empty_tiles_json($ARGV[1], "".$coords[-4], \%json);
