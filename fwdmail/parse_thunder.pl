#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
#use Mail::MboxParser;

undef $/; # undefines the separator. Can read one whole file in one scalar.
$| = 1; # flush the buffer each line

# I convert my Outlook mail to mbox format from Thunderbird.
# That mail needs a bit more processing before I can view it from mutt.
# The goal is to archive all my mail in proper mbox format and later forward to gmail.

my $Strip_CR = 1; # if to strip carriage returns
MAIN: {

  my ($folder, $folder_tmp, $text, $mail_dir, $thunder_dir, @thunder_subdirs, $dir, @folders);
  my %folder_style_map;

  $folder = $ARGV[0];
 
  open(FILE, "<$folder"); $text = <FILE>; close(FILE);
     
  # Do a few changes to headers to convert the odd mbox format obtained after
  # importing Outlook mail into Thunderbird to "standard" mbox.
  $text = &parse_folder ($text);

  $folder = $folder . "_parsed";
  print "Writing to $folder\n";
  open(FILE, ">$folder"); print FILE $text; close(FILE);
}

# I don't like how Outlook names some of its defaulft folders
sub OutlookStyle_to_MyStyle {

  my %folder_style_map;
  $folder_style_map{'Inbox'}='i';
  $folder_style_map{'Sent Items'}='s';
  $folder_style_map{'Work'}='w';
  $folder_style_map{'Sync Issues'}='q';
  $folder_style_map{'Drafts'}='postponed-msgs';
  $folder_style_map{'Outbox'}='c';
  $folder_style_map{'Junk E-mail'}='spam';
  $folder_style_map{'Deleted Items'}='trash';

  return %folder_style_map;
}

sub parse_folder {
  
  my ($text, $message, @messages, $header, $body, $count);
  
  $text = shift;

  # Convert the odd format imported by Thunderbird from Outlook to standard "From " lines.
  $text =~ s/(^|\n)(From)\s+-\s+(\w\w\w),?\s+(\d+)\s+(\w+)\s+(\d\d\d\d)\s+(\d+:\d\d:\d\d).*?(\n)/$1$2 dummy\@dummy.com $3 $5 $4 $7 $6 $8/g; 
  
  # Several lines of scratch to help with the regex above   
  #  2      3     4  5   6    7        8 
  #  From - Fri, 28 Sep 2007 07:01:12
  #  -----------------------------------------------------------
  #  From oleg@school.edu Thu Sep 27 19:54:41 2007
  #  2 @ 3 5 4 7 6 8
  
  #  Odd Microsoft header line. This line may confuse mail parsers so needs to be done here.
  $text =~ s/(^|\n)(From\s+[^\s]*?\@.*?\n)(Microsoft Mail Internet Headers)/$1$2X-dummy-line: $3/g; 

  # this part could be done with the Perl mailbox parser module. Could be more reliable. 
  @messages = &split_text_into_messages ($text);
  
  $count = 0;
  foreach $message (@messages){

    $count++;

    # split into $header and $body, to process them separately
    if  ($message !~ /^(.*?\n\s*?\n)(.*?)$/s){
      print "Error! Can't find body! Exiting ... \n";
      exit(0);
    }

    $header = $1;
    $body = $2;

    # For some reason, the above matching does not make
    # $message equal to $header$body. Very odd. I have to force
    # newlines at the end of $body.
    $body =~ s/\s*$/\n\n/g;

    # Fix dummy Outlook/Thunderbird bug where the email is in
    # html but is declared as plain text.
    ($header, $body) = &fix_content_type ($header, $body);

    # Fix silly Outlook bug when my email address does not get attached to emails I sent.
    # The same bug exists for "To: " recepients, but that is harder to fix.
    $header =~ s/(\s*From:\s+\"Oleg Alexandrov\")(\s*?\n)/$1 \<oleg\@cadcompany.com\>$2/g;

    # Dummy Microsoft Outlook does not add Message ID to sent messages
    $header = &add_message_id_if_needed($header);
    
    # join back to message
    $message = $header . $body;
    # last if ($count > 3); # this line is useful for debugging
  }

  $text = join ("", @messages);

  $text =~ s/\r//g if ($Strip_CR); # strip carriage returns
  
  return $text;
}

sub split_text_into_messages {

  my $text = shift;
  my $sep = ' soAdop '; # a dummy thing, to separate messages. There's got to be a more elegant way.
  
  # Insert a sep between messages.
  # This assumes that the mbox format used does have an email address on the "From " line.
  $text =~ s/(\n)(From\s+[^\s]*?\@)/$1$sep$2/g; 
  
  my @messages = split ($sep, $text);
  
  return @messages;
}

sub fix_content_type {

  # Some attachments/message parts are in HTML, but Outlook (or
  # Thuderbird) is stupid enough to claim it is text. Replace
  # text/plain with text/html.

  my ($header, $body) = @_;

  my ($sep, @attachments, $attachment);

  # Sometimes things are wrong in the header.
  if ($body =~ /\<html/i && $header =~ /Content-Type:\s+text\/plain/i){
    $header =~ s/Content-Type:\s+text\/plain/Content-Type: text\/html/ig;  
  }

  # Same thing with attachments. What is below is a silly way to parse
  # attachments, I don't want to bother to learn MIME::PARSE or something
  if ($header =~ /\nContent-Type:.*?\n\s+boundary=\"(.*?)\"/i){
    $sep = $1;
    #print "Separator is $sep\n";
  }else{
    return ($header, $body); 
  }

  # The attachment parser below does not do a perfect job, but is good enough.
  @attachments = split ($sep, $body);

  foreach $attachment (@attachments){

    # It is very dumb to claim html is plain text. Same for ms-tnef, whatever that is.
    if ($attachment =~ /\nContent-Type:\s+(text\/plain|application\/ms-tnef)/i && $attachment =~ /\n\<html/i){
      $attachment =~ s/\nContent-Type:\s+(text\/plain|application\/ms-tnef)/\nContent-Type: text\/html/;
    }
    
  }
  
  $body = join ($sep, @attachments);
  return ($header, $body);

}

sub add_message_id_if_needed {

  # Don't modify the way the ID is manufactured here,
  # as this will yield to messages being duplicated on gmail
  # if having different ids.
  my ($header, $id);
  $header = shift;

  if ($header =~ /Message-ID:\s+\<.*?\>/i){
    # nothing to do, id exists
    return $header;
  }
  
  # Manufacture an id from the "from" and "to" lines.
  # Must be deterministic.
  if ($header =~ /^From (.*?)\n/){
    $id = $1;
  }else{
    print "Error! Missing \"From\" line in header!\n";
    exit(0);
  }

  if ($header =~ /To:(.*?)\n/i){
    $id = $id . $1;
  }else{
    print "Error! Missing \"To\" line in header!\n";
    print "$header\n";
    exit(0);
  }

  $id =~ s/[^a-zA-Z0-9]/-/g;

  $header =~ s/^(.*?\n)(Date:.*?)$/$1Message-ID: \<$id\>\n$2/sg;

  return $header;
}
  
  

