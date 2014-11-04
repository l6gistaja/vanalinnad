#!/usr/bin/perl

use JSON;

if(scalar(@ARGV) < 1) {
  print "\nUsage: ./dev/jsoncleaner.pl SITE_ID\nDeletes empty tile data of nonexisting year directories.\n";
  exit;
}

$dir = './raster/places/'.$ARGV[0];
opendir(DIR, $dir) or die $!;
@y = qw();
while ( $file = readdir(DIR)) {
    # Use a regular expression to ignore files beginning with a period
    next if ($file =~ m/^\./);
    push(@y, $file);
}
closedir(DIR);
print "Existing year directories: '".join("', '",@y)."'\n";

$emptyjson = './vector/places/'.$ARGV[0].'/empty.json';
open(FILE, $emptyjson) or die "Can't read file $emptyjson [$!]\n";
$document = <FILE>;
close (FILE);
%doc = %{decode_json($document)};

@d = qw();
foreach $year (keys %doc) {
  if ( !($year ~~ @y) ) {
    push(@d, $year);
    delete $doc{$year};
  }
}

if(scalar(@d) > 0) {
  open(FILE, '>'.$emptyjson) or die "Can't read file $emptyjson [$!]\n";
  print FILE encode_json(\%doc);
  close (FILE);
  print "Deleted: '".join("', '",@d)."'\n";
}

exit 0;
