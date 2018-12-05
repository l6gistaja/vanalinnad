#!/usr/bin/perl

@commands = ('echo "empty v1 to v2"');

use lib './dev';
use VlHelper qw(get_sites);
$xml = new XML::Simple;
$mainconf = $xml->XMLin('conf.xml');
@sites = get_sites($mainconf);
@sites = qw(Voru);

foreach my $site (@sites) {
    $v1 = "$mainconf->{dirvector}$mainconf->{dirplaces}$site/empty_v1.json";
    $v2 = "$mainconf->{dirvector}$mainconf->{dirplaces}$site/$mainconf->{fileemptytiles}";
    push(@commands,"mv $v2 $v1");
    push(@commands,"$mainconf->{dirdev}attic/empty1to2_workhorse.pl $v1 $v2");
}

foreach my $command (@commands) {
    print "$command\n";
    #system($command);
}
