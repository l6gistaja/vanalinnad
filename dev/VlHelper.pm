package VlHelper;
 
use Exporter qw(import);
use JSON;
use Scalar::Util qw(reftype);
use Storable qw(dclone);
use XML::Simple;
use Data::Dumper;

our @EXPORT_OK = qw(minify_empty_tiles_json minify_empty_tiles_json_v2 add_empty_tiles_json bbox_fragment add_to_tree kml_envelope gdal_mapindex gdal_tlast bbox_box bbox_points json_file_read json_file_write get_sites get_bbox_from_layers);

sub minify_empty_tiles_json {
  %json = %{dclone($_[0])};
  #json_file_write('/var/www/html/vanalinnad/cache/emptypaldiski.json', \%doc);
  print Dumper(%doc);
  
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

sub minify_empty_tiles_json_v2 {

    $nil = -1;
    $bbox = 'R';
    %v1 = %{$_[0]};
    %v2 = qw();
    %index = qw();
    %ranges = qw();

    foreach $year (keys %v1) {
	$v2{$year} = {};
	foreach $zoom (keys %{$v1{$year}}) {
	    $v2{$year}{$zoom}{''.$bbox} = [$nil,$nil,$nil,$nil];
	    foreach $lon (keys %{$v1{$year}{$zoom}}) {
		$l = 0 + $lon;
		if($v2{$year}{$zoom}{''.$bbox}[0] == $nil || $l < $v2{$year}{$zoom}{''.$bbox}[0]) { $v2{$year}{$zoom}{''.$bbox}[0] = $l; }
		if($v2{$year}{$zoom}{''.$bbox}[1] == $nil || $l > $v2{$year}{$zoom}{''.$bbox}[1]) { $v2{$year}{$zoom}{''.$bbox}[1] = $l; }
		$l = reftype($v1{$year}{$zoom}{$lon}[0]) eq 'ARRAY' ? $v1{$year}{$zoom}{$lon}[0][0] : $v1{$year}{$zoom}{$lon}[0];
		if($v2{$year}{$zoom}{''.$bbox}[2] == $nil || $l < $v2{$year}{$zoom}{''.$bbox}[2]) { $v2{$year}{$zoom}{''.$bbox}[2] = $l; }
		$l = scalar(@{$v1{$year}{$zoom}{$lon}}) - 1;
		$l = reftype($v1{$year}{$zoom}{$lon}[$l]) eq 'ARRAY' ? $v1{$year}{$zoom}{$lon}[$l][1] : $v1{$year}{$zoom}{$lon}[$l];
		if($v2{$year}{$zoom}{''.$bbox}[3] == $nil || $l > $v2{$year}{$zoom}{''.$bbox}[3]) { $v2{$year}{$zoom}{''.$bbox}[3] = $l; }
		$unique_key = "$year/$zoom".encode_json($v1{$year}{$zoom}{$lon});
		$l = $nil;
		if(exists $ranges{$unique_key}) {
		    $l = $ranges{$unique_key};
		} else {
		    $ranges{$unique_key} = $lon;
		}
		$index{"$year/$zoom/$lon"} = $l;
	    }
	    $v2{$year}{$zoom}{''.$bbox}[1] = $v2{$year}{$zoom}{''.$bbox}[1] - $v2{$year}{$zoom}{''.$bbox}[0];
	    $v2{$year}{$zoom}{''.$bbox}[3] = $v2{$year}{$zoom}{''.$bbox}[3] - $v2{$year}{$zoom}{''.$bbox}[2];
	}
    }

    foreach $lon (keys %index) {
	@long = split(/\//, $lon);
	$x = $v2{$long[0]}{$long[1]}{''.$bbox}[0];
	$y = $v2{$long[0]}{$long[1]}{''.$bbox}[2];
	if($index{$lon} == $nil) {
	    @data = @{dclone($v1{$long[0]}{$long[1]}{$long[2]})};
	    foreach($i = 0; $i < scalar(@data); $i++) {
		$data[$i] = reftype($data[$i]) eq 'ARRAY' ? [$data[$i][0] - $y, $data[$i][1] - $y] : $data[$i] - $y;
	    }
	    $v2{$long[0]}{$long[1]}{''.($long[2] - $x)} = [@data];
	} else {
	  $v2{$long[0]}{$long[1]}{''.($long[2] - $x)} = $index{$lon} - $x;
	}
    }
    
    return %v2;
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
  open(FILE, $_[0]) or die "Can't open file '".$_[0]."' for reading: $!\n";
  $document = <FILE>;
  close (FILE);
  return %{decode_json($document)};
}

sub json_file_write {
  open(FILE, '>'.$_[0]) or die "Can't open file '".$_[0]."' for writing: $!\n";
  print FILE encode_json($_[1]);
  close (FILE);
}

sub get_sites {
    @sites = ();
    $xml = new XML::Simple;
    $sitekml = $xml->XMLin($_[0]->{dirvector}.$_[0]->{fileareaselector});
    foreach $site (keys %{$sitekml->{Document}->{Placemark}}) {
        push(@sites, exists $sitekml->{Document}->{Placemark}->{$site}->{description}
        ? $sitekml->{Document}->{Placemark}->{$site}->{description} : $site);
    }
    return @sites;
}

sub get_bbox_from_layers {
    $layers = $_[0];
    $len = scalar(@{$layers->{'layer'}});
    @max = qw(181 91 -181 -91);
    for($i=0; $i<=$len; $i++) {
    if($layers->{'layer'}[$i]{'type'} eq 'tms') {
        @c = split(/[,\s]/, $layers->{'layer'}[$i]{'bounds'});
        if($c[0] < $max[0]) { $max[0] = $c[0]; }
        if($c[1] < $max[1]) { $max[1] = $c[1]; }
        if($c[2] > $max[2]) { $max[2] = $c[2]; }
        if($c[3] > $max[3]) { $max[3] = $c[3]; }
    }
    }

    if(exists $layers->{'roadbounds'}) {
        if(exists $layers->{'roadbounds'}{'n'}) {$max[3] = $layers->{'roadbounds'}{'n'};}
        if(exists $layers->{'roadbounds'}{'e'}) {$max[2] = $layers->{'roadbounds'}{'e'};}
        if(exists $layers->{'roadbounds'}{'s'}) {$max[1] = $layers->{'roadbounds'}{'s'};}
        if(exists $layers->{'roadbounds'}{'w'}) {$max[0] = $layers->{'roadbounds'}{'w'};}
    }
    return @max;
}

1;
