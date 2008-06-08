#!/usr/bin/perl
use strict;                   # 'strict' insists that all variables be declared
use diagnostics;              # 'diagnostics' expands the cryptic warnings
use Unicode::Normalize;
use LWP::Simple;
require Encode;

undef $/;

sub strip_html {
  
  my ($text, $url, $title, $see_also, @Links, %maplink,
  @potential_links, $link, $link_root, $Link, $potential_link,
  $before, $after, $built_link, $id, $cats);

  my $bmt="___begin_oleg_mathtab___";
  my $emt="___end_oleg_mathtab___";
  
  $text=shift;
  
  # Section 1: save some info before it is stripped off

  # (a) figure out the see also section
  if ($text =~ /(See\s+Also:.*?\n)/) {
    $see_also=$1;
  } else {
    $see_also="";
  }
 $see_also=&format_seealso($see_also);


  # (b) id 
  $text =~ /Object\s+id\s+is\s+(\<.*?\>|)(\d+)/;
  $id=$2;
  
  # (c) title
  $text =~ /\<title\>(.*?)\<\/title\>/;
  $title=$1;
  $title =~ s/PlanetMath:\s*\s*//i;
  $title =~ s/^(.)/uc($1)/e;


  # (d) AMS classification and categories
  $text =~ /\<br.*?\>Classification:\<br.*?\>\s*\<table.*?\>(.*?)\<\/table\>/is;
  $cats=$1; $cats=&format_cats($cats);

  # Section 2: strip HTML cruft from top and bottom of article -- very sensitive part of the code

  $text =~ s/^.*?\<\!--\s+math box\s+--\>//sg;
  $text =~ s/^.*?\<\!--\s+content\s+--\>.*?\<table.*?\<td\>//sg;
  $text =~ s/\n[^\n]*?\<font\s+size=\"-1\"\>[^\n]*?is\s+owned\s+by.*?$//s; 
  $text =~ s/\n[^\n]*?\<font\s+size=\"-1\"\>[^\n]*?Was\s+owned\s+by.*?$//s; 

  # Section 3: newlines and spaces

  $text =~ s/\s+/ /g;   
  $text =~ s/\<p[^\<]*?\>/\n\n/g; # must be that way, with [^\>], otherwise confusion arises
  $text =~ s/\<\/p.*?\>//g;
 

  $text =~ s/\<br.*?\>//g;
  $text =~ s/\<div.*?\>/\n\n/g; # div means new paragraph
  $text =~ s/\<\/div.*?\>/\n\n/g;

  # Section 4: html cleanups

  # (a) minor html cleanups
  $text =~ s/\<\!--.*?--\>//sg; # strip comments 
  $text =~ s/\<\/?tbody.*?\>//g; # rm this kind of marks
  $text =~ s/\`\`/\"/g;   $text =~ s/\'\'/\"/g;  # quotes style
  $text =~ s/ -- / \&amp;mdash; /g; # long line style
  $text =~ s/\<dt\>\<a\s+id=\"[^\"]*?\"\s+name=\"[^\"]*?\"\>.*?\<\/dt\>\s*/\n\* /g; # references
  
  # (c) deal with section headings
  $text =~ s/\<h1\>\<a\s+id.*?\>(.*?)\<.*?h1\>/\n\n==$1==\n\n/g;
  $text =~ s/\<h2\>\<a\s+id.*?\>(.*?)\<.*?h2\>/\n\n===$1===\n\n/g;
  $text =~ s/\<h(\d+)\>\<a\s+id.*?\>(.*?)\<.*?h\1\>/\n\n===$2===\n\n/g; # for all other headings

  # (d) span and font issues
  $text =~ s/\<span class=\"arabic\"\>(.*?)\<\/span\>/$1/ig;
  $text =~ s/\<span class=\"textit\"\>(.*?)\<\/span\>/\<i\>$1\<\/i\>/ig;
  $text =~ s/\<span class=\"textbf\"\>(.*?)\<\/span\>/<b\>$1\<\/b\>/ig;
  $text =~ s/\<\/?b\>/'''/ig;
  $text =~ s/\<\/?i\>/''/ig;
  $text =~ s/\<\/?em\>/''/ig;
   
  # Section 5: math formulas: tricky

  # (a) replaces images with their alt text 
  $text =~ s/\"\s*\$/\"$bmt/g;
  $text =~ s/\$\s*\"/$emt\"/g;
  $text =~ s/\<img\s+[^\>]*?alt\s*=\s*\"(.*?)\".*?\>/$1/ig; #(be very careful with this command!)
  $text =~ s/$bmt\s*/\<math\>/g;
  $text =~ s/$emt/\<\/math\>/g;

  # (b) more math formulas tweaking
  $text =~ s/\<span\s+class\s*=\s*\"MATH\"\>(.*?)<\/span\>/$1/ig;
  $text =~ s/\\begin\{displaymath\}/\<math\>/g;
  $text =~ s/\\end\{displaymath\}/\<\/math\>/g;
  $text =~ s/(\\begin\{eqnarray\*?\}.*?\\end\{eqnarray\*?\})/eqnarray_fun($1)/eg;
  $text =~ s/(\\begin\{cases\*?\}.*?\\end\{cases\*?\})/cases_fun($1)/eg;
  $text =~ s/(\<table class=\"equation.*?\<\/table\>)/format_eqntable($1)/seg;
  $text =~ s/\<math\>\s*\\displaystyle/\n\n:\<math\>/g; # displaystyle goes onto a new line
  $text =~ s/\\lvert/\\left\|/g; $text =~ s/\\rvert/\\right\|/g;
  $text =~ s/\\text/\\mbox/g;

  # (c) minor cleanups
  $text =~ s/(\<\/math\>)\./.$1/g;  # put period inside the formulas
  $text =~ s/\<math\>\\ \<\/math\>//g; # this abnomination shows up sometimes
  $text =~ s/\n\s*\<math\>/\n\n:\<math\>/g; # indent

  # (d) deal with links. Technically this does not belong here, but sometimes there are formulas in links
  $text =~ s/(\<a\s+name\s*=\s*\"tex2htm.*?\<\/a\>)/&format_link($1)/eg;

  # Section 6: convert to simpler TeX dialect..................

  $text=~ s/\\ast([^a-zA-Z])/\*$1/g; # \ast --> *
  $text=~ s/\\qedsymbol([^a-zA-Z])/\\square$1/g; # black square at the end of proof
  $text =~ s/\\prec([^a-zA-Z])/\\triangleleft$1/g;  
  $text =~ s/\\vert([^a-zA-Z])/\|$1/g;
  $text =~ s/\\bigl([^a-zA-Z])/\\bigg$1/g;
  $text =~ s/\\bigr([^a-zA-Z])/\\bigg$1/g;
  $text =~ s/\\dots[a-z]([^a-zA-Z])/\\dots$1/g;
  $text =~ s/\\H([^a-zA-Z])/\\mathcal\{H\}$1/g;
  $text =~ s/\\mathscr([^a-zA-Z])/\\mathcal$1/g;
  $text =~ s/\\xrightarrow([^a-zA-Z])/\\longrightarrow$1/g;
  
  # Section 7. Add various info saved earlier. 

  # (a) append the see also
  $text = "$text\n\n" . "$see_also";

  # (b) bottom template
  $text = "$text\n\n----\n{{planetmath|id=$id|title=$title}}\n\n";
 
  # (c) categories
  $text = "$text\n\n$cats\n";
  
  # Appendix: minor cleanups (these operations better be last)

  # (a) sometimes emtpy indented text shows up from <div>
  $text =~ s/\n\s*:\n/\n\n/g; 

  # (b) I like it more this way
  $text =~ s/===\s*Bibliography\s*===/== References ==/g;

  # (c) rm extra spaces
  $text =~ s/\n\s+/\n\n/g; 
  $text =~ s/^\s*//g;
  $text =~ s/\s*$//g;
  
  # Conclussion.
  return ($id, $title, $text);
}

sub eqnarray_fun{
  $_=shift;
  s/\\begin\{eqnarray\*?\}/\<math\>\\begin\{matrix\}/g;
  s/\\end\{eqnarray\*?\}/\\end\{matrix\}\<\/math\>/g;


  s/\\\s+/\\\\ /g;

  return $_;
}

sub cases_fun{
  $_=shift;

  s/\\begin\{cases\}/\\begin\{matrix\}/g;
  s/\\end\{cases\}/\\end\{matrix\}/g;

  s/\\\s+/\\\\ /g;

  return $_;
}

sub format_link {
  $_=shift;

  
  my ($link, $name);
  
  /^.*?encyclopedia\/(.*?).html.*?\>(.*?)\<\/a\>/ig;
  $link=$1; $name=$2;
  $link =~ s/([A-Z][a-z])/ $1/g;
  $link =~ s/^\s*//g;
  $link = lc($link);

  # some pages on Wikipedia are named differently than on PM, so links need to be changed
  open (FILE, "<User:mathbot/Mapped_links.txt");
  foreach (split ("\n", <FILE>)){
    next if (/^\s*$/ || /^\#/); # ignore comments and empty lines
    if (/^\s*($link)\s*--\s*(.*?)\s*$/i){
      $link=$2;
    }
  }

  $link =~ s/\d+$//g; # make "absolute value2" into "absolute value"

  $link =~ s/\<\/?math\>//g; $name =~ s/\<\/?math\>//g;  # Wikipedia does not like math in links
  
  if ($name =~/^($link)(.*?)$/i ) {
    return "\[\[$1\]\]$2";
  } else {
    return "\[\[$link|$name\]\]"; 
  }
}

sub format_seealso{
  $_=shift;

  if ($_ =~ /^\s*$/) {
    return "";
  }

  s/\<a\s+href.*?\>/\[\[/g;
  s/\<\/a\>/\]\]/g;
  s/See\s+Also:\s*/\n\n==See also==\n\n\* /g;
  s/\s*,\s*/\n\* /g;
  s/\<.*?\>//g;
  return $_;
}

sub format_eqntable{
  $_=shift;
  s/\<table.*?\>//g;
  s/\<\/table.*?\>//g;
  s/\<\/?td\b.*?\>//g;
  s/\<\/?tr\b.*?\>//g;

  return $_;
}

sub format_cats {
  
  my (@class, %cats, $class_no, $cat, $key);
   
  $_=shift;
  s/\<.*?>//g;
  s/\&nbsp;/ /g;
  s/\(.*?\)//sg;
  s/^\s*AMS\s*MSC:\s*//g;
  s/\s+/ /g;
  s/\s*$//g;
  $class_no=$_;
  
  open(FILE, "<Cats.txt");
    foreach (split "\n", <FILE>){
    next unless (/^:(\d+)\s+(.*?)$/);
    $key=$1; $cat=$2;
    $cat =~ s/\]\]\s+\[\[/\]\]\n\[\[/g;
    $cats{$key}=$cat;
  }

  $cat="";
  
  @class=split(" ", $class_no);
  foreach (@class){
    next unless (/^\d\d/);
    s/^(\d\d).*?$/$1/g;
     
    if (exists $cats{$_}) {
      $cat=  "$cat" . "\n$cats{$_}\n";
    }else{
      $cat = "$cat" . "\n<!-- Error! AMS MSC $_-xxx does not have a corresponding Wikipedia category! This needs fixing!\n";
    }
  }

  $cat =~ s/\[\[:Category:/\[\[Category:/g;
  
  if ($cat !~ /\[\[Category:/){
    $cat = "$cat" . "\[\[Category:Mathematics]]"; # fallback category
  }

  # rm possible duplicates
  %cats=();
  foreach (split ("\n", $cat) ){
    next if (/^\s*$/);
    s/^\s*//g;
    s/\s*$//g;
    $cats{$_}=1;
  }
  
  $cat="";
  foreach (keys %cats){
    $cat="$cat" . "$_" . "\n";
  }

  return $cat;
}

sub print_head {
    print '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" dir="ltr" lang="en"><head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    
<body>

<div id="bodyContent">
<div id="contentSub"></div>

<div id="wikiPreview"></div><script type="text/javascript">
/*<![CDATA[*/
document.writeln("<div id=\'toolbar\'>");
document.writeln("</div>");
/*]]>*/
</script>

<form id="editform" name="editform" method="post" action="http://en.wikipedia.org/w/index.php?title= ... not really, just bootstrapping Wikipedia\'s preview function &amp;action=submit" enctype="multipart/form-data">

<center>
<textarea tabindex="1" accesskey="," name="wpTextbox1" rows="25" cols="80">';
}

sub print_foot {
  print '</textarea> 

<br>

<input tabindex="6" id="wpPreview" value="Show preview" name="wpPreview" accesskey="p" title="Preview your changes, please use this before saving! [alt-p]" type="submit"> (this will bootstrap the Wikipedia preview function)

<p>

';
  
}
1;
