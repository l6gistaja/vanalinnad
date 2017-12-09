#!/usr/bin/perl

@commands = ('echo "Rerendering ALL maps"');

use XML::Simple;
$xml = new XML::Simple;
$mainconf = $xml->XMLin('conf.xml');

@sites = ();
$sitekml = $xml->XMLin($mainconf->{dirvector}.$mainconf->{fileareaselector});
foreach $site (keys %{$sitekml->{Document}->{Placemark}}) {
    push(@sites, exists $sitekml->{Document}->{Placemark}->{$site}->{description}
	? $sitekml->{Document}->{Placemark}->{$site}->{description} : $site);
}

foreach my $site (@sites) {
    $sitegdal = $xml->XMLin($mainconf->{dirvector}.$mainconf->{dirplaces}.$site.'/'.$mainconf->{filegdal});
    push(@commands, 'echo "#################################################### SINGLE MAPS '.$site.'"');
    foreach $map (@{$sitegdal->{translate}}) {
	@flags = exists $map->{flags} ? split(/,/, $map->{flags}) : qw();
	if('deleted' ~~ @flags) { next; }
	push(@commands, './dev/tiler.pl -s '.$site.' -y '.$map->{map});
    }
    push(@commands, 'echo "#################################################### COMPOSITE MAPS '.$site.'"');
    foreach $map (keys %{$sitegdal->{composite}}) {
	@flags = exists $sitegdal->{composite}->{$map}->{flags} ? split(/,/, $sitegdal->{composite}->{$map}->{flags}) : qw();
	if('deleted' ~~ @flags
	    || ! exists $sitegdal->{composite}->{$map}->{maps}) { next; }
	push(@commands, 'echo "===================================== COMPOSITE '.$site.' '.$map.'"');
	@composites = split(/,/, $sitegdal->{composite}->{$map}->{maps});
	$l = scalar(@composites);
	for($i = 0; $i < $l; $i++) {
	    push(@commands, './dev/tiler.pl -s '.$site.' -y '.$composites[$i]
	      .($i < $l - 1 ? ' -m' : ''));
	}
    }
}

foreach my $command (@commands) {
    #print "$command\n";
    #system($command);
}
