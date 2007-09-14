require 'bin/get_html.pl';
require 'bin/language_definitions.pl';
require 'bin/escape_things.pl';
require 'bin/rm_extra_html.pl';
use Encode;

sub fetch_articles_cats{

  my ($cat, $cats, $articles, $wiki_http, $text, $error, $tmp, $continue, $link, $count, $line);
  my ($cont_tag, $old_cont_tag, $max_failures, $count_attempts, $sleep, %Dictionary, $Lang, $Category, $max_no);

  %Dictionary = &language_definitions();
  $Lang      = $Dictionary{'Lang'};
  $Category  = $Dictionary{'Category'};
  $wiki_http = 'http://' . $Lang . '.wikipedia.org';

  $max_failures = 10;  $sleep = 1;

  $max_no = 500; # Fetch $max_no articles at the same time (the query gives error for more than that)
  
  # $cat is the category to search for subcategories and articles. Use it to create a Wikipedia query.
  # Note that we call &escape_things which replaces spaces with "+", then "&" with "%26", etc.
  $cat = shift; $cat =~ s/^\Q$Category\E://ig; $cat = &escape_things ($cat);
  $link = $wiki_http . '/w/query.php?what=category&cptitle=' . $cat . '&format=txt' . '&cplimit=' . $max_no;
 
  $cats=shift; $articles=shift; # the last two are actually arrays, will contain the output artcicles/cats
  @$cats=(); @$articles=(); # blank them before populating

  $continue=1;
  $count_attempts = 1;
  $cont_tag = "";
  
  while ($continue){
     print "Getting $link<br>\n";

     ($text, $error) = &get_html($link);
     $text =~ s/\<\/?b\>//ig; # rm strange bold markup in the query format
     $text = &rm_extra_html($text);

     # a kind of convoluted code. Try harder to get the continuation of current category than the first page
     if ($link =~ /cpfrom=/){
       $max_failures = 10; 
     }else{
       $max_failures = 2;
     }
     
     if (  $text !~ /\[perf\]\s*=\>\s*Array/i
	   && $text !~ /\[pageInfo\]\s*=\>\s*Array/i 
	   && $count_attempts < $max_failures) {

       print "Warning: Could not fetch $link properly in attempt $count_attempts !!! <br>\n";
       print "Sleep $sleep<br>\n"; sleep $sleep;
       
       $count_attempts++;
       $continue = 1;

       # try again the same thing
       next;
     }

     $count_attempts = 1; # reset 
     $continue = 0;

     foreach $line ( split ("\n", $text) ){

       # Check if the current category continues on a different page. If so, fetch that one too.
       if ($line =~ /\[next\]\s*\=\>\s*(.*?)\s*$/i){

	 # Need to bring $old_cont_tag in, to avoid an infinite loop bug in query.php
	 $old_cont_tag = $cont_tag;
	 $cont_tag = $1;

	 # must convert $cont_tag to something acceptable in URLs
	 $cont_tag = &escape_things ($cont_tag);

	 $link = $wiki_http . '/w/query.php?what=category&cptitle=' . $cat
	    . '&format=txt&cpfrom=' . $cont_tag . '&cplimit=' . $max_no;

	 $continue = 1 unless ($cont_tag eq $old_cont_tag); # go on, but avoid infinite loops.
       }

       # get subcategories and articles in a given category
       next unless ($line =~ /\[title\]\s*\=\>\s*(.*?)\s*$/); # parse Yurik's format
       $match = $1;
       
       if ($match =~ /^\Q$Category\E:/i){
	 @$cats = (@$cats, $match); # that's a category
       }else{
	 @$articles = (@$articles, $match);
       }
     }

     print "Sleep 1<br><br>\n"; sleep 1;
   }

  # sort the articles and categories. Not really necessary, but it looks nicer later when things are done in order
  @$articles = sort {$a cmp $b} @$articles;
  @$cats = sort {$a cmp $b} @$cats;
 }

1;

