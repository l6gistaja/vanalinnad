#!/usr/bin/perl

print "Write list of all maps to SQLite\n";
use lib './dev';
use VlHelper qw(get_sites);
use Data::Dumper;
use DBI qw(:sql_types);
use POSIX;
use Digest::MD5 qw(md5_hex);
$dir = 'vector/common/vanalinnad_maps/';
our $dbh = DBI->connect("dbi:SQLite:dbname=".$dir."maps.sqlite3","","");
$xml = new XML::Simple;
$mainconf = $xml->XMLin('conf.xml');
@sites = get_sites($mainconf);

%statuses = qw();
$sth = $dbh->prepare("SELECT enum, name FROM enums WHERE column = 'maps.use'");
$sth->execute();
while(($enum, $name) = $sth->fetchrow()) { $statuses{$enum} = $name; }
$sth->finish;

$sth = $dbh->prepare("DELETE FROM maps WHERE permanent_record = 'N'");
$sth->execute();
$sth->finish;

our $sth = $dbh->prepare("INSERT INTO maps (permanent_record, vl_site, anchor, use, vl_year, year, url, uid, title, author) VALUES (?,?,?,?,?,?,?,?,?,?)");
foreach my $site (@sites) {
    print $site."\n";
    
    $layers = $xml->XMLin($mainconf->{dirvector}.$mainconf->{dirplaces}.$site.'/'.$mainconf->{filelayers});
    #print Dumper($layers);
    our @years = qw();
    foreach $layer (@{$layers->{layer}}) { if($layer->{type} eq 'tms') { push(@years, $layer->{year}); } }
    #print Dumper(@years);
    
    opendir(DIR, $mainconf->{dirvector}.$mainconf->{dirplaces}.$site.'/');
    @files = grep(/^rss.+\.xml$/, readdir(DIR));
    closedir(DIR);
    foreach $file (@files) {
        $rss = $xml->XMLin($mainconf->{dirvector}.$mainconf->{dirplaces}.$site.'/'.$file);
        if(exists($rss->{channel}->{vector})) { next; }
        $year = substr($file, 3, -4);
        if(ref($rss->{channel}->{item}) eq 'HASH') {
            handle_rss_item(\%{$rss->{channel}->{item}}, $site, $year);
        } else {
            foreach $item (@{$rss->{channel}->{item}}) { handle_rss_item(\%{$item}, $site, $year); }
        }
    }
}
$sth->finish;


$sth = $dbh->prepare("SELECT vl_site, vl_year, year, anchor, use, url, uid, title, author FROM maps ORDER BY vl_site, year");
$sth->execute(); 
open(CSV, '>', $dir.'maps.csv') or die $!;
print CSV "\xEF\xBB\xBFvl_site;vl_year;year;use;url;uid;title;author;anchor\n";
open(HTML, '>', $dir.'index.html') or die $!;
$header =<<'HTML_HEADER';
<!DOCTYPE html>
<html>
  <head>
    <title>Vanalinnad maps</title>
    <meta http-equiv=Content-Type content="text/html; charset=UTF-8">
    <style>
table, td, th {
  border: 1px solid black;
  border-collapse: collapse;
  border-color: black;
  border-spacing: 5px;
}

td, th { 
    padding: 10px;
    vertical-align: top;
}
    </style>
  </head>
  <body>
    Following data is also available in <a href="maps.csv">CSV</a> and <a href="maps.sqlite3">SQLite</a> formats. Updated @ %s.<br/><pre>
    Status diagram: Candidate → Published
                        ↓           ↓
                    Unsuitable   Deleted</pre>
    <table>
        <tr>
            <th>#</th>
            <th>Site</th>
            <th>Map</th>
            <th>Year</th>
            <th>Status</th>
            <th>Title</th>
            <th>Author</th>
            <th>UID</th>
        </tr>
HTML_HEADER
print HTML sprintf($header, strftime "%F %T", localtime time);
$i = 1;
while(($vl_site, $vl_year, $year, $anchor, $use, $url, $uid, $title, $author) = $sth->fetchrow()){
   $anchor = md5_hex(join('~', $vl_site, $vl_year, $year, $uid, $anchor));
   print CSV get_csv_line(($vl_site, $vl_year, $year, $use, $url, $uid, $title, $author, $anchor));
   print HTML
    '<tr>'
    .'<td><a href="#'.$anchor.'">'.$i.'</a></td>'
    .'<td><a name="'.$anchor.'">'.$vl_site.'</a></td>'
    .'<td>'.($use eq 'P' ? '<a target="_blank" href="http://vanalinnad.mooo.com/info.html?site='.$vl_site.'&year='.$vl_year.'#map.'.$anchor.'">'.$vl_year.'</a>' : $vl_year).'</td>'
    .'<td><a target="_blank" href="'.$url.'">'.$year.'</a></td>'
    .'<td>'.$statuses{$use}.'</td>'
    .'<td>'.$title.'</td>'
    .'<td>'.$author.'</td>'
    .'<td>'.$uid.'</td>'
    ."</tr>\n";
    $i++;
}

close(CSV);
print HTML <<'HTML_FOOTER';
        <tr>
            <th>#</th>
            <th>Site</th>
            <th>Map</th>
            <th>Year</th>
            <th>Status</th>
            <th>Title</th>
            <th>Author</th>
            <th>UID</th>
        </tr>
    </table>
  </body>
</html>    
HTML_FOOTER
close(HTML);
$sth->finish;

$dbh->disconnect;

sub get_csv_line {
    my $csv = '';
    foreach my $v (@_) {
        $v =~ s/"/""/g;
        $csv .= '"'.$v.'";';
    }
    return $csv."\n";
}

sub handle_rss_item {
    my %item = %{shift()};
    $site = shift();
    $year = shift();
    $anchor = (exists($item{anchor}) ? $item{anchor} : substr($item{pubDate}, 12, 4));
    $sth->execute(
        'N',
        $site,
        $anchor,
        exists($item{deleted}) || !($year ~~ @years)  ? 'D' : 'P',
        $year,
        substr($anchor, 0, 4),
        ref($item{link}) eq 'ARRAY' ? $item{link}[0] : $item{link},
        exists($item{guid}) ? $item{guid} : '',
        exists($item{title}) ? $item{title} : '',
        exists($item{author}) ? $item{author} : ''
    );
};
