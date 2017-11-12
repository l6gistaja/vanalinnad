#!/usr/bin/perl

use DBI qw(:sql_types);
use JSON;
use XML::Simple;
use lib './dev';
use VlHelper qw(json_file_read json_file_write);

if(scalar(@ARGV) < 1) {
  print "\nUsage: ./dev/jsoncleaner.pl SITE_ID\nDeletes empty tile data of nonexisting year directories.\n";
  exit;
}

$xml = new XML::Simple;
$mainconf= $xml->XMLin('conf.xml');
#use Data::Dumper; print Dumper($mainconf);
%localdata = json_file_read($mainconf->{'dircache'}.$mainconf->{'filelocal'});

$dir = './'.$mainconf->{'dirraster'}.$mainconf->{'dirplaces'}.$ARGV[0];
opendir(DIR, $dir) or die $!;
@y = qw();
while ( $file = readdir(DIR)) {
    # Use a regular expression to ignore files beginning with a period
    next if ($file =~ m/^\./);
    push(@y, $file);
}
closedir(DIR);
print "Existing year directories: '".join("', '",@y)."'\n";

$emptyjson =  $mainconf->{'dirvector'}.$mainconf->{'dirplaces'}.$ARGV[0].'/'.$mainconf->{'fileemptytiles'};
%doc = json_file_read($emptyjson);
$dbh = DBI->connect("dbi:SQLite:dbname=".$mainconf->{'dbloads'},"","");
$sth = $dbh->prepare("INSERT INTO updates (map,crud,host,time) VALUES (?,'D','".$localdata{'id'}."',CURRENT_TIMESTAMP)");
$sthD = $dbh->prepare("DELETE FROM updates WHERE map = ? AND crud <> 'D'");
@d = qw();
foreach $year (keys %doc) {
  if ( !($year ~~ @y) ) {
    push(@d, $year);
    delete $doc{$year};
    $sthD->bind_param(1, $ARGV[0].'/'.$year);
    $sthD->execute();
    $sth->bind_param(1, $ARGV[0].'/'.$year);
    $sth->execute();
  }
}
$sthD->finish;
$sth->finish;
$dbh->disconnect;

if(scalar(@d) > 0) {
  json_file_write($emptyjson, \%doc);
  print "Deleted: '".join("', '",@d)."'\n";
}

exit 0;
