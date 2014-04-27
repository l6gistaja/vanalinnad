#!/usr/bin/perl

use Storable qw(dclone);
%json = qw();

open(INFO, $ARGV[0]) or die("Could not open file.");

foreach $line (<INFO>)  {
  $line =~ s/\.[a-z]+\s*$//i;
  @coords = split(/\//,$line);
  $z = ''.$coords[-3];
  if(!exists $json{$z}) { $json{$z} = qw(); }
  $x = ''.$coords[-2];
  $y = 0 + $coords[-1];
  if(!exists $json{$z}{$x}) {
    $json{$z}{$x} = [$y];
  } else {
    # if not duplicate
    if ( !($y ~~ @{$json{$z}{$x}}) ) {
      push(@{$json{$z}{$x}}, $y);
    }
  }
}

close(INFO);

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

use JSON;
#print encode_json(\%json);

open(FILE, $ARGV[1]) or die "Can't read file 'filename' [$!]\n";
$document = <FILE>;
close (FILE);

%doc = %{decode_json($document)};
$doc{"".$coords[-4]} = \%json;

open(FILE, '>'.$ARGV[1]) or die "Can't read file 'filename' [$!]\n";
print FILE encode_json(\%doc);
close (FILE);
