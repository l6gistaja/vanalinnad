#!/usr/bin/perl

use XML::Simple;
use DBI qw(:sql_types);
$xml = new XML::Simple;
$mainconf = $xml->XMLin('conf.xml');
$dbh = DBI->connect("dbi:SQLite:dbname=loads/loads.sqlite","","");

%dbdata = qw();
$sth = $dbh->prepare("SELECT * FROM data");
$sth->execute();
while ($row = $sth->fetchrow_hashref) { $dbdata{$row->{k}} = $row->{v}; }

@sites = qw();
$sth = $dbh->prepare("SELECT map FROM updates WHERE id > ? GROUP BY map");
$sth->execute($dbdata{last_vanalinnad});
while ($row = $sth->fetchrow_hashref) { push(@sites, $row->{map}); }

@commands = ('git push');
foreach my $site (@sites) {
    $cachedir = $dbdata{upload_directory}
      .$mainconf->{dircache}
      .uploaddir($site);
    push(@commands, 'ssh '
      .$dbdata{upload_host}.' "rm -rf '
      .$cachedir.'"');
    push(@commands, 'scp '
      .$mainconf->{dirraster}
      .$mainconf->{dirplaces}
      .$site.' '
      .$dbdata{upload_host}.':'
      .$cachedir);
}

push(@commands, 'ssh '
      .$dbdata{upload_host}.' "cd '
      .$dbdata{upload_directory}.' ; git pull"');

foreach my $site (@sites) {
    $rasterdir = $dbdata{upload_directory}
      .$mainconf->{dirraster}
      .$mainconf->{dirplaces}
      .$site;
    push(@commands, 'ssh '
      .$dbdata{upload_host}.' "rm -rf '
      .$rasterdir.' ; mv '
      .$dbdata{upload_directory}
      .$mainconf->{dircache}
      .uploaddir($site).' '
      .$rasterdir.'"');
}

foreach my $command (@commands) {
    print "\n========================================================\nEXECUTE: $command\n";
    #system($command);
}

$sth = $dbh->prepare("DELETE FROM updates");
$sth->execute();

sub uploaddir {
 @pieces = split(/\//, $_[0]);
 unshift(@pieces, 'upload'); 
 return join('_', @pieces);
}