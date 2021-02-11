#!/usr/bin/perl

use DBI qw(:sql_types);
use JSON;
use XML::Simple;
use lib './dev';
use VlHelper qw(json_file_read json_file_write);

if(scalar(@ARGV) < 1) {
  print "\nUsage: ./dev/jsoncleaner.pl SITE_ID\nDeletes empty tile data of nonexisting year directories. \nIf SITE_ID value is dot (.), all lately changed sites will be cleansed.\n\n";
  exit;
}

$xml = new XML::Simple;
$mainconf= $xml->XMLin('conf.xml');
#use Data::Dumper; print Dumper($mainconf);
%localdata = json_file_read($mainconf->{'dircache'}.$mainconf->{'filelocal'});
$dbh = DBI->connect("dbi:SQLite:dbname=".$mainconf->{'dbloads'},"","");
$sth = $dbh->prepare("INSERT INTO updates (map,crud,host,time) VALUES (?,'D','".$localdata{'id'}."',CURRENT_TIMESTAMP)");
$sthD = $dbh->prepare("DELETE FROM updates WHERE map = ? AND crud <> 'D'");
$sthS = $dbh->prepare("SELECT map FROM updates WHERE id > ".$localdata{'upload'}." GROUP BY map");

@sites = ();
if($ARGV[0] eq '.') {
    $sthS->execute();
    while(($year) = $sthS->fetchrow()) {
        @pieces = split /\//, $year;
        if(!($pieces[0] ~~ @sites)) { push(@sites, $pieces[0]); }
    }
} else { push(@sites, $ARGV[0]); }

foreach (@sites)
{
    $dir = './'.$mainconf->{'dirraster'}.$mainconf->{'dirplaces'}.$_;
    opendir(DIR, $dir) or die $!;
    @y = qw();
    while ( $file = readdir(DIR)) {
        # Use a regular expression to ignore files beginning with a period
        next if ($file =~ m/^\./);
        push(@y, $file);
    }
    closedir(DIR);
    print "Existing year directories: '".join("', '",@y)."'\n";

    $emptyjson =  $mainconf->{'dirvector'}.$mainconf->{'dirplaces'}.$_.'/'.$mainconf->{'fileemptytiles'};
    %doc = json_file_read($emptyjson);
    @d = qw();
    foreach $year (keys %doc) {
        if ( !($year ~~ @y) ) {
            push(@d, $year);
            delete $doc{$year};
            $sthD->bind_param(1, $_.'/'.$year);
            $sthD->execute();
            $sth->bind_param(1, $_.'/'.$year);
            $sth->execute();
        }
    }
}

$sthS->finish;
$sthD->finish;
$sth->finish;
$dbh->disconnect;

if(scalar(@d) > 0) {
  json_file_write($emptyjson, \%doc);
  print "Deleted: '".join("', '",@d)."'\n";
}

# those things dont belong here, but as it is cleanup script, and whole codebase is buggy...
system 'rm '.$mainconf->{'dirvector'}.$mainconf->{'dirplaces'}.$ARGV[0].'/bbox.kml';
system 'rm '.$mainconf->{'dirvector'}.$mainconf->{'dirplaces'}.$ARGV[0].'/rss.xml';
system 'find '.$mainconf->{'dirvector'}.$mainconf->{'dirplaces'}.' -name "rss*.xml" -exec sed -f '.$mainconf->{'dirdev'}.'clean_rss.sed -i {} \;';

exit 0;
