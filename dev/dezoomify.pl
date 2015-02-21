#!/usr/bin/perl

use XML::Simple;
use Getopt::Std;
use Data::Dumper;
use File::Fetch;
use POSIX ();
use File::Path qw(make_path);

%self = qw(workPath ./cache/dezoomify/ resultFile result.jpg zoomifyXML ImageProperties.xml zoomifyExt .jpg downloadLock downloadlock.xml tileFile tiles.txt partPrefix c);

getopt('u:wsz', \%opts);
if(!exists $opts{'u'}) {
  print <<EndUsage;
Usage: dezoomify.pl -u ... [-w ...] [-s] [-z ...]

-u : on webpage, which contains Zoomify applet, open page source. URL for -u can be copied from variable zoomifyImagePath.
-w : working directory, to which Zoomify tiles will be downloaded and where result file ($self{resultFile}) will be composed.
     Optional, default value is '$self{workPath}'.
-s : show statistics instead processing, useful for finding appropriate zoom level (-z flag).
-z : zoom level number, see -s flag. Default: maximum zoom.
Translated to Perl from dezoomify 1.4's dezoomify.py, comments with beginning ## are from there.
See: http://sourceforge.net/projects/dezoomify/
Dependency: ImageMagick's convert.
NB! Maximum zoomlevel might not be reasonable choice, as machine might run out of memory while trying to merge very large tilesets.
EndUsage
  exit;
}

$self{'zoomifyURL'} = $opts{'u'};
if(exists $opts{'w'}) { $self{'workPath'} = $opts{'w'}; }

if (-d $self{'workPath'}) {
    if (!(-w $self{'workPath'})) {
        die "Working directory $self{workPath} is not a writable directory!";
    }
}
elsif (-e $self{'workPath'}) {
    die "Working directory $self{workPath} exists but is not a directory!";
}
else {
    make_path($self{'workPath'});
    if (!(-e $self{'workPath'})) {
        die "Error occured while creating $self{workPath}!";
    }
}

unlink($self{'workPath'}.$self{'zoomifyXML'});
$ff = File::Fetch->new(uri => $self{'zoomifyURL'}.$self{'zoomifyXML'});
$where = $ff->fetch('to' => $self{'workPath'}) or die $ff->error;

$xml = new XML::Simple;
$zoomifyXML = $xml->XMLin($self{'workPath'}.$self{'zoomifyXML'}, ForceArray => 1);

$self{'max_width'} = 0 + $zoomifyXML->{'WIDTH'};
$self{'max_height'} = 0 + $zoomifyXML->{'HEIGHT'};
$self{'tile_size'} = $zoomifyXML->{'TILESIZE'};

## Construct a list of all zoomlevels with sizes in tiles
$loc_width = $self{'max_width'};
$loc_height = $self{'max_height'};
@levels = qw();
while(true) {
    $width_in_tiles = POSIX::ceil($loc_width / $self{'tile_size'});
    $height_in_tiles = POSIX::ceil($loc_height / $self{'tile_size'});
    push(@levels, [$width_in_tiles, $height_in_tiles]);
    if ($width_in_tiles == 1 && $height_in_tiles == 1) { last; }
    $loc_width = POSIX::ceil($loc_width / 2);
    $loc_height = POSIX::ceil($loc_height / 2);
}
## make the 0th level the smallest zoom, and higher levels, higher zoom
@levels = reverse(@levels);

# TODO: here, only max zoom is supported
# original dezoomify.py allows user to specify desired zoomlevel
$self{'max_zoom'} = scalar(@levels) - 1;
$show_stats = exists $opts{'s'};
if(exists $opts{'z'}) {
    $self{'zoom_level'} = POSIX::floor(0 + $opts{'z'});
    if($self{'zoom_level'} < 0 || $self{'zoom_level'} > $self{'max_zoom'}) {
        print "-z flag out of range ($self{zoom_level})!\n";
        $show_stats = 1;
    }
} else {
    $self{'zoom_level'} = $self{'max_zoom'};
}

