#!/usr/bin/perl

use XML::Simple;
use Getopt::Std;
use Data::Dumper;
use POSIX ();
use lib './dev';
use VlHelper qw(gdal_mapindex gdal_tlast json_file_read);

getopt('s:y:rmd', \%opts);
if(!exists $opts{'s'} || !exists $opts{'y'}) {
  print "\nUsage: dev/tiler.pl -s SITE -y MAPYEAR (-r) (-m) (-d)\n\n";
  print "  -d - only show source image statistics\n";
  print "  -m - don't merge tiles to final map\n";
  print "  -r - don't re-create tiles\n";
  print "  -z - don't zoom image; use last zoomed image from cache instead\n\n";
  exit;
}

$xml = new XML::Simple;
$mainconf = $xml->XMLin('conf.xml');
%c = qw();
$c{'dirvector'} = $mainconf->{'dirvector'}.$mainconf->{'dirplaces'}.$opts{'s'}.'/';
$c{'filegdal'} = $c{'dirvector'}.$mainconf->{'filegdal'};
$gdal = $xml->XMLin($c{'filegdal'}, ForceArray => 1);
#print Dumper($gdal);
%localdata = json_file_read($mainconf->{'dircache'}.$mainconf->{'filelocal'});

$c{'y'} = gdal_mapindex($gdal, $opts{'y'});

if($c{'y'} < 0) {
  print "\nNo map '".$opts{'y'}."' in ".$c{'filegdal'}."\n\n";
  exit;
}

@flags = exists $gdal->{'translate'}[$c{'y'}]{'flags'} ? split(/,/, $gdal->{'translate'}[$c{'y'}]{'flags'}) : qw();

if(exists $gdal->{'translate'}[$c{'y'}]{'composite'}) {
  $c{'composite'} = $gdal->{'translate'}[$c{'y'}]{'composite'};
  $c{'dirsrcimg'} = $localdata{'dirsource'}.$opts{'s'}.'/'.$mainconf->{'dircomposite'}.$c{'composite'}.'/';
  $c{'dirraster'} = $c{'dirsrcimg'}.$opts{'y'};
} else {
  $c{'dirsrcimg'} = $localdata{'dirsource'}.$opts{'s'}.'/';
  $c{'dirraster'} = $mainconf->{'dirraster'}.$mainconf->{'dirplaces'}.$opts{'s'}.'/'.$opts{'y'};
}
$c{'tlast'} = gdal_tlast($gdal, $c{'y'});
$c{'filesrcimg'} = $c{'dirsrcimg'}.$gdal->{'translate'}[$c{'y'}]{'t'}[$c{'tlast'}]{'file'};
$c{'dirtransform'} = $mainconf->{'dircache'}.'transform/';
$c{'filewarp'} = $c{'dirtransform'}.'warp.tif';
$c{'filegeoref'} = $c{'dirtransform'}.'georef.tif';
$c{'filelayers'} = $c{'dirvector'}.$mainconf->{'filelayers'};
#print Dumper(\%c); exit;

if(exists $opts{'d'}) {
  sheller('identify '.$c{'filesrcimg'});
  print "\n";
  exit;
}

if(exists $gdal->{'translate'}[$c{'y'}]{'zoom'} && !exists $opts{'r'}) {
  $c{'filezoomedimg'} = $c{'dirtransform'}.'zoomed.jpg';
  if(!exists $opts{'z'}) {
    sheller('rm '.$c{'filezoomedimg'});
    sheller('convert '.$c{'filesrcimg'}.' -resize '.POSIX::floor(100*$gdal->{'translate'}[$c{'y'}]{'zoom'}).'% '.$c{'filezoomedimg'});
  }
  $c{'filesrcimg'} = $c{'filezoomedimg'};
  sheller('identify '.$c{'filesrcimg'});
}

$layers = $xml->XMLin($c{'filelayers'}, ForceArray => 1);
#print Dumper($layers); exit;

if(!exists $opts{'r'}) {
  
    $cmd = 'mkdir '.$c{'dirtransform'};
    sheller($cmd);
    
    $cmd = 'rm '.$c{'dirtransform'}.'*.tif';
    sheller($cmd);
    
    $deltaX = exists $gdal->{'translate'}[$c{'y'}]{'t'}[$c{'tlast'}]{'deltaX'}
      ? 0 + eval($gdal->{'translate'}[$c{'y'}]{'t'}[$c{'tlast'}]{'deltaX'})
      : 0 ;
    $deltaY = exists $gdal->{'translate'}[$c{'y'}]{'t'}[$c{'tlast'}]{'deltaY'}
      ? 0 + eval($gdal->{'translate'}[$c{'y'}]{'t'}[$c{'tlast'}]{'deltaY'})
      : 0 ;
    $zoom = exists $gdal->{'translate'}[$c{'y'}]{'zoom'}
      ? 0 + $gdal->{'translate'}[$c{'y'}]{'zoom'}
      : 1 ;
    $gcp = $gdal->{'translate'}[$c{'y'}]{'t'}[$c{'tlast'}]{'gcps'};
    if($deltaX != 0 || $deltaY != 0 || $zoom != 1) {
      $gcp =~ s/^\s+|\s+$//g;
      @gcps = split(/\s+/, $gcp);
      for($i = 0; $i < $#gcps; $i += 5) {
        $gcps[$i+1] = POSIX::floor(($deltaX + $gcps[$i+1]) * $zoom);
        $gcps[$i+2] = POSIX::floor(($deltaY + $gcps[$i+2]) * $zoom);
      }
      $gcp = join(' ', @gcps); 
    }
    
    
    $cmd = 'gdal_translate '.$c{'filesrcimg'}.' '.$c{'filegeoref'}.' -of GTiff '.$gcp;
    sheller($cmd);

    $cmd = 'gdalwarp -dstnodata "255 255 255" '.$c{'filegeoref'}.' '.$c{'filewarp'};
    sheller($cmd);
    $cmd = 'rm -rf '.$c{'dirraster'};
    sheller($cmd);

    $cmd = $mainconf->{'dirdev'}.'gdal2tiles.py --profile mercator --s_srs \'GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563,AUTHORITY["EPSG","7030"]],AUTHORITY["EPSG","6326"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.01745329251994328,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4326"]]\' --zoom '.$layers->{'minzoom'}[0].'-'.$layers->{'maxzoom'}[0].' --title \''.$opts{'s'}.' '.$opts{'y'}.'\' --tile-format jpeg --webviewer all '.$c{'filewarp'}.' '.$c{'dirraster'};
    sheller($cmd);
    
}

