#!/usr/bin/perl

use XML::Simple;
use Getopt::Std;
use Data::Dumper;
use File::Fetch;
use POSIX ();
use File::Path qw(make_path);

$t0 = time();
%self = qw(
    workPath ./cache/dezoomify/
    resultFile iipresult.jpg
    partPrefix column
    zoomifyExt .jpg
);

getopt('u:wproa:b:', \%opts);
if(!exists $opts{'u'}) {
  print <<EndUsage;

Usage: deiip.pl -u ... -a # -b # [-w ...] [-p ...] [-r #] [-o ...]

-u : IIP service tile URL, without tile number in end.
-a : left bottom corner's tile number from URL.
-b : right bottom corner's tile number from URL.
-w : working directory, to which tiles will be downloaded and where result file 
     ($self{resultFile}) will be composed. Optional, default value is '$self{workPath}'.
-p : if exists, only given parts of script will run: 'd' - download, 'm' - merging (already downloaded) tiles.
-r : percentage of tiles resize before final merger (0 < integer < 100).
-o : output file name. Optional, default is '$self{workPath}$self{resultFile}'.

Needs ImageMagick's convert for tile merging and wget for download.

Example: deiip.pl -u 'http://www.ra.ee/fcgi-bin/iipsrv.fcgi?FIF=/mnt/saaga_laiendus/kaardid/eaa0001/002/c-0-ii-0-35/eaa0001_002_c-0-ii-0-35_00001_k.tif&CNT=1&SDS=0,90&JTL=8,' -a 1254 -b 1291

EndUsage
  exit;
}

if($opts{'a'} > $opts{'b'}) { die "\nParameter b cannot be smaller then a!\n\n"; }

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

$self{'x_tiles'} = $opts{'b'} - $opts{'a'} + 1;
$self{'y_tiles'} = ($opts{'b'} + 1) / $self{'x_tiles'};

# DOWNLOAD
if(!exists $opts{'p'} || $opts{'p'} =~ /d/) {

    print "\nDOWNLOADING TILES\n\n";

    $totalSize = 0;

    unlink glob($self{'workPath'}.'i*'.$self{'zoomifyExt'});
    for($x = 0; $x < $opts{'b'} + 1; $x++) {
            $filename = $self{'workPath'}.'i'.$x.$self{'zoomifyExt'};
            system('wget --header="User-Agent: Opera/9.80 (X11; Linux x86_64) Presto/2.12.388 Version/12.16" --header="Host: www.ra.ee" --header="Accept: text/html, application/xml;q=0.9, application/xhtml+xml, image/png, image/webp, image/jpeg, image/gif, image/x-xbitmap, */*;q=0.1" --header="Accept-Language: en-US,en;q=0.9" --header="Accept-Encoding: gzip, deflate" --header="Cache-Control: no-cache" --header="Connection: Keep-Alive" \''.$opts{'u'}.$x.'\' -O '.$filename);
            @fs = stat($filename);
            $totalSize += $fs[7];
    }

    print "Downloaded ".($totalSize >> 20)." MB\n";
}

print "$self{x_tiles} x $self{y_tiles} tiles.\n";
# TILE MERGING
if(!exists $opts{'p'} || $opts{'p'} =~ /m/) {

    print "\nMERGING TILES\n\n";

    $resize = 0;
    if(exists $opts{'r'}) {
      if($opts{'r'} =~ /^[1-9]\d*$/) {
          $resize = 0 + $opts{'r'};
          print "Resizing $opts{r}%.\n";
      } else {
          print "Will not resize, -r flag should be positive integer, not '$opts{r}'!\n";
      }
    }

    print "Composing columns :";
    for($x = 0; $x < $self{'x_tiles'}; $x++) {
        $filename = $self{'workPath'}.$self{'partPrefix'}.$x.$self{'zoomifyExt'};
        $cmd = 'convert';
        for($y = 0; $y < $self{'y_tiles'}; $y++) {
            $cmd .= ' '.$self{'workPath'}.'i'.($x + ($y * $self{'x_tiles'})).$self{'zoomifyExt'};
        }
        print ' '.$x;
        system($cmd.' -append '.$filename);
        if($resize) {
            $fileresize = $self{'workPath'}.$self{'partPrefix'}.'_resize'.$self{'zoomifyExt'};
            system("convert $filename -resize $resize% $fileresize");
            rename($fileresize, $filename);
        }
    }

    $result = $self{'workPath'}.$self{'resultFile'};
    print "\nMerging columns into result image @ $result\n";
    $cmd = 'convert -monitor';
    for($x = 0; $x < $self{'x_tiles'}; $x++) {
        $cmd .= ' '.$self{'workPath'}.$self{'partPrefix'}.$x.$self{'zoomifyExt'};
    }
    system($cmd . ' +append '.$result);
    unlink glob($self{'workPath'}.$self{'partPrefix'}.'*'.$self{'zoomifyExt'});
}

if(exists $opts{'o'}) { system('cp '.$result.' '.$opts{'o'}); }

print "FINISHED! Running time ".(time() - $t0)." seconds.\n";
print "\a";