if($show_stats) {
    print "\nSTATISTICS\n\nTile size $self{tile_size} x $self{tile_size} px\n";
    for($i = 0; $i < scalar(@levels); $i++) {
        print "Zoom level $i : ".(POSIX::ceil($self{'max_width'}  / 2 ** ($self{'max_zoom'} - $i))).' x '.(POSIX::ceil($self{'max_height'} / 2 ** ($self{'max_zoom'} - $i))).' px, '.$levels[$i][0].' x '.$levels[$i][1]." tiles\n";
    }
    exit;
}

## GET THE SIZE AT THE REQUESTED ZOOM LEVEL
$self{'width'}  = 0 + POSIX::ceil($self{'max_width'}  / 2 ** ($self{'max_zoom'} - $self{'zoom_level'}));
$self{'height'} = 0 + POSIX::ceil($self{'max_height'} / 2 ** ($self{'max_zoom'} - $self{'zoom_level'}));

## GET THE NUMBER OF TILES AT THE REQUESTED ZOOM LEVEL
$self{'maxx_tiles'} = 0 + $levels[scalar(@levels) - 1][0];
$self{'maxy_tiles'} = 0 + $levels[scalar(@levels) - 1][1];
$self{'x_tiles'} = 0 + $levels[$self{'zoom_level'}][0];
$self{'y_tiles'} = 0 + $levels[$self{'zoom_level'}][1];

$levelIndexIncrement = 0;
for($i = 0; $i < $self{'zoom_level'}; $i++) {
    $levelIndexIncrement += POSIX::ceil(POSIX::floor($self{'width'} / 2 ** ($self{'max_zoom'} - $i)) / $self{'tile_size'}) *
              POSIX::ceil(POSIX::floor($self{'height'} / 2 ** ($self{'max_zoom'} - $i)) / $self{'tile_size'});
}

# download
unlink glob($self{'workPath'}.'*-*'.$self{'zoomifyExt'});
for($x = 0; $x < $self{'x_tiles'}; $x++) {
    for($y = 0; $y < $self{'y_tiles'}; $y++) {
        $tile_index = $x + $y * POSIX::ceil(POSIX::floor($self{'width'} / 2 ** ($self{'max_zoom'} - $self{'zoom_level'})) / $self{'tile_size'});
        $tile_index = POSIX::floor(($tile_index + $levelIndexIncrement) / $self{'tile_size'});
        ## Return the full URL of an image at a given position in the Zoomify structure.
        $filename = $self{'zoom_level'}.'-'.$x.'-'.$y.$self{'zoomifyExt'};
        $url = $self{'zoomifyURL'}.'TileGroup'.$tile_index.'/'.$filename;
        print $url."\n";
        $ff = File::Fetch->new(uri => $url);
        $where = $ff->fetch('to' => $self{'workPath'}) or die $ff->error;
        rename($self{'workPath'}.$filename, $self{'workPath'}.$x.'-'.$y.$self{'zoomifyExt'});
    }
}

$xml->XMLout(\%self, RootName => 'dezoomifyvars', OutputFile => $self{'workPath'}.$self{'downloadLock'});

print "Composing columns :";
for($x = 0; $x < $self{'x_tiles'}; $x++) {
    $cmd = 'convert';
    for($y = 0; $y < $self{'y_tiles'}; $y++) {
        $cmd .= ' '.$self{'workPath'}.$x.'-'.$y.$self{'zoomifyExt'};
    }
    print ' '.$x;
    system($cmd . ' -append '.$self{'workPath'}.$self{'partPrefix'}.$x.$self{'zoomifyExt'});
}

$result = $self{'workPath'}.$self{'resultFile'};
print "\nMerging columns into result image @ $result\n";
$cmd = 'convert';
for($x = 0; $x < $self{'x_tiles'}; $x++) {
    $cmd .= ' '.$self{'workPath'}.$self{'partPrefix'}.$x.$self{'zoomifyExt'};
}
system($cmd . ' +append '.$result);
unlink glob($self{'workPath'}.$self{'partPrefix'}.'*'.$self{'zoomifyExt'});
