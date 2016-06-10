#!/usr/local/bin/perl

use Unicode::Normalize;
use LWP::Simple;
use CGI::Carp qw(fatalsToBrowser);
require Encode;
require "cgi-lib.pl";
require "pm.pl";

binmode utf8;

MAIN: {

  # Read in all the variables set by the form
  &ReadParse(*input);

  # Print the header
  print "Content-type: text/html\n\n";

  $id=$input{'id'}; $id =~ s/[^\d]//g;
  $text=$input{'text'};

  $url='https://planetmath.org/?op=getobj&from=objects&id=' . "$id";
  $text = get($url);

  ($id, $title, $text) = &strip_html($text);

  &print_head();

  print "$text\n";

  &print_foot();

  print "Original PlanetMath article: <a href=\"$url\">$title</a>\n";

  print "</center></body></html>\n";

  my $date=`date`;
  my $ip;
  
  if (exists $ENV{REMOTE_ADDR} ){
    $ip=$ENV{REMOTE_ADDR};
    $ip = $ip . "\n" . `nslookup $ip`;
  }else{
    $ip=""; 
  }

}
