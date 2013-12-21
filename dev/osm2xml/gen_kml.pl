#!/usr/bin/perl

use XML::Simple;
use Switch;

$all = 1;

$xml = new XML::Simple;
$conf = $xml->XMLin('roads.kml');
@coords = split(/[,\s]/,$conf->{'Document'}{'Placemark'}[$ARGV[0]]{'LineString'}{'coordinates'});

$data = $xml->XMLin($conf->{'Document'}{'ExtendedData'}{'v:dirbase'}
    .$conf->{'Document'}{'ExtendedData'}{'v:dircache'}
    .$conf->{'Document'}{'ExtendedData'}{'v:fileprefix'}
    .join('_',@coords)
    .$filebase.$conf->{'Document'}{'ExtendedData'}{'v:filextxml'});
$len = scalar(@{$data->{'w'}});
%index = qw();

for($i=0; $i<=$len; $i++) {
  if ($all) {
    $index{'i'.$i} = $i;
  } else {
    $write = 0;
    $name = $data->{'w'}[$i]{'n'};
    $name =~ s/^\s+//;
    $name =~ s/\s+$//;
    if($name eq '') { print $i."\n"; next; }
    @g = split(",", $data->{'w'}[$i]{'g'});
    $l = scalar(@g);

    if($index{$name}) {
      $x = $index{$name};
      if($l > $data->{'w'}[$x]{'L'}) { $write = 1; }
      if($l == $data->{'w'}[$x]{'L'} && $data->{'w'}[$i]{'t'} gt $data->{'w'}[$x]{'t'}) { $write = 1; }
    } else {
      $write = 1;
    }

    if($write){
      $data->{'w'}[$i]{'L'} = $l;
      $index{$name} = $i;
    }
  }

}

@levels = qw(primary secondary tertiary);
$levelLen = scalar(@levels);

for($level = 0; $level < $levelLen+1; $level++) {

open (DATA, '>'.$conf->{'Document'}{'ExtendedData'}{'v:dirbase'}
  .$conf->{'Document'}{'ExtendedData'}{'v:dircache'}
  .$conf->{'Document'}{'ExtendedData'}{'v:fileprefixroads'}
  .$level
  .$conf->{'Document'}{'ExtendedData'}{'v:filextkml'});
binmode DATA, ":utf8";

print DATA $filebase.$conf->{'Document'}{'ExtendedData'}{'v:kmlheader'};
print DATA <<EndHeader;
<LatLonBox>
<north>>$coords[3]</north>
<south>$coords[1]</south>
<east>$coords[2]</east>
<west>$coords[0]</west>
</LatLonBox> 
EndHeader

while ( ($k, $v) = each %index ) {
  $next = 0;
  $g = $data->{'w'}[$v]{'g'};
  if(''.$g eq '') {
     $next = 1;
  } else {
    if ($level == $levelLen) {
      for($i = 0; $i < $levelLen; $i++) {
        if($levels[$i] eq $data->{'w'}[$v]{'h'}) {
          $next = 1;
          break;
        }
      }
    } else {
      if($data->{'w'}[$v]{'h'} ne $levels[$level]) { $next = 1; }
    }
  }
  if($next) { next; }
  $g = $data->{'w'}[$v]{'g'};
  print DATA '<Placemark><name>'.$data->{'w'}[$v]{'n'}.'</name><LineString><coordinates>'.$g."</coordinates></LineString></Placemark>\n";
}

print DATA $filebase.$conf->{'Document'}{'ExtendedData'}{'v:kmlfooter'};
close(DATA);

}
