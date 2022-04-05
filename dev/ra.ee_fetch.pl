#!/usr/bin/perl

use Storable qw(dclone);
use DBI qw(:sql_types);
use Getopt::Std;
use File::Fetch;
use Data::Dumper;
use lib './dev';
use VlHelper qw(rss_date);

getopt('s:i:o:f:wtd', \%opts);

if(!(exists $opts{'i'}) && !(exists $opts{'f'})) {
    print <<EOF;

Usage: dev/ra.ee_fetch.pl -s SITE [ -i ID | -f FILENAME ]  ...

Possible flags:

-f FILENAME : file containing IDs, separated by newline
-i ID : ID is integer or in format ABC1234_1234_1234_1234, for example lva6828_004_0000524_00002
-o # : if ID is in format ABC1234_1234_1234_1234, remove # parts from beginning
-s SITE
-t : test mode: dont load main page
-w : write to database
-d : delete from database (mark nonpermanent)

EOF
  exit;
}

@ids = qw();
if(exists $opts{'f'}) {
    open $handle, '<', $opts{'f'};
    chomp(@ids = <$handle>);
    close $handle;
}
if(exists $opts{'i'}) { push @ids, $opts{'i'}; }
print "\nIDs : ".join(',',@ids);

our $dbh = DBI->connect("dbi:SQLite:dbname=vector/common/vanalinnad_maps/maps.sqlite3","","");
@id_mem = [];

foreach $id ( @ids ) {

    print "\n\n################## ID $id ##################\n\n";
    $orig_id = $id;

    if($id !~ /^\d+$/) {
        @aa = split('_', $id);
        if(exists $opts{'o'}) { for($i = 0; $i < 0 + $opts{'o'}; $i++) { shift @aa; } }
        $aa[0] =~ /^([a-z]+)([-\d]+)$/i;
        unshift(@aa, uc($1));
        $aa[1] = $2;
        if($aa[0] eq 'LVA') { $aa[0] = 'LVVA'; }
        if($aa[0] =~ /^(E[AR]A)([RT])/) {
            $aa[0] = $1;
            $aa[1] = $2.$aa[1];
        }
        @params = qw(archive fond inventory item sheet);
        $url = 'https://www.ra.ee/kaardid/index.php/et/map/searchAdvanced?';
        $len = scalar(@aa) > 5 ? 5 : scalar(@aa);
        for($i = 0; $i < $len; $i++) {
            if($i > 4) { break; }
            $val = $aa[$i];
            $val =~ s/^0+//;
            $val =~ s/^([RT])0-/$1-/;
            if($val eq '') { next; }
            $url .= '&'.$params[$i].'='.$val;
        }
        print "\n\nSearch: ".$url."\n\n";
        $ff = File::Fetch->new(uri => $url);
        $where = $ff->fetch('to' => \$data) or print $ff->error;
        $id = '';
        foreach ( split "\n", $data ) {
            if ($_ =~ /href="\/kaardid\/index\.php\/et\/map\/view\?id=(\d+)\&/) {
                $id = $1;
                break;
            }
        }
    }
    
    if($id eq '') { print "Empty ID!\n"; next; }
    if($id ~~ @id_mem) { print "ID $id already read!\n"; next; } else { push @id_mem, $id; }
    if(exists $opts{'t'}) { print "Test: dont load main page.\n"; next; }
    %a = qw();
    $a{'url'} = 'http://www.ra.ee/kaardid/index.php/et/map/view?id='.$id;
    $ff = File::Fetch->new(uri => $a{'url'});
    $where = $ff->fetch('to' => \$data) or print $ff->error;
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
    
     print "FETCHED ITEM:\n\n".rss_item(\%aa);

    $where = "WHERE url = '".$a{'url'}."' OR uid = '".$a{'uid'}."';";
    $select = 'SELECT * FROM maps '.$where;
    $sth = $dbh->prepare($select);
    $sth->execute;
    $printout = '';
    $printouts = 0;
    while($res = $sth->fetchrow_hashref)  {
        $printouts++;
        $printout .= "\n".rss_item($res);
    }
    $sth->finish();
    if($printouts > 0) { print "\nFOUND $printouts SIMILAR ITEMS IN DATABASE:\n$printout"; }
    
    if( exists $a{'year'} && !($a{'year'} =~ /^\d{4}$/) ) {
        print "Year in strange format: ".$a{'year'};
        $status = prompt_select('0) Dont change year 1) Truncate year to 4 digits 2) Take year from filename 3) Input year manually','0,1,2,3');
        if($status eq '1') { $a{'year'} = substr $a{'year'}, 0, 4; }
        if($status eq '2') {
            @pieces = split('_', $orig_id);
            $a{'year'} = substr $pieces[0], -4;
        }
        if($status eq '3') {
            print "\nInput year: ";
            $a{'year'} = <STDIN>;
            chomp $a{'year'};
        }
    }
    $update = '';
    $insert_fields = '';
    $insert_values = '';
    foreach $field (keys %a) {
        $escaped = $a{$field} =~ s/'/\\'/gr;
        $update .= ($update eq '' ? '' : ', ').$field." = '".$escaped."'";
        $insert_fields .= ', '.$field;
        $insert_values .= ", '".$escaped."'";
    }
    $site = exists $opts{'s'} ? $opts{'s'} : '';
    
    if($printouts > 0) {
        if(exists $opts{'w'}) {
            $status = prompt_select('Write to DB?','0,1');
            $sql = 'UPDATE maps SET '.$update.' '.$where;
        }
        if(exists $opts{'d'}) {
            $status = prompt_select('Delete from DB?','0,1');
            $sql = "UPDATE maps SET permanent_record='N' ".$where;
        }
    } else {
        $status = prompt_select('Insert item status. If 0, nothing will be written to DB.','U,D,C,P,0');
        $sql = "INSERT INTO maps (permanent_record, vl_site, vl_year, use$insert_fields) VALUES ('Y','$site',NULL,'$status'$insert_values);";
    }
    if((exists $opts{'w'} || exists $opts{'d'}) && $status ne '0') {
        $sth = $dbh->prepare($sql);
        $sth->execute;
        $sth->finish();
        print "\nWROTE TO DB!\n";
    }
    print "\n$sql\n";
}
$dbh->disconnect;

sub prompt_select {
    $y = '-';
    @options = split(',', $_[1]);
    while( !($y ~~ @options) ) {
        print "\n".$_[0].' ('.$_[1].'): ';
        $y = <STDIN>;
        chomp $y;
        if($y eq '') { $y = $options[0]; }
    }
    return $y;
}

sub rss_item {
    %aa = %{dclone($_[0])};
    $rssdate = rss_date(substr $a{'year'}, 0, 4);
    return <<EOF;
<item>
<title>$a{title}</title>
<author>$a{author}</author>
<guid>$a{uid}</guid>
<link>$a{url}</link>
<pubDate>$rssdate</pubDate>
</item>
EOF
}
