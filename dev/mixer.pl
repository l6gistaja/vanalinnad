#!/usr/bin/perl

if(scalar(@ARGV) < 2) {
  print "\nUsage: mixer.pl VANALINNAD_ROOT_DIR RELATIVE/PATH/TO/BBOX_FILE\n\n";
  exit;
}

use XML::Simple;
$xml = new XML::Simple;

$bboxdata = $xml->XMLin($ARGV[0].$ARGV[1]);
$mainconf = $xml->XMLin($ARGV[0].'conf.xml');

use Data::Dumper;
#print Dumper($bboxdata);

%data = qw();
foreach $key (keys %{$bboxdata->{'Document'}->{'ExtendedData'}->{'Data'}}) {
  $data{$key} = $bboxdata->{'Document'}->{'ExtendedData'}->{'Data'}->{$key}->{'value'};
}

# DISCOVER TILES 

%tiles = qw();
@maps = split(/,/, $data{'maps'});
$maplen = scalar(@maps);
for($m=0; $m<$maplen; $m++) {
  for($z=$data{'zmin'}; $z<=$data{'zmax'}; $z++) {

    $command = 'ls -1 '.$data{'sourcedir'}.$maps[$m].'/'.$z;
    #print $command."\n";
    @xs = `$command`;
    $xslen = scalar(@xs);
    for($xk=0; $xk<$xslen; $xk++) {
      $x = 0 + $xs[$xk];
      if(exists $tiles{'xmin'.$z}) {
        if($x > $tiles{'xmax'.$z}) { $tiles{'xmax'.$z} = $x; }
        if($x < $tiles{'xmin'.$z}) { $tiles{'xmin'.$z} = $x; }
      } else {
        $tiles{'xmin'.$z} = $tiles{'xmax'.$z} = $x;
      }
    }

    $command = 'ls -1 '.$data{'sourcedir'}.$maps[$m].'/'.$z.'/'.$x;
    print $command."\n";
    @ys = `$command`;
    $yslen = scalar(@ys);
    for($yk=0; $yk<$yslen; $yk++) {
      $y = 0 + $ys[$yk];
      if(exists $tiles{'ymin'.$z}) {
        if($y > $tiles{'ymax'.$z}) { $tiles{'ymax'.$z} = $y; }
        if($y < $tiles{'ymin'.$z}) { $tiles{'ymin'.$z} = $y; }
      } else {
        $tiles{'ymin'.$z} = $tiles{'ymax'.$z} = $y;
      }
    }

  }
}

# GENERATE BBOX KML

open (DATA, '>'.$ARGV[0].$ARGV[1]) or die("Could not open file ".$ARGV[0].$ARGV[1]);
binmode DATA, ":utf8";

print DATA <<EndHeader;
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>
EndHeader

$gdaldir = '/home/jux/vanalinnad/vector/places/Tallinn/';
@bounds = qw();
for($m=0; $m<$maplen; $m++) {
  $renderdata = $xml->XMLin($data{'sourcedir'}.$maps[$m].'/tilemapresource.xml');
  # OpenLayers bounds are in order W,S,E,N
  $command = $ARGV[0].$mainconf->{'dirdev'}.'bboxfragment.pl '.
    $gdaldir.'gdal'.$maps[$m].'.txt'.
    ' \''.$maps[$m].'\' '.
    join(',',
      $renderdata->{'BoundingBox'}->{'miny'},
      $renderdata->{'BoundingBox'}->{'minx'},
      $renderdata->{'BoundingBox'}->{'maxy'},
      $renderdata->{'BoundingBox'}->{'maxx'},
      );
      if(scalar(@bounds) == 0) {
        push(@bounds,$renderdata->{'BoundingBox'}->{'miny'});
        push(@bounds,$renderdata->{'BoundingBox'}->{'minx'});
        push(@bounds,$renderdata->{'BoundingBox'}->{'maxy'});
        push(@bounds,$renderdata->{'BoundingBox'}->{'maxx'});
      } else {
        if($bounds[0] > $renderdata->{'BoundingBox'}->{'miny'}) {
          $bounds[0] = $renderdata->{'BoundingBox'}->{'miny'};
        }
        if($bounds[1] > $renderdata->{'BoundingBox'}->{'minx'}) {
          $bounds[1] = $renderdata->{'BoundingBox'}->{'minx'};
        }
        if($bounds[2] < $renderdata->{'BoundingBox'}->{'maxy'}) {
          $bounds[2] = $renderdata->{'BoundingBox'}->{'maxy'};
        }
        if($bounds[3] < $renderdata->{'BoundingBox'}->{'maxx'}) {
          $bounds[3] = $renderdata->{'BoundingBox'}->{'maxx'};
        }
      }
  print $command."\n";
  print DATA `$command`;
}
$data{'bbox'} = join(',',@bounds);

print DATA <<EndHeader;
<ExtendedData>
EndHeader

foreach $key (keys %data) {
  print DATA '<Data name="'.$key.'"><value>'.$data{$key}."</value></Data>\n";
}

print DATA <<EndHeader;
</ExtendedData>

</Document>
</kml>
EndHeader

close(DATA);

# MERGE MAPS

if(-e $data{'destinationdir'}) {
  $command = 'rm -rf '.$data{'destinationdir'}.'*';
} else {
  $command = 'mkdir '.$data{'destinationdir'};
}
print $command."\n";
system($command);

$tilewhite = $ARGV[0].$mainconf->{'dirdev'}.'whitetile'.$data{'tileext'};
$tilewritable = $data{'sourcedir'}.'tilewritable'.$data{'tileext'};
$tiletransparent = $data{'sourcedir'}.'tiletransparent.png';
$tilemerged = $data{'sourcedir'}.'tilemerged'.$data{'tileext'};
for($z=$data{'zmin'}; $z<=$data{'zmax'}; $z++) {
  $zdir = $data{'destinationdir'}.$z;
  system('mkdir '.$zdir);
  for($x=$tiles{'xmin'.$z}; $x<=$tiles{'xmax'.$z}; $x++) {
    $xdir = $zdir.'/'.$x;
    system('mkdir '.$xdir);
    for($y=$tiles{'ymin'.$z}; $y<=$tiles{'ymax'.$z}; $y++) {
      $emptytile = 1;
      for($m=0; $m<$maplen; $m++) {
        $mapfile = $data{'sourcedir'}.$maps[$m].'/'.$z.'/'.$x.'/'.$y.$data{'tileext'};
        if(!(-e $mapfile) || (0 + `identify -format %k $mapfile` < 2)) {
          next;
        }
        if($emptytile) {
          system('cp '.$mapfile.' '.$tilewritable);
        } else {
          system('convert -transparent white '.$mapfile.' '.$tiletransparent);
          system('composite '.$tiletransparent.' '.$tilewritable.' -gravity center '.$tilemerged);
          system('cp '.$tilemerged.' '.$tilewritable);
        }
        $emptytile = 0;
      }
      system('cp '.($emptytile ? $tilewhite : $tilewritable).' '.$xdir.'/'.$y.$data{'tileext'});
    }
  }
}