$uploads = '';
if(exists $c{'composite'}) {
  if(!exists $opts{'m'}) {
    $cmd = $mainconf->{'dirdev'}.'mixer.pl '.$opts{'s'}.' '.$c{'composite'};
    sheller($cmd);

    $compositebbox = $xml->XMLin($c{'dirvector'}.'bbox'.$c{'composite'}.'.kml', ForceArray => 1);
    $c{'bbox'} = $compositebbox->{'Document'}[0]{'ExtendedData'}[0]{'Data'}{'bbox'}{'value'}[0];
    $c{'layeryear'} = $c{'composite'};
    $uploads = $opts{'s'}.'/'.$c{'composite'};
  }
} else {
  $tilemapres = $xml->XMLin($c{'dirraster'}.'/tilemapresource.xml', ForceArray => 1);
  # OpenLayers bounds are in order W,S,E,N
  $c{'bbox'} = $tilemapres->{'BoundingBox'}[0]{'miny'}.','.$tilemapres->{'BoundingBox'}[0]{'minx'}.','.$tilemapres->{'BoundingBox'}[0]{'maxy'}.','.$tilemapres->{'BoundingBox'}[0]{'maxx'};
  $c{'layeryear'} = $opts{'y'};

  $cmd = $mainconf->{'dirdev'}.'postproc.bash '.$opts{'s'}.' '.$opts{'y'};
  sheller($cmd);
  $uploads = $opts{'s'}.'/'.$opts{'y'};
}

$c{'ls'} = scalar(@{$layers->{'layer'}});
$isNewLayer = 1;
for($i = 0; $i < $c{'ls'}; $i++) {
  if($layers->{'layer'}[$i]{'type'} eq 'tms' && $layers->{'layer'}[$i]{'year'} eq $c{'layeryear'}) {
    $layers->{'layer'}[$i]{'bounds'} = $c{'bbox'};
    $isNewLayer = 0;
    break;
  }
}

if($isNewLayer && $c{'layeryear'}) {
  push(@{$layers->{'layer'}}, {'type' => 'tms', 'bounds' => $c{'bbox'}, 'year' => $c{'layeryear'}});
}

$layers->{'json'}[0] = '<![CDATA['.$layers->{'json'}[0].']]>';
$xml->XMLout($layers, RootName => 'vanalinnadlayers', OutputFile => $c{'filelayers'}, NoEscape => 1);

$rss = $c{'dirvector'}.'rss'.$c{'layeryear'}.'.xml';
$crud = 'U';
if(! -e $rss) {
  $crud = 'C';
  if($c{'layeryear'} =~ /^\d{4}[^\d]*$/) {
    $rssdate = $c{'layeryear'};
    $rssdate =~ s/[^\d]*$//;
    $rssdate = 'LC_ALL=en_US.utf8 date -d '.$rssdate.'0101 "+%a, %d %b %Y 00:00:00 +0000"';
    $rssdate = `$rssdate`;
    $rssdate =~ s/\s+$//;
    $cmd = 'cat '.$mainconf->{'dirvector'}.'rsstemplate.xml | sed "s/<pubDate>.*<\/pubDate>/<pubDate>'.$rssdate.'<\/pubDate>/" > '.$rss;
    if($c{'layeryear'}) { sheller($cmd); }
  } else {
    $cmd = 'cp '.$mainconf->{'dirvector'}.'rsstemplate.xml '.$rss;
    if($c{'layeryear'}) { sheller($cmd); }
  }
}

if(!(exists $localdata{'dontlogmaps'} && $localdata{'dontlogmaps'} == 1) && $uploads ne '') {
  use DBI qw(:sql_types);
  $dbh = DBI->connect("dbi:SQLite:dbname=".$mainconf->{'dbloads'},"","");
  $sth = $dbh->prepare("INSERT INTO updates (map,crud,host,time) VALUES (?,?,?,CURRENT_TIMESTAMP)");
  $sth->bind_param(1, $uploads);
  $sth->bind_param(2, $crud);
  $sth->bind_param(3, $localdata{'id'});
  $sth->execute();
  $sth->finish;
  $dbh->disconnect;
}

$uploads =~ s/\//&year=/;
print "\n\nSee @ ".$localdata{'webroot'}."?site=".$uploads."&debug=1&random=".rand()."\n\n";
print "\a";

sub sheller {
 print "\n".$_[0]."\n";
 system($_[0]);
}
