package VlHelper;
 
use Exporter qw(import);
use Storable qw(dclone);
use JSON;

our @EXPORT_OK = qw(minify_empty_tiles_json add_empty_tiles_json bbox_fragment add_to_tree);

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
  open(FILE, $_[0]) or die "Can't read file 'filename' [$!]\n";
  $document = <FILE>;
  close (FILE);

  %doc = %{decode_json($document)};
  $doc{$_[1]} = $_[2];

  open(FILE, '>'.$_[0]) or die "Can't read file 'filename' [$!]\n";
  print FILE encode_json(\%doc);
  close (FILE);
}

sub bbox_fragment {
  $y = "\n";

  if(scalar(@_) > 2) {
      @c = split(/[,]/, $_[2]);
      $y .= '<Placemark id="bbox'.
        ($_[1] eq '' ? '' : '.'.$_[1]).
        '"><name>'.
        $_[1].
        '</name><LineString><coordinates>'.
        $c[0].','.$c[1].' '.$c[0].','.$c[3].' '.$c[2].','.$c[3].' '.$c[2].','.$c[1].' '.$c[0].','.$c[1].
        "</coordinates></LineString></Placemark>\n";
  }

  if(-e $_[0]) {
    @c = qw();
    open(INFO, $_[0]) or die("Could not open file ".$_[0]);
    foreach $line (<INFO>) { if($line =~ /gdal_translate/) { @c = split(/\s+/, $line); } }
    close(INFO);
    if(scalar(@c) > 5) {
      $j = 0;
      for($gi=0; $gi<scalar(@c); $gi++) {
        if($c[$gi] eq '-gcp') {
          $j++;
          $y .= '<Placemark id="gcp'.$_[1].'.'.$j.'"><name>'.
            ($_[1] eq '' ? '' : $_[1].' ').
            '#'.$j.'</name><description>'.$c[1+$gi].' '.$c[2+$gi].'</description><Point><coordinates>'.$c[3+$gi].','.$c[4+$gi]."</coordinates></Point></Placemark>\n";
        }
      }
    }
  }

  return $y."\n";
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

1;