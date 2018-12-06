#!/usr/bin/perl

@commands = ('echo "Refreshing ALL roads"');

use lib './dev';
use VlHelper qw(get_sites);
$xml = new XML::Simple;
$mainconf = $xml->XMLin('conf.xml');

@sites = get_sites($mainconf);

foreach my $site (@sites) {
    $layers = $xml->XMLin($mainconf->{dirvector}.$mainconf->{dirplaces}.$site.'/'.$mainconf->{filelayers});
    push(@commands, 'echo');
    push(@commands, 'echo "#################################################### ROADS '.$site.'"');
	push(@commands, './dev/osm2xml/osmroads.pl '.$site.' .00001 '.(exists($layers->{xtra}->{osmparams}) ? $layers->{xtra}->{osmparams} : ''));
}

foreach my $command (@commands) {
    #print "$command\n";
    system($command);
}
