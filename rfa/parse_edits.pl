use strict;                   # 'strict' insists that all variables be declared
use diagnostics;              # 'diagnostics' expands the cryptic warnings
use POSIX;
use List::Util qw(first max maxstr min minstr reduce shuffle sum);
require 'bin/get_html.pl';

my $verbose = 0 ; # useful for debugging
sub parse_edits {
  
  my ($user, $user_enc, $link, $contribs_page_text, $page_no, $total_major, $total_minor, $max_pages);
  my ($commented_major, $commented_minor, $pmajor, $pminor, $lang, $inner_iter);
  my ($max_inner_iter, $editsum, $success, $base, $wiki_http, $error, $error_msg);
  
  $user=shift;
  $lang=shift;
  $base=shift; # to compute the edit summary usage based on the last how many edits

  if ($user =~ /^\s*$/){
    print "Error in parse_edits.pl. No user given. Exiting.\n";
    exit(0);
  }

  $lang="en" if (!$lang || $lang =~ /^\s*$/);

  $user =~ s/^\s*(.*?)\s*$/$1/g; 
  $lang =~ s/^\s*(.*?)\s*$/$1/g; 

  $user_enc = &html_encode($user);
  $lang     = &html_encode($lang);	
  
  $verbose = 0;
  $total_major=0; $total_minor=0; $commented_major=0; $commented_minor=0;
  $wiki_http = "http://$lang.wikipedia.org";
  $error_msg = '<font color=red>Failed to get the link!</font> Server problem or the user may not exist. ';
  
  $link = $wiki_http . "/w/index.php?limit=500&title=Special%3AContributions&contribs=user&target=$user_enc&namespace=0";

  # look at several pages of user's contributions and count the edit summary usage
  $page_no=0; $max_pages = 10; # look at most the last $max_pages pages of user's contributions
  $max_inner_iter=10; # try this many times for each link
  while ($page_no < $max_pages && $link ne "" && ($total_minor < $base || $total_major < $base)  ){ 
    $page_no++;
    
    # try several times to get the page of contributions at $link, and to find value of $link for the next contribs page
    print "Fetching \<a href=\"$link\">$link\<\/a\> ... ";
    for ($inner_iter = 1; $inner_iter <= $max_inner_iter; $inner_iter++){ 

      ($contribs_page_text, $error) = &get_html ($link);
      ($link, $success) = &get_link_to_next_contributions_page ($link, $contribs_page_text, $wiki_http);
      last if ($success); # got the page from the server, eventually

      print "Attempt: $inner_iter/$max_inner_iter. ";
      print $error_msg . "Sleep 5 seconds and try again.<br>\n";
      sleep 5;
    }
    
    if (! $success ){
      print $error_msg . "Try again later!</font>\n";
      exit (0); 
    }
    print "Done!<br>\n";

    # parse the current page of contributions, and extract the needed info
    ($total_major, $commented_major, $total_minor, $commented_minor)
       = &parse_current_contributions_page($contribs_page_text, $base,
					   $total_major, $commented_major, $total_minor, $commented_minor);

    if ($page_no > 1){
      print "sleeping for 2 seconds to give the server a break...\<br\>\n";
      sleep 2;
    }
  }

  $pmajor=floor(100*$commented_major/(max($total_major, 1)) + 0.5);
  $pminor=floor(100*$commented_minor/(max($total_minor, 1)) + 0.5);

    
  $editsum="<b>Edit summary usage</b> for $user: $pmajor\% for major edits and $pminor\% for minor edits. Based on the last $total_major major and $total_minor minor edits in the article namespace.<br>\n";
  
  return $editsum;
}

sub get_link_to_next_contributions_page {
  my ($link, $text, $wiki_http) = @_;

  my $success = 0;
  
  # given the curent page of contributions, find the link to the next page if it exists
  # the link is kind of hard to identify, since the keywords in it depend on what language Wikipedia is in
  # try to match in a language-independent way
  
  if ($text =~ /\n(.*?limit=.*?contribs=.*?namespace=.*?)\n/i){
    
    $link = $1; $link =~ s/^.*?\(.*?\).*?\(.*?\).*?\((.*?)\).*?$/$1/g;  # look in the third par of praens
    $success = 1;

    # see if there are more contributions
    if ($link =~ /a\s+href=\"(.*?)\"/i){
      $link = $1;
      $link = $wiki_http . $link;
      $link =~ s/\&amp;/\&/g;
    }else{
      $link="";  # looked at all user's contributions
    }

    print "The next link is $link\<br\>\n" if ( $verbose );

  }

  # note that in the case the main 'if' statement does not get executed, $link is same as inputed and $success == 0
  return ($link, $success);
}

sub parse_current_contributions_page {

  my ($text, $base, $total_major, $commented_major, $total_minor, $commented_minor) = @_;
  my ($line, @lines, $title, $comment, $minor);
  
  $text =~ s/\n//g; 
  $text =~ s/\<div class=[\"\']printfooter[\"\']\>.*?$//sg; #strip bottom
  $text =~ s/(\<li\b)/\n$1/ig;                              #care only about items
  @lines = split ("\n", $text);

  foreach $line (@lines) {
   
    next unless ($line =~ /^\s*\<li\b.*?title=[\"\'](.*?)[\"\'](.*?)$/i);
    $title=$1; $comment=$2; # page name is in $title, the comment is in $comment
    $title =~ s/_/ /g;
    
    next if ($title =~ /:/i); # ignore everything but the article namespace
    $comment =~ s/\<span\s+class=[\"\']autocomment[\"\']\>.*?\<\/span\>//g; # strip default comment
    
    if ($comment =~ /\<span\s+class=[\"\']minor[\"\']\>.*?\<\/span\>/) {
      $minor=1;
    } else {
      $minor=0; 
    }
    
    if ($comment =~  /\<span\s+class=[\"\']comment[\"\']\>\s*\(\s*(.*?)\s*\)\s*\<\/span\>/) {
      $comment=$1;
    } else {
      $comment=""; 
    }
    
    # the heart of the code, see how many edit summaries have comments, both for minor and for major edits
    if ($minor && $total_minor < $base ) {
      
      $total_minor++;
      $commented_minor++ if ($comment !~ /^\s*$/);
      
    } elsif ( (!$minor) && $total_major < $base ) {
      
      $total_major++;
      $commented_major++ if ($comment !~ /^\s*$/);
    }
    
    print "minor=$minor -- $title -- comment=\"$comment\"\n" if ($verbose);
  }

  return ($total_major, $commented_major, $total_minor, $commented_minor);
  
}

# small routines to convert a subset of Unicode to HTML encoded text and viceversa

# to HMTL
sub html_encode {
  $_=$_[0];
  s/ /_/g;

  s/([^A-Za-z0-9_\-.:])/sprintf("%%%02x",ord($1))/eg;
  s/\%2a/\%2A/g; # convert from a to A in line with Wikipedia conventions for encoding of *

  return($_);
}

# from HTML
sub html_decode {
  $_ = shift;
  tr/+/ /;
  s/_/ /g;
  s/%(..)/pack('c', hex($1))/eg;
  return($_);
}
		
1;
