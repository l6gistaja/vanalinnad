#!/usr/bin/perl

if(scalar(@ARGV) < 2) {
  print "\nUsage: empty1to2_workhorse.pl EMPTY_JSON_V1_FILE EMPTY_JSON_V2_FILE\n\n";
  exit;
}

use lib './dev';
use VlHelper qw(json_file_read json_file_write minify_empty_tiles_json_v2);

%v1 = json_file_read($ARGV[0]);
%v2 = minify_empty_tiles_json_v2(\%v1);
json_file_write($ARGV[1], \%v2);
