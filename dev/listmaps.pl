#!/usr/bin/perl

print "Write list of all maps to SQLite\n";
use lib './dev';
use VlHelper qw(get_sites);
use Data::Dumper;
use DBI qw(:sql_types);
our $dbh = DBI->connect("dbi:SQLite:dbname=vector/common/vanalinnad_maps/maps.sqlite3","","");
$xml = new XML::Simple;
$mainconf = $xml->XMLin('conf.xml');

@sites = get_sites($mainconf);

$sth = $dbh->prepare("DELETE FROM maps WHERE permanent_record = 'N'");
$sth->execute();
$sth->finish;
$sth = $dbh->prepare("INSERT INTO maps (permanent_record, vl_site, anchor,use,vl_year,year) VALUES (?,?,?,?,?,?)");
our $stupdl = $dbh->prepare("UPDATE maps SET url = ?, uid = ?, title = ?, author = ? WHERE permanent_record = 'N' AND vl_site = ? AND vl_year = ? AND anchor LIKE ?");
foreach my $site (@sites) {
    $gdal = $xml->XMLin($mainconf->{dirvector}.$mainconf->{dirplaces}.$site.'/'.$mainconf->{filegdal});
    #print Dumper($gdal);
    print $site."\n";
    foreach my $map (@{$gdal->{translate}}) {
        $vl_site = $site;
        $vl_year = $year = $anchor = $map->{map};
        $year = substr $year, 0, 4;
        $use = exists($map->{flags}) && $map->{flags} =~ /deleted/ ? 'D' : 'A';
        if(exists($map->{composite})) {
            $vl_year = $map->{composite};
            if(exists($gdal->{composite}->{$vl_year}->{flags}) && $gdal->{composite}->{$vl_year}->{flags} =~ /deleted/) {
                $use = 'D';
            }
        }
        $sth->execute('N',$vl_site,$anchor,$use,$vl_year,$year);
    }
    
    opendir(DIR, $mainconf->{dirvector}.$mainconf->{dirplaces}.$site.'/');
    @files = grep(/^rss.+\.xml$/, readdir(DIR));
    closedir(DIR);
    foreach $file (@files) {
        $rss = $xml->XMLin($mainconf->{dirvector}.$mainconf->{dirplaces}.$site.'/'.$file);
        if(exists($rss->{channel}->{vector})) { next; }
        #print Dumper($rss->{channel}->{item});
        print ref($rss->{channel}->{item})."\n";
        if(ref($rss->{channel}->{item}) eq 'HASH') {
            handle_rss_item(\%{$rss->{channel}->{item}}, $site, substr($file, 3, -4));
        }
    }
}
$sth->finish;
$stupdl->finish;

$dbh->disconnect;

sub handle_rss_item {
    my %item = %{shift()};
    $site = shift();
    $year = shift();
    print Dumper(%item);
    #print Dumper($year);
    #$stupdl = $dbh->prepare("UPDATE maps SET url = ?, uid = ?, title = ?, author = ? WHERE permanent_record = 'N' AND vl_site = ? AND vl_year = ? AND anchor LIKE ?");
    $stupdl->execute(
        ref($item{link}) eq 'ARRAY' ? $item{link}[0] : $item{link},
        exists($item{guid}) ? $item{guid} : '',
        exists($item{title}) ? $item{title} : '',
        exists($item{author}) ? $item{author} : '',
        $site,
        $year,
        (exists($item{anchor}) ? $item{anchor} : substr($item{pubDate}, 12, 4)).'%'
    );
};
