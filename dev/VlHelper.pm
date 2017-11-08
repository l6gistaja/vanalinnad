package VlHelper;
 
use Exporter qw(import);
use Storable qw(dclone);
use JSON;

our @EXPORT_OK = qw(minify_empty_tiles_json add_empty_tiles_json bbox_fragment add_to_tree kml_envelope gdal_mapindex gdal_tlast bbox_box bbox_points json_file_read json_file_write);

sub minify_empty_tiles_json {
  %json = %{dclone($_[0])};

  foreach $z (keys %json) {
    foreach $x (keys %{$json{$z}}) {
        # numeric ascending sort
        @a = sort {$a <=> $b} @{$json{$z}{$x}};
        $len = scalar(@a);
        if($len < 3) {
          # clone array, otherwise ref to @a will be copied
          $json{$z}{$x} = dclone(\@a);
        } else {

          @b = qw();
          $begin = 0;

          for($i=1; $i < $len; $i++) {
            if($a[$i] - $a[$i-1] > 1) {
              if($i - $begin > 2) {
                push(@b, [$a[$begin], $a[$i-1]]); 
              } else {
                for($j=$begin; $j < $i; $j++) {
                  push(@b, $a[$j]); 
                }
              }
              $begin = $i;
            }
          }

          if($len-1 - $begin > 2) {
            push(@b, [$a[$begin], $a[$len-1]]); 
          } else {
            for($j=$begin; $j < $len; $j++) {
              push(@b, $a[$j]); 
            }
          }

          $json{$z}{$x} = dclone(\@b);
        }
    }
  }
  return %json;
}

sub add_empty_tiles_json {
  %doc = json_file_read($_[0]);
  $doc{$_[1]} = $_[2];
  json_file_write($_[0], \%doc);
}

sub bbox_fragment {
  $y = "\n";

  if(scalar(@_) > 2) {
      $y .= bbox_box($_[1], $_[2]);
  }

  if(-e $_[0]) {
    $coords = '';
    open(INFO, $_[0]) or die("Could not open file ".$_[0]);
    foreach $line (<INFO>) { if($line =~ /gdal_translate/) { $coords = $line; } }
    close(INFO);
    $y .= bbox_points($coords, $_[1]);
  }

  return $y."\n";
}

sub kml_envelope {
  return <<EndHeader;
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://earth.google.com/kml/2.2">
<Document>
$_[0]
</Document>
</kml>
EndHeader
}

sub bbox_box {
      @c = split(/[,]/, $_[1]);
      return '<Placemark id="bbox'.
        ($_[0] eq '' ? '' : '.'.$_[0]).
        '"><name>'.
        $_[0].
        '</name><LineString><coordinates>'.
        $c[0].','.$c[1].' '.$c[0].','.$c[3].' '.$c[2].','.$c[3].' '.$c[2].','.$c[1].' '.$c[0].','.$c[1].
        "</coordinates></LineString></Placemark>\n";
}

sub bbox_points {
    $ybbp = '';
    $j = 0;
    @c = split(/\s+/, $_[0]);
    for($gi=0; $gi<scalar(@c); $gi++) {
      if($c[$gi] eq '-gcp') {
        $j++;
        $ybbp .= '<Placemark id="gcp'.$_[1].'.'.$j.'"><name>'.
          ($_[1] eq '' ? '' : $_[1].' ').
          '#'.$j.'</name><description>'.$c[1+$gi].' '.$c[2+$gi].'</description><Point><coordinates>'.$c[3+$gi].','.$c[4+$gi]."</coordinates></Point></Placemark>\n";
      }
    }
    return $ybbp;
}

sub add_to_tree {
  $z = ''.$_[0][0];
  $x = ''.$_[0][1];
  if(!exists $_[1]{$z}) { $_[1]{$z} = qw(); }
  if(!exists $_[1]{$z}{$x}) {
    $_[1]{$z}{$x} = [$_[0][2]];
  } else {
    # if not duplicate
    if ( !($_[0][2] ~~ @{$_[1]{$z}{$x}}) ) {
      push(@{$_[1]{$z}{$x}}, $_[0][2]);
    }
  }
}

sub gdal_mapindex {
  $y = -1;
  $ts = scalar(@{$_[0]->{'translate'}});
  for($i = 0; $i < $ts; $i++) {
    if($_[0]->{'translate'}[$i]{'map'} eq $_[1]) {
      $y = $i;
      break;
    }
  }
  return $y;
}

sub gdal_tlast {
  return scalar(@{$_[0]->{'translate'}[$_[1]]{'t'}}) -1;
}

sub json_file_read {
  open(FILE, $_[0]) or die "Can't open file [$!]\n";
  $document = <FILE>;
  close (FILE);
  return %{decode_json($document)};
}

sub json_file_write {
  open(FILE, '>'.$_[0]) or die "Can't open file [$!]\n";
  print FILE encode_json($_[1]);
  close (FILE);
}

1;