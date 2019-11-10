#!/usr/bin/perl

@commands = ('echo "Uploading all commited changes and tiles to website"','git push');

use XML::Simple;
use DBI qw(:sql_types);
use lib './dev';
use VlHelper qw(json_file_read json_file_write);

$xml = new XML::Simple;
$mainconf = $xml->XMLin('conf.xml');
%localdata = json_file_read($mainconf->{'dircache'}.$mainconf->{'filelocal'});
$dbh = DBI->connect("dbi:SQLite:dbname=".$mainconf->{'dbloads'},"","");

%dbdata = qw();
$sth = $dbh->prepare("SELECT * FROM data");
$sth->execute();
while ($row = $sth->fetchrow_hashref) { $dbdata{$row->{k}} = $row->{v}; }
$sth->finish;

@sites = qw();
$sth = $dbh->prepare("SELECT map FROM updates WHERE id > ? AND host = ? AND crud <> 'D' GROUP BY map");
$sth->execute($localdata{'upload'}, $localdata{'id'});
while ($row = $sth->fetchrow_hashref) { if ($row->{map} !~ /sandbox\//) { push(@sites, $row->{map}); } }
$sth->finish;

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
      .$pieces[0].'"');
    push(@commands, 'ssh '
      .$dbdata{upload_host}.' "rm -rf '
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

if(scalar @sites) {
    $sth = $dbh->prepare("SELECT MAX(id) AS mid FROM updates WHERE host = ? AND crud <> 'D'");
    $sth->execute($localdata{'id'});
    $row = $sth->fetchrow_hashref;
    $localdata{'upload'} = $row->{mid};
    $sth->finish;
    json_file_write($mainconf->{'dircache'}.$mainconf->{'filelocal'}, \%localdata);
}

$dbh->disconnect;

sub uploaddir {
 @pieces = split(/\//, $_[0]);
 unshift(@pieces, 'upload'); 
 return join('_', @pieces);
}
