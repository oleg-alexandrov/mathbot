#!/usr/local/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings

my $wp_path='/u/cedar/h2/afa/aoleg/public_html/cgi-bin/wp';
@INC=($wp_path . '/modules', $wp_path . '/rfa', @INC); 

require 'bin/wikipedia_fetch_submit.pl'; # my own packages, this and the one below
require 'bin/wikipedia_login.pl';
require 'bin/get_html.pl';
require 'extract_user.pl';

undef $/;		      # undefines the separator. Can read one whole file in one scalar.
MAIN: {

  # obligatory first print line in a cgi script
  print "Content-type: text/html\n\n";

  # flush the buffer each line
  $| = 1; 
  
  my ($attempts, $sleep, $toc, $toc_text, $rfa_url, $username);
  my ($rfa, $error, $text, $section, $level, $type);
  my ($sec_count, $subsec_count, @sections, @levels, $i, $data, $edit_summary);
  my ($position); # == 1 if we are in the section listing admin and bureaucrat candidates, and 0 otherwise
  
  chdir $wp_path . '/rfa';
  &wikipedia_login(); $attempts = 10; $sleep = 2;
  
  $rfa = 'Wikipedia:Requests for adminship';
  $toc=  $rfa . '/TOC.wiki';

  $rfa_url = $rfa; $rfa_url =~ s/ /_/g;
  $rfa_url = 'https://en.wikipedia.org/wiki/' . $rfa_url;

  $data->{'adminship'}=(); $data->{'bureaucratship'}=();
  $edit_summary = &extract_current_admin_bureaucrat_candidates($rfa, $data);

  print '<p>Fetching the source of <a href="' . $rfa_url . '">' . $rfa . '</a>.' . "\n";
  ($text, $error) = &get_html ($rfa_url);

  # initialize the TOC
  $toc_text = &init_toc();
  $sec_count = 0; $subsec_count = 0;
  $position = 1;
  
  print "<p>Extracting level 2 and level 3 headings ... <br><br>\n";
  foreach $section (split ("\n", $text)){
    
    next unless ($section =~ /^\<h(\d+)/i);
    $level = $1;

    # strip all headings except h2 and h3. Then strip all html markup from headings
    next unless ($level == 2 || $level == 3);
    $section =~ s/\".*?\"//g; $section =~ s/\<.*?\>//g; $section =~ s/\s*\[edit\]\s*//g;

    next if ($section eq 'Contents');

    if ($level == 2){

      $sec_count++; $subsec_count = 0;
      $toc_text = $toc_text . &print_level1($rfa, $sec_count, $section);

      # if $section is supposed to list the admin and bureaucrat candidates, then do list them
      if ($section =~ /Current nominations for (adminship|bureaucratship)/i){
	$type = $1;
	$position = 1;

	foreach $username (@{$data->{$type}}){
	  $subsec_count++;
	  $toc_text = $toc_text . &print_level2($rfa, $sec_count, $subsec_count, $username);
	}
	
      }else{
      # other sections
	$position=0;
      }

      
    }else{
      # level 3 headings
      
      next if ($position == 1); # admins and bureaucrats are already listed

      $subsec_count++;
      $toc_text = $toc_text . &print_level2($rfa, $sec_count, $subsec_count, $section);
    }
  }

  $toc_text = $toc_text . &print_toc_footer();

  &wikipedia_submit($toc, $edit_summary, $toc_text, $attempts, $sleep);
  
  print '<p><b>Done!</b> You may go back to <a href="' . $rfa_url . '">' . $rfa . '</a>.' . "\n";
}		

# match each subpage with the user name of the admin candidate in that subpage
sub extract_current_admin_bureaucrat_candidates {

  my ($rfa, $text, $current_candidates_file, $sep, $line, %prev_candidates, $sleep, $attempts, $shift);
  my (%order, $rfa_wiki, $type, %current_candidates, $page, $username, $count);
  my ($data, $edit_summary);
  
  $rfa = shift; $data = shift;
  $rfa_wiki = $rfa . '.wiki';
  
  $sep = ' --;;-- ';
  $attempts = 10; $sleep = 2;
  
  $current_candidates_file = 'Current_candidates.txt';
  open(FILE, "<$current_candidates_file"); $text = <FILE>; close(FILE);
  foreach $line (split ("\n", $text)){
    next unless ($line =~ /^(.*?)$sep(.*?)$/);
    $prev_candidates{$1} = $2;
  }
  
  $count = 0;
  $text = &wikipedia_fetch ($rfa_wiki, $attempts, $sleep);
  foreach $line (split ("\n", $text)){

    # this is not an admin or bureaucrat
    next if ($line =~ /Wikipedia:Requests for adminship\/Front matter/i); # not a real admin candidate
    next if ($line =~ /Wikipedia:Requests for adminship\/bureaucratship/i); # not a real admin candidate

    # keep only the relevant lines
    next unless ($line =~ /\{\{\s*(Wikipedia:Requests[_ ]for[_ ](adminship|bureaucratship)\/.*?)\s*}\}/i);
    $page = $1; $type = $2;

    # the username of the current candidate
    if (exists $prev_candidates{$page}){
      $username = $prev_candidates{$page};
      $current_candidates{$page} = $username;
    }else{
      $text = &wikipedia_fetch($page . '.wiki', $attempts, $sleep);
      $username = &extract_user ($text);
      next if ($username =~ /^\s*$/);
      $current_candidates{$page} = $username;
    }

    push (@{$data->{$type}}, $username);
  }
  

  $edit_summary="";
  foreach $page (keys %current_candidates){
    if (! exists $prev_candidates{$page}){
      $username = $current_candidates{$page};
      $edit_summary = $edit_summary . "\[\[User:$username\|$username]] added. ";
    }
  }

  foreach $page (keys %prev_candidates){
    if (! exists $current_candidates{$page}){
      $username = $prev_candidates{$page};
      $edit_summary = $edit_summary . "\[\[User:$username\|$username]] removed. ";
    }
  }

  # print the current candidates to file
  open(FILE, ">$current_candidates_file");
  foreach $page (sort {$a cmp $b} keys %current_candidates){
    print FILE "$page$sep$current_candidates{$page}\n";
  }

  $edit_summary = "Updating the TOC." if ($edit_summary =~ /^\s*$/);
  return $edit_summary;
}

# ugly wikicode
sub init_toc {

  return
'<!-- Hide the default TOC. Create a simulated TOC with only level 2 and level 3 headings. -->
__NOTOC__
<table id="toc" class="toc" align="right" summary="Contents">
<tr>
<td>
<div id="toctitle">
\'\'\'Contents\'\'\'
<!--<h2>Contents</h2>-->
</div>
<ul>
';
}

sub print_level1 {

  my ($rfa, $sec_count, $section)=@_;
  
  return '<li class="toclevel-1"> [[' . $rfa . '#' . $section . ' | '
	 . $sec_count . ' ' . $section . ']]' . ' </li>' . "\n"; 
}

sub print_level2{

  my ($rfa, $sec_count, $subsec_count, $section)=@_;

  return '<ul><li class="toclevel-2"> ' . '[[' . $rfa . '#' . $section . ' | '
     . $sec_count . '.' . $subsec_count . ' ' . $section . ']]' . ' </li></ul>' . "\n"; 
}

sub print_toc_footer {
  
  return "</ul>\n([https://www.math.ucla.edu/~aoleg/wp/rfa/toc.cgi refresh contents])\n"
	. "</td>\n</tr>\n</table>\n";
}
