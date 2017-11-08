#!/usr/bin/perl

if(scalar(@ARGV) < 2) {
  print "\nUsage: dev/mixer.pl SITE YEAR\n\n";
  exit;
}

use lib './dev';
use VlHelper qw(minify_empty_tiles_json add_empty_tiles_json bbox_fragment add_to_tree kml_envelope gdal_tlast bbox_box bbox_points json_file_read);
use Data::Dumper;
use POSIX;

$gdaltxtformat = 0;

%data = qw();
$rootdir = '';
$site = $ARGV[0];
$year = $ARGV[1];

use XML::Simple;
$xml = new XML::Simple;
$mainconf = $xml->XMLin($rootdir.'conf.xml');
$gdaldir = $rootdir.$mainconf->{'dirvector'}.$mainconf->{'dirplaces'}.$site.'/';
$bboxfile = $gdaldir.'bbox'.$year.'.kml';
%localdata = json_file_read($mainconf->{'dircache'}.$mainconf->{'filelocal'});

if($gdaltxtformat) {
  $bboxdata = $xml->XMLin($bboxfile);
  #print Dumper($bboxdata);
  foreach $key (keys %{$bboxdata->{'Document'}->{'ExtendedData'}->{'Data'}}) {
    $data{$key} = $bboxdata->{'Document'}->{'ExtendedData'}->{'Data'}->{$key}->{'value'};
  }
} else {
  $vdir = $mainconf->{'dirvector'}.$mainconf->{'dirplaces'}.$site.'/';
  $layers = $xml->XMLin($vdir.$mainconf->{'filelayers'}, ForceArray => 1);
  $gdal = $xml->XMLin($vdir.$mainconf->{'filegdal'}, ForceArray => 1);
  if(!exists $gdal->{'composite'}{$year}) {
    print 'No composite '.$year.' in '.$vdir.$mainconf->{'filegdal'};
    exit;
  }
  if(exists $gdal->{'composite'}{$year}{'montage'}) {
    $data{'montage'} = 'yes';
  }
  $data{'maps'} = $gdal->{'composite'}{$year}{'maps'};
  $data{'zmin'} = $layers->{'minzoom'}[0];
  $data{'zmax'} = $layers->{'maxzoom'}[0];
  $data{'tileext'} = '.jpg';
  $data{'sourcedir'} = $localdata{'dirsource'}.$site.'/'.$mainconf->{'dircomposite'}.$year.'/';
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

$kmldata = '';
@bounds = qw();
%compositebboxes = qw();
for($m=0; $m<$maplen; $m++) {
  $renderdata = $xml->XMLin($data{'sourcedir'}.$maps[$m].'/tilemapresource.xml');
  $coords = join(',',
    $renderdata->{'BoundingBox'}->{'miny'},
    $renderdata->{'BoundingBox'}->{'minx'},
    $renderdata->{'BoundingBox'}->{'maxy'},
    $renderdata->{'BoundingBox'}->{'maxx'});
  # OpenLayers bounds are in order W,S,E,N
  if($gdaltxtformat) {
    $kmldata .= bbox_fragment($gdaldir.'gdal'.$maps[$m].'.txt', ''.$maps[$m], $coords);
  } else {
    $compositebboxes{$maps[$m]} = $coords;
  }
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
}

if(!$gdaltxtformat) {
  $ts = scalar(@{$gdal->{'translate'}});
  for($i = 0; $i < $ts; $i++) {
    if($gdal->{'translate'}[$i]{'composite'} eq $year) {
      $tlast = gdal_tlast($gdal, $i);
      $kmldata .= "\n".bbox_box($gdal->{'translate'}[$i]{'map'}, $compositebboxes{$gdal->{'translate'}[$i]{'map'}})
        .bbox_points($gdal->{'translate'}[$i]{'t'}[$tlast]{'gcps'}, $gdal->{'translate'}[$i]{'map'});
    }
  }
}

$data{'bbox'} = join(',',@bounds);

$kmldata .= "\n<ExtendedData>\n";
foreach $key (keys %data) {
  $kmldata .= '<Data name="'.$key.'"><value>'.$data{$key}."</value></Data>\n";
}
$kmldata .= "\n</ExtendedData>\n";

open (DATA, '>'.$bboxfile) or die("Could not open file ".$bboxfile);
binmode DATA, ":utf8";
print DATA kml_envelope($kmldata);
close(DATA);

# MERGE MAPS

$destinationdir = $rootdir.$mainconf->{'dirraster'}.$mainconf->{'dirplaces'}.$site.'/'.$year.'/';
if(-e $destinationdir) {
  $command = 'rm -rf '.$destinationdir.'*';
} else {
  $command = 'mkdir -p '.$destinationdir;
}
print $command."\n";
system($command);

%json = qw();
%montage = qw();
$tilewhite = $rootdir.$mainconf->{'dirdev'}.'whitetile'.$data{'tileext'};
$tilewritable = $data{'sourcedir'}.'tilewritable'.$data{'tileext'};
$tiletransparent = $data{'sourcedir'}.'tiletransparent.png';
for($z=$data{'zmax'}; $z>=$data{'zmin'}; $z--) {
  print 'Merging zoomlevel '.$z." ...\n";
  $zdir = $destinationdir.$z;
  system('mkdir '.$zdir);
  for($x=$tiles{'xmin'.$z}; $x<=$tiles{'xmax'.$z}; $x++) {
    $xdir = $zdir.'/'.$x;
    system('mkdir '.$xdir);
    for($y=0+$tiles{'ymin'.$z}; $y<=$tiles{'ymax'.$z}; $y++) { 
      $emptytile = 1;
      $cmd = '';
      
      # montage lower zoom levels tiles from one level higher tiles,
      # if higher level tiles were composed/montaged from many overlapping maps.
      # it helps to hide ugly composition lines from higher levels.
      if(exists $data{'montage'} && $z < $data{'zmax'}) {
      ##if(exists $data{'montage'} && $z < $data{'zmax'} && exists $montage{$z} && exists $montage{$z}{$x}) {
        ##$yl = scalar(@{$montage{$z}{$x}});
        ##for($ym=0;$ym<$yl;$ym++) {
        ##  if($montage{$z}{$x}[$ym] == $y) {
            @src = qw();
            $emptycount = 0;
            for($yy=1;$yy>-1;$yy--) {
              for($yx=0;$yx<2;$yx++) {
                $mtile = $destinationdir.(1+$z).'/'.($yx + ($x << 1)).'/'.($yy + ($y << 1)).$data{'tileext'};
                $emptytile = !(-e $mtile) || (0 + `identify -format %k $mtile` < 2);
                push(@src, $emptytile ? $tilewhite : $mtile);
                if($emptytile) { $emptycount++; }
              }
            }
            if($emptycount < 4) {
              $cmd = 'montage '.join(' ', @src).' -tile 2x2 -geometry 128x128+0+0 '.$xdir.'/'.$y.$data{'tileext'};
              system($cmd);
            } else {
              $cmd = '#';
              add_to_tree([$z,$x,0+$y],\%json);
            }
        ##    add_to_tree([$z - 1, $x >> 1, $y >> 1], \%montage);
        ##    last;
        ##  }
        ##}
      }

      if($cmd ne ''){ next; }
      for($m=0; $m<$maplen; $m++) {
        $mapfile = $data{'sourcedir'}.$maps[$m].'/'.$z.'/'.$x.'/'.$y.$data{'tileext'};
        # if current map tile doesnt exist or is monocolor, then continue with other maps
        if(!(-e $mapfile) || (0 + `identify -format %k $mapfile` < 2)) {
          next;
        }
        if($emptytile) {
          system('cp '.$mapfile.' '.$tilewritable);
        } else {
          if(!exists $data{'montage'} || $z == $data{'zmax'}) {
            system('convert -transparent white '.$mapfile.' '.$tiletransparent);
            system('composite '.$tiletransparent.' '.$tilewritable.' -gravity center '.$tilewritable);
            ##add_to_tree([$z - 1, $x >> 1, $y >> 1], \%montage);
          }
        }
        $emptytile = 0;
      }
      if($emptytile) {
        add_to_tree([$z,$x,0+$y],\%json);
      } else {
        system('cp '.$tilewritable.' '.$xdir.'/'.$y.$data{'tileext'});
      }
    }
  }
}

%json = minify_empty_tiles_json(\%json);
add_empty_tiles_json($gdaldir.$mainconf->{'fileemptytiles'}, $year, \%json);
