#!/usr/bin/perl

@commands = (
    'echo "Uploading all commited changes and tiles to website"',
    'echo "Usage: dev/uploader.pl (-d) (-i) (-u)"',
    'echo "  -d - dry run (dont write anything anywhere)"',
    'echo "  -i - instead uploading all maps and moving them afterwards, move each map immediately after upload"',
    'echo "  -u - dont upload maps"',
    'git push'
);

use XML::Simple;
use DBI qw(:sql_types);
use lib './dev';
use VlHelper qw(json_file_read json_file_write);
use Getopt::Std;

getopts('diu', \%opts);
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
@towns = qw();
$sth = $dbh->prepare("SELECT map FROM updates WHERE id > ? AND host = ? AND crud <> 'D' GROUP BY map");
$sth->execute($localdata{'upload'}, $localdata{'id'});
while ($row = $sth->fetchrow_hashref) { if ($row->{map} !~ /sandbox\//) { push(@sites, $row->{map}); } }
$sth->finish;

if(!exists $opts{'u'}) {
    foreach my $site (@sites) {
        @pp = split(/\//, $site);
        $cachedir = $dbdata{upload_directory}
            .$mainconf->{dircache}
            .uploaddir($site);
        $command = 'ssh '
            .$dbdata{upload_host}.' "rm -rf '
            .$cachedir.' ; mkdir '
            .$cachedir;
        if(!($pp[0] ~~ @towns)) {
            $command .= '; mkdir '
                .$dbdata{upload_directory}
                .$mainconf->{dirraster}
                .$mainconf->{dirplaces}
                .$pp[0];
            push(@towns, $pp[0]);
        }
        $command .= '"';
        push(@commands, $command);
        push(@commands, 'scp -r -q '
            .$mainconf->{dirraster}
            .$mainconf->{dirplaces}
            .$site.'/* '
            .$dbdata{upload_host}.':'
            .$cachedir);
        if(exists $opts{'i'}) { push(@commands, moveupload($site)); }
    }
    if(!exists $opts{'i'}) { foreach my $site (@sites) { push(@commands, moveupload($site)); } }
}

push(@commands, 'ssh '
      .$dbdata{upload_host}.' "cd '
      .$dbdata{upload_directory}.' ; git pull"');

foreach my $command (@commands) {
    print "\n##### EXECUTE:\n$command\n";
    if(!exists $opts{'d'}) { system($command); }
}

if(exists $opts{'d'} || exists $opts{'u'}) {
    $dbh->disconnect;
    exit;
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

sub moveupload {
    $rasterdir = $dbdata{upload_directory}
      .$mainconf->{dirraster}
      .$mainconf->{dirplaces}
      .$_[0];
    return 'ssh '.$dbdata{upload_host}.' "rm -rf '
      .$rasterdir.' ; mv '
      .$dbdata{upload_directory}
      .$mainconf->{dircache}
      .uploaddir($_[0]).' '
      .$rasterdir.'"';
}
