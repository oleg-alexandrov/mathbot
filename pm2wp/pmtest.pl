#!/usr/bin/perl
use strict;                   # 'strict' insists that all variables be declared
use diagnostics;              # 'diagnostics' expands the cryptic warnings
use Unicode::Normalize;
use LWP::Simple;
require Encode;
require 'pm_devel.pl';

undef $/;

my ($url, $id, $text, $title);

#$url='https://planetmath.org/?op=getobj&from=objects&id=720';
#$text = get($url);
#print "$text";
#exit (0);

open (FILE, "<:utf8", "$ARGV[0]");
$text=<FILE>;
close(FILE);

($id, $title, $text) = &strip_html($text);

print "$text\n";

