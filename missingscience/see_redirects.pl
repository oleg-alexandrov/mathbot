#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use LWP::Simple;
use open ':utf8'; # input/output in unicode
undef $/;

my (@letters, $text, $address, @entries, $link, $name, $letter);
my ($counter, @links, %done, $redirto, %redir);

open (FILE, "<:utf8", "Done.txt"); $text = <FILE>; close (FILE);
@links = split ("\n", $text);
foreach $link (@links){
  next unless ($link =~ /^\/./);

  if (open (FILE, "<:utf8", "articles/$link")){
   $text = <FILE>;
  }else {
   print "$link does not exist!\n";
   $text="";
  }
 close (FILE);
  $text =~ s/\s+/ /g;
  $text =~ s/\&\#(\d+);/chr($1)/eg;
  if ($text =~ /<td\s+valign=\"baseline\"\s*class=\s*"title"\s*>(.*?)\<\/td/ig){
    $name=$1;
    $name =~ s/\<.*?\>//g;
  }else{
     $name="";
     print "Error! Could not find the title of $link!\n";
  }
  if ($text =~ /\<span\s+class=\"crosslinkheader\">SEE:\<\/span\>\s*<a\s+href=.*?\>(.*?)\<\/a/igs){
   $redirto=$1;
   $redirto =~ s/\<.*?\>//g;
   $redir {$name}=$redirto;
   print "$name redirecs to $redirto\n";
  }
}
 
open (FILE, ">:utf8", "MW_redirs.txt"); 
foreach $name (sort {$a cmp $b } keys  %redir){
  print FILE "\[\[$name\]\] redirects to \[\[$redir{$name}\]\]\n";
}
close (FILE);

