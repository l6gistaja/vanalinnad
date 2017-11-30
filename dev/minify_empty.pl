#!/usr/bin/perl

if(scalar(@ARGV) < 2) {
  print "\nUsage: minify_empty.pl EMPTY_JSON_V1_FILE EMPTY_JSON_V2_FILE\n\n";
  exit;
}

use JSON;
use Data::Dumper;
use Scalar::Util qw(reftype);
use Storable qw(dclone);
use lib './dev';
use VlHelper qw(json_file_read json_file_write);
use constant NIL => -1;
use constant BBOX => 'R';

%v1 = json_file_read($ARGV[0]);
%v2 = qw();
%index = qw();
%ranges = qw();

foreach $year (keys %v1) {
    $v2{$year} = {};
    foreach $zoom (keys %{$v1{$year}}) {
        $v2{$year}{$zoom}{''.BBOX} = [NIL,NIL,NIL,NIL];
        foreach $lon (keys %{$v1{$year}{$zoom}}) {
            $l = 0 + $lon;
            if($v2{$year}{$zoom}{''.BBOX}[0] == NIL || $l < $v2{$year}{$zoom}{''.BBOX}[0]) { $v2{$year}{$zoom}{''.BBOX}[0] = $l; }
            if($v2{$year}{$zoom}{''.BBOX}[1] == NIL || $l > $v2{$year}{$zoom}{''.BBOX}[1]) { $v2{$year}{$zoom}{''.BBOX}[1] = $l; }
            $l = reftype($v1{$year}{$zoom}{$lon}[0]) eq 'ARRAY' ? $v1{$year}{$zoom}{$lon}[0][0] : $v1{$year}{$zoom}{$lon}[0];
            if($v2{$year}{$zoom}{''.BBOX}[2] == NIL || $l < $v2{$year}{$zoom}{''.BBOX}[2]) { $v2{$year}{$zoom}{''.BBOX}[2] = $l; }
            $l = scalar(@{$v1{$year}{$zoom}{$lon}}) - 1;
            $l = reftype($v1{$year}{$zoom}{$lon}[$l]) eq 'ARRAY' ? $v1{$year}{$zoom}{$lon}[$l][1] : $v1{$year}{$zoom}{$lon}[$l];
            if($v2{$year}{$zoom}{''.BBOX}[3] == NIL || $l > $v2{$year}{$zoom}{''.BBOX}[3]) { $v2{$year}{$zoom}{''.BBOX}[3] = $l; }
            $unique_key = "$year/$zoom".encode_json($v1{$year}{$zoom}{$lon});
            $l = NIL;
            if(exists $ranges{$unique_key}) {
                $l = $ranges{$unique_key};
            } else {
                $ranges{$unique_key} = $lon;
            }
            $index{"$year/$zoom/$lon"} = $l;
        }
        $v2{$year}{$zoom}{''.BBOX}[1] = $v2{$year}{$zoom}{''.BBOX}[1] - $v2{$year}{$zoom}{''.BBOX}[0];
        $v2{$year}{$zoom}{''.BBOX}[3] = $v2{$year}{$zoom}{''.BBOX}[3] - $v2{$year}{$zoom}{''.BBOX}[2];
    }
}

foreach $lon (keys %index) {
    @long = split(/\//, $lon);
    $x = $v2{$long[0]}{$long[1]}{''.BBOX}[0];
    $y = $v2{$long[0]}{$long[1]}{''.BBOX}[2];
    if($index{$lon} == NIL) {
        @data = @{dclone($v1{$long[0]}{$long[1]}{$long[2]})};
        foreach($i = 0; $i < scalar(@data); $i++) {
            $data[$i] = reftype($data[$i]) eq 'ARRAY' ? [$data[$i][0] - $y, $data[$i][1] - $y] : $data[$i] - $y;
        }
        $v2{$long[0]}{$long[1]}{''.($long[2] - $x)} = [@data];
    } else {
       $v2{$long[0]}{$long[1]}{''.($long[2] - $x)} = $index{$lon} - $x;
    }
}

json_file_write($ARGV[1], \%v2);
