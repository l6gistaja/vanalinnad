#!/usr/bin/perl

@commands = ('echo "Uploding all committed changes and tiles to website"','git push');

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

foreach my $site (@sites) {
    $cachedir = $dbdata{upload_directory}
      .$mainconf->{dircache}
      .uploaddir($site);
    push(@commands, 'ssh '
      .$dbdata{upload_host}.' "rm -rf '
      .$cachedir.' ; mkdir '
      .$cachedir.'"');
    push(@commands, 'scp -r -q '
      .$mainconf->{dirraster}
      .$mainconf->{dirplaces}
      .$site.'/* '
      .$dbdata{upload_host}.':'
      .$cachedir);
}

foreach my $site (@sites) {
    @pieces = split(/\//, $site);
    $rasterdir = $dbdata{upload_directory}
      .$mainconf->{dirraster}
      .$mainconf->{dirplaces}
      .$site;
    push(@commands, 'ssh '
      .$dbdata{upload_host}.' "mkdir '
      .$dbdata{upload_directory}
      .$mainconf->{dirraster}
      .$mainconf->{dirplaces}
      .$pieces[0]
      .' ; rm -rf '
      .$rasterdir.' ; mv '
      .$dbdata{upload_directory}
      .$mainconf->{dircache}
      .uploaddir($site).' '
      .$rasterdir.'"');
}

push(@commands, 'ssh '
      .$dbdata{upload_host}.' "cd '
      .$dbdata{upload_directory}.' ; git pull"');

foreach my $command (@commands) {
    print "\n========================================================\nEXECUTE: $command\n";
    system($command);
}

$sth = $dbh->prepare("DELETE FROM updates");
$sth->execute();

sub uploaddir {
 @pieces = split(/\//, $_[0]);
 unshift(@pieces, 'upload'); 
 return join('_', @pieces);
}