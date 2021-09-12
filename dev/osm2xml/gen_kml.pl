#!/usr/bin/perl

use Getopt::Std;
use XML::Simple;
binmode(STDOUT, "encoding(UTF-8)");

$xml = new XML::Simple;
$dirbase = '';
$mainconf = $xml->XMLin($dirbase.'conf.xml');
$dirosm = $dirbase.$mainconf->{'dirdev'}.'osm2xml/';
$conf = $xml->XMLin($dirosm.'roads.kml');

getopt('b:s:', \%opts);
if(!exists $opts{'b'}) {
  print "\nUsage: dev/osm2xml/generate_roads.pl -b W,S,E,N (-s SITE)\n\n";
  exit;
}

#@coords = scalar(@ARGV) < 2 ? split(/[,\s]/, $conf->{'Document'}{'Placemark'}[$ARGV[0]]{'LineString'}{'coordinates'}) : split(/[,]/, $ARGV[1]);
@coords = split(/[,]/, $opts{'b'});

$data = $xml->XMLin($dirbase
    .$mainconf->{'dircache'}
    .$conf->{'Document'}{'ExtendedData'}{'v:fileprefix'}
    .'_'.(exists $opts{'s'}  ? $opts{'s'} : 'NOSITE').'_'
    .join('_',@coords)
    .$filebase.'.xml');
$len = scalar(@{$data->{'w'}});
%index = qw();
%max = qw();

@levels = qw(trunk primary secondary tertiary);
$levelLen = scalar(@levels);

for($i=0; $i<=$len; $i++) {

  $write = 0;
  $name = $data->{'w'}[$i]{'n'};
  if($name eq '') { $name = $data->{'w'}[$i]{'r'}; }
  $name =~ s/^\s+//;
  $name =~ s/\s+$//;
  if($name eq '') { next; }

  $currentLevel = $levelLen;
  for($l=0; $l<$levelLen; $l++) {
    if($levels[$l] eq $data->{'w'}[$i]{'h'}) {
      $currentLevel = $l;
      break;
    }
  }

  if(exists $index{$name}) {
    push(@{$index{$name}}, $i);
    if($currentLevel < $max{$name}) { $max{$name} = $currentLevel; }
  } else {
    $index{$name} = [$i];
    $max{$name} = $currentLevel;
  }

}

for($level = 0; $level <= $levelLen; $level++) {
  $file = $dirbase
    .$mainconf->{'dircache'}
    .$mainconf->{'fileprefixroads'}
    .$level
    .'.txt';
  print $file."\n";
  open (DATA, '>'.$file);
  binmode DATA, ":utf8";

#  print DATA $filebase.$conf->{'Document'}{'ExtendedData'}{'v:kmlheader'};
#  print DATA <<EndHeader;
#  <LatLonBox>
#    <north>$coords[3]</north>
#    <south>$coords[1]</south>
#    <east>$coords[2]</east>
#    <west>$coords[0]</west>
#  </LatLonBox>
#EndHeader

  while ( ($k, $v) = each %index ) {

    if($max{$k} != $level) { next; }
    @parts = @{$v};
    $partslen = scalar(@parts);
    @linestrings = qw();
    for($i = 0; $i < $partslen; $i++) {
      $data->{'w'}[$parts[$i]]{'g'} =~ s/\s+$//;
      @cf = split(/[,\s]/,$data->{'w'}[$parts[$i]]{'g'});
      $cfLen = scalar(@cf);
      @cfp = qw();
      for($cfi = 0; $cfi < $cfLen; $cfi +=2) {
        # discard points outside boundingbox
        if($cf[$cfi] < $coords[0] || $cf[$cfi] > $coords[2] || $cf[$cfi+1] < $coords[1] || $cf[$cfi+1] > $coords[3]) {
          if(scalar(@cfp) > 1) { push(@linestrings, join(' ', @cfp)); }
          @cfp = qw();
        } else {
          push(@cfp, $cf[$cfi].','.$cf[$cfi+1]);
        }
      }
      if(scalar(@cfp) > 1) { push(@linestrings, join(' ', @cfp)); }
    }

    $partslen = scalar(@linestrings);
    if($partslen < 1) { next; }
    print DATA '<Placemark><name>'.($data->{'w'}[$parts[0]]{'n'} ne '' ? $data->{'w'}[$parts[0]]{'n'} : $data->{'w'}[$parts[0]]{'r'}).'</name>';
    if($partslen > 1) { print DATA '<MultiGeometry>'; }
    print DATA '<LineString><coordinates>'
      .join('</coordinates></LineString><LineString><coordinates>', @linestrings)
      .'</coordinates></LineString>';
    if($partslen > 1) { print DATA '</MultiGeometry>'; }
    print DATA "</Placemark>\n";
  }

#  print DATA $filebase.$conf->{'Document'}{'ExtendedData'}{'v:kmlfooter'};
  close(DATA);

}
