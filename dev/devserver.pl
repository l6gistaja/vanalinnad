#!/usr/bin/perl

use lib './dev';
use VlHelper qw(json_file_read);
$xml = new XML::Simple;
$mainconf = $xml->XMLin('conf.xml');
%localdata = json_file_read($mainconf->{'dircache'}.$mainconf->{'filelocal'});
$localdata{webroot} =~ /:(\d+)/;
system('python -m SimpleHTTPServer '.$1); 




