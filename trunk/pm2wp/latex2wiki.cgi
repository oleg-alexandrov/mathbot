#!/usr/local/bin/perl

use strict;                   # 'strict' insists that all variables be declared
use diagnostics;              # 'diagnostics' expands the cryptic warnings
use CGI::Carp qw(fatalsToBrowser);

# These two modules ('cgi-lib.pl' and 'pm.pl') help in dealing with web forms.
# The actual functionality of the code is implemented in the parse_latex routine below
require "cgi-lib.pl";
require 'pm.pl';

MAIN: {

  # Read in all the variables set by the form
  my (%input, $ltext);
  &ReadParse(\%input);

  # Print the header
  print "Content-type: text/html\n\n";

  $ltext=$input{'ltext'};
  $ltext = &parse_latex ($ltext);

  # print the processed text in a Wikipedia textbox
  &print_head();

  print "$ltext\n";

  &print_foot();
  
}

sub parse_latex{

  my $text = shift;
  my ($ms, $me);

  $text =~ s/\r//g; # get rid of carriage returns

  # emphasize an empty line with more returns
  $text =~ s/\n[\t ]*\n/\n\n\n/g;

  # rm otherwise newlines
  $text =~ s/[ \t]*\n[ \t]*([^\n])/ $1/g;

  # strip the preamble
  $text =~ s/^.*?\\begin\{document\}//sig;
  $text =~ s/\\end\{document\}.*?$//sig;

  # dollar signs to math tags
  $ms='<math>'; $me = '</math>';
  $text =~ s/\s*\$\$\s*(.*?)\s*\$\$\s*/\n\n:$ms$1$me\n\n/sg;
  $text =~ s/\$(.*?)\$/$ms$1$me/g;

  # convert sections and subsections
  $text =~ s/\s*\\section.*?\{(.*?)\}\s*/\n\n==$1==\n\n/sig;
  $text =~ s/\s*\\subsection.*?\{(.*?)\}\s*/\n\n===$1===\n\n/sig;

  # convert bold and italic
  $text =~ s/\{\s*\\bf\s*(.*?)\s*\}/'''$1'''/sg;
  $text =~ s/\{\s*\\it\s*(.*?)\s*\}/''$1''/sg;
  $text =~ s/\{\s*\\em\s*(.*?)\s*\}/''$1''/sg;
  $text =~ s/\\emph\s*\{\s*(.*?)\s*\}/''$1''/sg;
  
  # deal with references, per [[Wikipedia:Footnote3]]
  $text =~ s/\s*\\begin{thebibliography}.*?\n\s*/\n\n==References==\n\n/g;
  $text =~ s/\\cite\{(.*?)\}/\{\{ref\|$1\}\}/g;
  $text =~ s/\s*\\bibitem\{(.*?)\}/\n\#\{\{note\|$1\}\}/g;
  $text =~ s/\s*\\newblock\s*/ /g; # odd bibtex command
  
  # strip extra newlines and rm space at the beginning and end (this better be the last thing in the code)
  $text =~ s/^\s*(.*?)\s*$/$1/sg;
  $text =~ s/[ \t]*\n[ \t]*\n\s*/\n\n/g;
  return $text;
}
