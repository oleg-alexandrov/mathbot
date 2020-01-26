require 'bin/html_encode_decode.pl';
require 'bin/get_html.pl';
require  'bin/language_definitions.pl';
use Encode;

sub fetch_articles_cats{

  my ($cat, $cats, $articles, $wiki_http, $text, $error, $tmp, $continue, $link, $count, $line, $cont_tag, $max_failures, $count_failures, $sleep, %Dictionary, $Lang, $Category);

  %Dictionary = &language_definitions();
  $Lang      = $Dictionary{'Lang'};
  $Category  = $Dictionary{'Category'};
  $wiki_http = 'https://' . $Lang . '.wikipedia.org';

  $max_failures = 10;  $sleep = 5;

  # $cat is the category to search for subcategories and articles. Use it to create a Wikipedia query
  $cat = shift; $cat =~ s/^\Q$Category\E://ig; $cat=&html_encode($cat); $cat =~ s/_/\+/g;
  $link = $wiki_http . '/w/query.php?what=category&cptitle=' . $cat . '&format=txt' . '&cplimit=500';
 
  $cats=shift; $articles=shift; # the last two are actually arrays, will contain the output artcicles/cats
  @$cats=(); @$articles=(); # blank them before populating

  $continue=1;
  $count_failures = 1;
  
  while ($continue){
     print "Getting $link<br>\n";

     ($text, $error) = &get_html($link);
     $text =~ s/\<\/?b\>//ig; # rm strange bold markup in the query format

     # a kind of convoluted code. Try harder to get the continuation of current category than the first page
     if ($link =~ /cpfrom=/){
       $max_failures = 10; $sleep = 5;
     }else{
      $max_failures = 2; $sleep = 5;
     }
     
     if (  $text !~ /\[perf\]\s*=\>\s*Array/i
	   && $text !~ /\[pageInfo\]\s*=\>\s*Array/i 
	   && $count_failures < $max_failures) {

       print "Error! Could not fetch $link properly in attempt $count_failures !!! <br>\n";
       print "Sleep $sleep<br>\n"; sleep $sleep;
       
       $count_failures++;
       $continue = 1;

       # try again the same thing
       next;
     }

     $count_failures = 0; # reset 
     $continue = 0;

     foreach $line ( split ("\n", $text) ){

       # Check if the current category continues on a different page. If so, fetch that one too.
       if ($line =~ /\[next\]\s*\=\>\s*(.*?)\s*$/i){

	 $cont_tag = $1;
	 $cont_tag = encode('utf8', $cont_tag); # Unicode encoding seems to be necessary

	 # must convert $cont_tag to something acceptable in URLs
	 $cont_tag =~ s/ /\+/g; $cont_tag =~ s/\&/\&amp;/g; $cont_tag =~ s/\"/\&quot;/g;

	 $link = $wiki_http . '/w/query.php?what=category&cptitle=' . $cat
	    . '&format=txt&cpfrom=' . $cont_tag . '&cplimit=500';
	 $continue = 1;
       }

       # get subcategories and articles in a given category
       next unless ($line =~ /\[title\]\s*\=\>\s*(.*?)\s*$/); # parse Yurik's format
       $match = $1;
       $match = encode('utf8', $match); # Unicode encoding seems to be necessary
       
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

