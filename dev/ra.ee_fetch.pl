#!/usr/bin/perl

if(scalar(@ARGV) < 1) {
  print "\nUsage: dev/ra.ee_fetch.pl ID\n\n";
  exit;
}

use File::Fetch;
use Data::Dumper;
use lib './dev';
use VlHelper qw(rss_date);

$data = '';
%a = qw();
$a{'url'} = 'http://www.ra.ee/kaardid/index.php/et/map/view?id='.$ARGV[0];
$ff = File::Fetch->new(uri => $a{'url'});
$where = $ff->fetch('to' => \$data) or die $ff->error;
$authortable = 0;
foreach ( split "\n", $data ) {
    $a{'title'} = $1 if $_ =~ /<th>Pealkiri<\/th><td>([^<]+)<\/td>/;
    $a{'uid'} = 'ra.ee='.$1 if $_ =~ /<th>Leidandmed<\/th><td><span[^>]+>([^<]+)<\/span>/;
    $a{'year'} = $1 if $_ =~ /<th>Koostamisaeg<\/th><td>([^<]+)<\/td>/;
    if($authortable) {
        if($_ =~ /<tr>/) {
            $authorrow++;
            $authorcell = 0;
            next;
        }
        if($authorrow < 1) { next; }
        if($_ =~ /<td>([^<]+)<\/td>/ && $authorcell < 2) {
            if($authorcell eq 0) {
                if($authorrow == 1) { $a{'author'} = $1; } else { $a{'author'} .= ', '.$1; }
            } else {
                $a{'author'} .= " ".$1;
            }
            $authorcell++;
        }
        if($_ =~ /<\/table>/) { $authortable = 0; }
    } else {
        if($_ =~ /<th>Eesnimi<\/th>/) {
            $authortable = 1;
            $authorrow = 0;
        }
    }
}

$where = "WHERE url = '".$a{'url'}."' OR uid = '".$a{'uid'}."';";
$update = '';
$insert_fields = '';
$insert_values = '';
foreach $field (keys %a) {
    $escaped = $a{$field} =~ s/'/\\'/gr;
    $update .= ($update eq '' ? '' : ', ').$field." = '".$escaped."'";
    $insert_fields .= ', '.$field;
    $insert_values .= ", '".$escaped."'";
}
$rssdate = rss_date(substr $a{'year'}, 0, 4);

print <<EOF;

-- SQL

SELECT * FROM maps $where

UPDATE maps SET $update $where

INSERT INTO maps (permanent_record, vl_site, vl_year, use$insert_fields) VALUES ('Y','',NULL,'C'$insert_values);

<!-- RSS -->

<item>
<title>$a{title}</title>
<author>$a{author}</author>
<guid>$a{uid}</guid>
<link>$a{url}</link>
<pubDate>$rssdate</pubDate>
</item>
EOF
