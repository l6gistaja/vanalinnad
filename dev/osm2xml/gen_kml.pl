#!/usr/bin/perl

use XML::Simple;

$xml = new XML::Simple;
$conf = $xml->XMLin('roads.kml');
$mainconf = $xml->XMLin($conf->{'Document'}{'ExtendedData'}{'v:dirbase'}.'conf.xml');
@coords = split(/[,\s]/,$conf->{'Document'}{'Placemark'}[$ARGV[0]]{'LineString'}{'coordinates'});

$data = $xml->XMLin($conf->{'Document'}{'ExtendedData'}{'v:dirbase'}
    .$mainconf->{'dircache'}
    .$conf->{'Document'}{'ExtendedData'}{'v:fileprefix'}
    .join('_',@coords)
    .$filebase.$conf->{'Document'}{'ExtendedData'}{'v:filextxml'});
$len = scalar(@{$data->{'w'}});
%index = qw();

for($i=0; $i<=$len; $i++) {

  $write = 0;
  $name = $data->{'w'}[$i]{'n'};
  $name =~ s/^\s+//;
  $name =~ s/\s+$//;
  if($name eq '') { next; }

  if(exists $index{$name}) {
    push(@{$index{$name}}, $i);
  } else {
    $index{$name} = [$i];
  }

}



@levels = qw(trunk primary secondary tertiary);
$levelLen = scalar(@levels);

for($level = 0; $level < $levelLen+1; $level++) {
  $file = $conf->{'Document'}{'ExtendedData'}{'v:dirbase'}
    .$mainconf->{'dircache'}
    .$mainconf->{'fileprefixroads'}
    .$level
    .$conf->{'Document'}{'ExtendedData'}{'v:filextkml'};
  print $file."\n";
  open (DATA, '>'.$file);
  binmode DATA, ":utf8";

  print DATA $filebase.$conf->{'Document'}{'ExtendedData'}{'v:kmlheader'};
  print DATA <<EndHeader;
  <LatLonBox>
    <north>$coords[3]</north>
    <south>$coords[1]</south>
    <east>$coords[2]</east>
    <west>$coords[0]</west>
  </LatLonBox>
EndHeader

  while ( ($k, $v) = each %index ) {
    $next = 0;
    @parts = @{$v};
    $partslen = scalar(@parts);
    if ($level == $levelLen) {
      for($i = 0; $i < $levelLen; $i++) {
        if($levels[$i] eq $data->{'w'}[$parts[0]]{'h'}) {
          $next = 1;
          break;
        }
      }
    } else {
      if($data->{'w'}[$parts[0]]{'h'} ne $levels[$level]) { $next = 1; }
    }
    @linestrings = qw();
    for($i = 0; $i < $partslen; $i++) { push(@linestrings, $data->{'w'}[$parts[$i]]{'g'}); }
    if($next) { next; }
    print DATA '<Placemark><name>'.$data->{'w'}[$parts[0]]{'n'}.'</name>';
    if($partslen > 1) { print DATA '<MultiGeometry>'; }
    print DATA '<LineString><coordinates>'
      .join('</coordinates></LineString><LineString><coordinates>', @linestrings)
      .'</coordinates></LineString>';
    if($partslen > 1) { print DATA '</MultiGeometry>'; }
    print DATA "</Placemark>\n";
  }

  print DATA $filebase.$conf->{'Document'}{'ExtendedData'}{'v:kmlfooter'};
  close(DATA);

}
