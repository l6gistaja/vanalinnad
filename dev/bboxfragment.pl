#!/usr/bin/perl

if(scalar(@ARGV) < 2) {
  print "\nUsage: bboxfragment.pl GDAL_FILE_PATH 'MAP_ID' {W,S,E,N}\n\n";
  exit;
}

print "\n";

if(scalar(@ARGV) > 2) {
    @c = split(/[,]/, $ARGV[2]);
    print '<Placemark id="bbox'.
      ($ARGV[1] eq '' ? '' : '.'.$ARGV[1]).
      '"><name>'.
      $ARGV[1].
      '</name><LineString><coordinates>'.
      $c[0].','.$c[1].' '.$c[0].','.$c[3].' '.$c[2].','.$c[3].' '.$c[2].','.$c[1].' '.$c[0].','.$c[1].
      "</coordinates></LineString></Placemark>\n";
}

if(-e $ARGV[0]) {
  @c = qw();
  open(INFO, $ARGV[0]) or die("Could not open file ".$ARGV[0]);
  foreach $line (<INFO>) { if($line =~ /gdal_translate/) { @c = split(/\s+/, $line); } }
  close(INFO);
  if(scalar(@c) > 5) {
    $j = 0;
    for($gi=0; $gi<scalar(@c); $gi++) {
      if($c[$gi] eq '-gcp') {
        $j++;
        print '<Placemark id="gcp'.$ARGV[1].'.'.$j.'"><name>'.
          ($ARGV[1] eq '' ? '' : $ARGV[1].' ').
          '#'.$j.'</name><description>'.$c[1+$gi].' '.$c[2+$gi].'</description><Point><coordinates>'.$c[3+$gi].','.$c[4+$gi]."</coordinates></Point></Placemark>\n";
      }
    }
  }
}

print "\n";
