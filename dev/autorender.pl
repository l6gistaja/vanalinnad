#!/usr/bin/perl

use XML::Simple;
$xml = new XML::Simple;
$mainconf = $xml->XMLin('conf.xml');
@commands = ();

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
	if(exists $map->{composite} || (exists $map->{flags} && $map->{flags} =~ /deleted/)) { next; }
	push(@commands, './dev/tiler.pl -s '.$site.' -y '.$map->{map});
    }
    push(@commands, 'echo "#################################################### COMPOSITE MAPS '.$site.'"');
    foreach $map (keys %{$sitegdal->{composite}}) {
	if((exists $sitegdal->{composite}->{$map}->{flags}
		&& $sitegdal->{composite}->{$map}->{flags} =~ /deleted/)
	    || ! exists $sitegdal->{composite}->{$map}->{maps}) { next; }
	push(@commands, 'echo "===================================== COMPOSITE '.$site.' '.$map);
	@composites = split(/,/, $sitegdal->{composite}->{$map}->{maps});
	$l = scalar(@composites);
	for($i = 0; $i < $l; $i++) {
	    push(@commands, './dev/tiler.pl -s '.$site.' -y '.$composites[$i]
	      .($i < $l - 1 ? ' -m' : ''));
	}
    }
}

foreach my $command (@commands) {
    print "$command\n";
    #system($command);
}
