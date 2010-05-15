#!/usr/bin/perl -w
use POSIX;                     # the strftime function
use CGI::Carp qw(fatalsToBrowser);
use lib '../modules'; # path to perl modules
use IO::Handle;

require 'bin/wikipedia_fetch_submit.pl'; # my own packages, this and the one below
require 'bin/wikipedia_login.pl';
require 'bin/fetch_articles_cats.pl';
require 'bin/html_encode_decode.pl';
require 'bin/get_html.pl';
undef $/;		      # undefines the separator. Can read one whole file in one scalar.

MAIN: {

  print "Content-type: text/html\n\n"; # this line must be the first to print in a cgi script

  # Redirecting STDOUT to /dev/null. Now, to print message, must use the SAVEOUT handle, so any other print calls will be ignored
  open (SAVEOUT, ">&STDOUT");  open (STDOUT, ">/dev/null");

  # flush the buffer after each line
  SAVEOUT->autoflush(1); 
  
  my ($assessments, $page, $project, $text, $sleep, $attempts, $iter, $class, $cat, $cat_wiki, $subject, $subcat, $subcat_wiki, $count, $root);
  
  $assessments->{quality}={'FA-Class'=>1, 'FL-Class'=>2, 'A-Class'=>3, 'GA-Class'=>4, 'B-Class'=>5,
			      'C-Class'=>6, 'Start-Class'=>7,
			      'Stub-Class'=>8, 'List-Class'=>9,
			      'Assessed-Class'=>10, 'Unassessed-Class'=>11 
			      };

  $assessments->{importance}={'Top-importance'=>'1', 'High-importance'=>'2', 'Mid-importance'=>'3',
		  'Low-importance'=>'4', 'No-importance'=>'5'};
  $root = 'Category:Wikipedia 1.0 assessments';

  &wikipedia_login('WP 1.0 bot');
  $sleep = 2; $attempts=10;

  $page = 'Wikipedia:Version 1.0 Editorial Team/Generate categories/Protected.wiki';
  $text=&wikipedia_fetch($page, $attempts, $sleep);

  # clean up the string a bit
  $text =~ s/_/ /g; 
  $text =~ s/[ \t]+/ /g; 
  $text =~ s/^.*?\n([^\n]*?articles by quality).*?$/$1/sg; 
  if ($text =~ /^\s*(.*?)\s+articles by quality/){
    $project = $1;
  }else{
    print SAVEOUT "Either you did not specify a project or you did it incorrectly. Exiting. <br><br>\n";
   exit(0);
  }

  if ($project =~ /foobar/i){
    print SAVEOUT "<b>$project</b> is not a real project. Exiting. <br><br>\n";
    exit(0);
  }

  print SAVEOUT "Project is <b>$project</b><br>\n";
  
  foreach $iter ( sort {$b cmp $a} keys %$assessments){

    $cat = 'Category:' . $project . ' articles by ' . $iter;
    $cat_wiki = $cat . '.wiki';

    $text=&wikipedia_fetch($cat_wiki, $attempts, $sleep);
    if ($text !~ /^\s*$/){
      print SAVEOUT &print_cat($cat) . " exists. Exiting. <br><br>\n";
      exit(0);
    }

    $text = '[[' . $root . '|' . $project . ']]';
    $subject = 'Creating [[' . $cat . ']] as subcategory in [[' . $root . ']]';
    print SAVEOUT '<br>Creating ' . &print_cat ($cat) . '<br>' . "\n\n";
    &wikipedia_submit($cat_wiki, $subject, $text, $attempts, $sleep); 

    $count=0;
    foreach $class ( sort { $assessments->{$iter}->{$a} <=> $assessments->{$iter}->{$b} } keys %{$assessments->{$iter}} ){

      $count++;
      
      $subcat = 'Category:' . $class . ' ' . $project . ' articles';
      $subcat_wiki = $subcat . '.wiki';
      
      $text=&wikipedia_fetch($subcat_wiki, $attempts, $sleep);
      $text = '[[' . $cat . '|' . $count . ']]';
      
      $subject = 'Creating [[' . $subcat . ']] as subcategory in [[' . $cat . ']]';
      print SAVEOUT '&nbsp;' x 4 . 'Creating ' . &print_cat ($subcat) . '<br>' . "\n\n";
      &wikipedia_submit($subcat_wiki, $subject, $text, $attempts, $sleep);

    }
  }
  print SAVEOUT "<br><b>Done! Please check if the above is what you wanted, and delete any categories created incorrectly.</b>\n";
}

sub print_cat {
  my $cat = shift;
  return '<a href="http://en.wikipedia.org/wiki/' . &html_encode($cat) . '">' . $cat . '</a>';
}
