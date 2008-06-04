#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings

undef $/; # undefines the separator. Can read one whole file in one scalar.
$| = 1; # flush the buffer each line


sub read_done_ids { # This routine is untested!!!!!!!!!!!!!!

  # A routine useful to mark if a given action was already performed
  # on a given message.
  my ($done_file, $Done_hash, $id, $text);
  
  $done_file = shift; $Done_hash = shift;
 
  open(FILE, "<$done_file") || die "Can't open file $done_file";
  $text = <FILE>; 
  close (FILE);
 
  foreach $id (split ("\n", $text)) {
    next if ($id =~ /^\s*$/);
    $Done_hash->{$id} = 1;
  }
}

sub parse_mailbox { # Checked!
  #                 # Use with split_in_header_body below each time at least once.

  # Split mailbox into messages. The big idea is that messages
  # are separated by a blank line (\n\n), and the first line
  # is a "From " line with a date.
  
  my ($folder, @mails, $text, $mail, $count, $header, $sep);
  
  $folder = shift; 
  print "Doing $folder\n";

  open (FILE, "<$folder");
  $text = <FILE>;
  close (FILE);

  # Below is the trickiest part in in all these routines,
  # splitting an email into individual messsages.
  $sep = '  dfAF69Afkasl4534AkdDF4dafpord9HJLaFe  Fkas74LagDre  ';  # something very unlikely
  $text =~ s/(\n\n)(From .*?\d:\d\d:\d\d)/$1$sep$2/g;
  @mails = split ($sep, $text);

  return @mails;
}

sub write_mailbox{   # Checked!

  my ($folder, $mails, $message);
  
  $folder = shift;
  $mails  = shift;

  if (-e $folder){
    print "Error! $folder exists!\n";
    exit(0);
  }

  print "Writing to $folder\n";
  open(FILE, ">$folder");
  foreach $message (@$mails){
    print FILE $message;
  }
  close(FILE);
  
}

sub split_in_header_body{ # checked!
  
  # Split message into header and body. Flag if there are problems.
  # Use the fact that the header is separated from the message body by a blank line.

  # To do: Add more checks for problems below.
  
  my ($message, $header, $body, $error);

  $message = shift;

  if ($message =~ /^(.*?\n\n)(.*?\s*)$/s){
    $header = $1;
    $body = $2;
  }else{
    #empty message body
    $header = $message;
    $body = "";
  }
  
  $error = 0;

  # The "From " line is the most important. 
  if ($header !~ /^From .*?\d:\d\d:\d\d/){
    print "Error! Malformed From line!\n";
    $error = 1;
  }
  
  # Check if the message id is missing. Some of my utils rely on it.
  if ($header !~ /\nMessage-ID:\s+\<.*?\>/i){
    print "Error, no message id!\n";
    $error = 1;
  }

  # check if there is more than one message id in the header    
  if ( $header =~ /\nMessage-ID:\s+\<[^\n]*?\>.*?\nMessage-ID:\s+\<[^\n]*?\>/si ) {
    print "Error, more than one message id!\n";
    $error = 1;
  }

  return ($header, $body, $error);
}

sub merge_header_body { # not checked!

  my ($header, $body);

  $header = shift; $body = shift;
  return $header . $body;
}

