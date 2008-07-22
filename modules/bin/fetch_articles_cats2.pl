use lib '/home/oleg/public_html/wp/modules';
require Mediawiki::API;
use HTML::Entities;

require 'bin/language_definitions.pl';
require 'bin/escape_things.pl';
require 'bin/rm_extra_html.pl';
require 'bin/watchdog_file.pl';

use Encode;
use Data::Dumper;

my $fa_api;
my $fa_count = 0;

my $Credentials;

#####################################################
## Initialize the API object

sub init_api { 
  my (%Dictionary, $Lang, $Category, $wiki_http);

  $fa_api = Mediawiki::API->new();
  $fa_api->html_mode(1);
  $fa_api->maxlag(25);
  $fa_api->debug_level(4);
  $fa_api->max_retries(100);
  $fa_api->html_mode(1);
#  $fa_api->debug_xml(1);

  %Dictionary = &language_definitions();
  $Lang      = $Dictionary{'Lang'};
  $Category  = $Dictionary{'Category'};
  $Credentials = $Dictionary{'Credentials'};
  $wiki_http = 'http://' . $Lang . '.wikipedia.org/w/api.php';

  $fa_api->base_url($wiki_http);
}

#######################################################
# Compatibility function
# Fetch contents of a category and split them
# into subcategories and all other contents

sub fetch_articles_cats {

  my ($cat, $cats, $articles, $results, $result, $catNS);
  my ($cont_tag, $old_cont_tag, $max_failures, $count_attempts, $sleep, $max_no);

  &check_watchdog_file();
  &prepare_api(); 

  my $delay = time();

  $cat = shift; 
#  $cat =~ s/^Category://;
  $cat = encode("utf8", $cat);

  $cats=shift; $articles=shift; # the last two are actually arrays, will contain the output artcicles/cats
  @$cats=(); @$articles=(); # blank them before populating

  $catNS = 14;

  $results = $fa_api->pages_in_category_detailed($cat);

  foreach $result ( @$results)  {
    if ( $result->{'ns'} == $catNS) {
      push @$cats, decode_entities($result->{'title'});
    } else {
      push @$articles, decode_entities($result->{'title'});
    }
  }

  # sort the articles and categories. Not really necessary, but it looks nicer later when things are done in order
  @$articles = sort {$a cmp $b} @$articles;
  @$cats = sort {$a cmp $b} @$cats;

  $delay = time() - $delay;
  print "\tDebug: took $delay seconds<br/>\n";
  print "\tResults: " . (scalar @$cats) . " subcats, " 
         . (scalar @$articles) . " articles. <br/><br/>\n";

}

########################################
# 

sub fetch_content_internal  {
  my $list = shift;
  my $data = shift;

  &prepare_api();

  my $res = $fa_api->content($list);
  my $page;

  if ( scalar @$list == 1) {  
    # the api returns just the content in this case
    $data->{decode("utf8",${$list}[0])} = $res;
  } else { 
    foreach $page ( keys %$res ) { 
      $data->{decode("utf8",$page)} = $res->{$page};
   }
  }

  return 0;  # all data passed in $data
}


################################################
# Fetch the source code for a list of wiki pages

sub fetch_content {
  my $list = shift;
  my $chunk_size = 50;
  my $page;
  my $tmp = [];
  my $data = {};
  my $delay = time();

  &check_watchdog_file();

  foreach $page ( @$list ) {
    push @$tmp, encode("utf8",$page);
#    push @$tmp, $page;
    $data->{$page} = "";

    if ( scalar @$tmp >= $chunk_size ) { 
      $text .= &fetch_content_internal($tmp, $data);
      $tmp = [];  
    }
  }

  if ( scalar @$tmp > 0) {  
      $text .= &fetch_content_internal($tmp, $data);
  }

  $delay = 1 + time() - $delay;
  print "\tDebug: overall fetch took $delay seconds<br/>\n";

  return $data;
}


###########################################

sub fetch_revids { 
  my $list = shift;
  my $ids = shift;

  &prepare_api();
  
  my $title = join "|", @$list;

  print "Fetching revision ids for " . scalar @$list . " articles ($fa_count)<br/>\n";
 
  my $data = $fa_api->makeXMLrequest(['format' => 'xml',
                    'action' => 'query',
                    'prop' => 'info',
                    'rvlimit' => '1',
                    'titles' => encode("utf8", $title)], ['page']);

  $data = $fa_api->child_data($data, ['query','pages','page']);

  my $d;
  my $revid;

  foreach $d ( @$data) {
    if ( ! defined $d->{'title'} ) { 
      print "No title!\n" . Dumper($d)  . "\n\n";
      next;
    }
    $title = $d->{'title'};
    $revid = $d->{'lastrevid'};
    $ids->{$title} = $revid;
#    print "R $title $revid\n";
  }

  return $results;

}


###################

sub prepare_api {
  if ( ! defined $fa_api ) { 
    &init_api();  #this should also init $Credentials
  }
  if ( ! defined $fa_count || (($fa_count % 100) == 0)) { 
    $fa_api->login_from_file($Credentials);
  }
  $fa_count++;
}


####################################################
# Compatibility function 
# Fetch source code of a page from the API

sub wikipedia_fetch2 { 
  my $page = shift;

  if ( ! defined $page) { 
    die "Attempted to fetch undefined page";
  }

  print "P '$page'\n";
  $page =~ s/.wiki$//;
  my $data = fetch_content([$page], $data);
 
  if ( ! defined $data->{$page}) {
    print "Error: unable to get the page content for $page\n";
    return "";
  }

  print "Length: " . length ($data->{$page}) ." <br/>\n";
  return $data->{$page};
}

1;

