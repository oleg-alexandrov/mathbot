#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use Encode;

undef $/; # undefines the separator. Can read one whole file in one scalar.
$| = 1; # flush the buffer each line

# Split mailbox in individual messages, and forward to gmail using procmail. 

MAIN: {

  my ($mail_dir, $id, $message_file, $pause, $message);
  my ($output, $success, $folder, @folders, $done_file, %Done_hash, $line, $mailbox);
  my (@mails);

  # define some settings we will need later
  $mail_dir = $ENV{HOME} . '/mail';
  $message_file = 'Message_file';  # save here a message before calling the forwarding program
  $done_file = 'Sent_to_gmail.txt'; # Store message ids of mail forwarded earlier
  $pause = 30; # pause this many seconds between sending messages to gmail

  &read_done_ids ($done_file, \%Done_hash);

  # start the fun, go through the folders, forward to gmail stuff which has not been forwarded yet
  @folders = <$mail_dir/*>;
  foreach $folder (@folders){

    @mails = &parse_mailbox($folder);
    foreach $message (@mails) {          
      next unless ($message =~ /Message-ID:\s+\<(.*?)\>/i); # checked for message id earlier
        
      $id = $1; $id =~ s/\s+/_/g; # this last subst should not be necessary, is here just in case
      next if ( ( exists $Done_hash{$id} ) && ( $Done_hash{$id} == 1 ) );
      print "Will be doing message $id\n";
      
     my $action = 1;   # use $action == 0 for debugging
     if ($action){
        # Forward with procmail
        &send_message_to_gmail_via_procmail($message);
        $success = 1;
        $Done_hash{$id} = $success;
        open (DONE_FH, ">>$done_file") || die "Can't append to $done_file!\n";
        print DONE_FH "$id $success\n";
        close (DONE_FH);

        print "Sleep for $pause seconds\n\n\n"; 
        sleep $pause;
      }
    }
  }
}


sub read_done_ids {
  
  my ($done_file, $Done_hash, $line, $id, $success, $text);
  
  $done_file = shift; $Done_hash = shift;
 
  open(FILE, "<$done_file") || die "Can't open file $done_file";
  $text = <FILE>; 
  close (FILE);
 
  foreach $line (split ("\n", $text)) {
    next unless ($line =~ /^(.*?)\s+(\d+)\s*$/);
    $id = $1; $success = $2;
    $Done_hash->{$id} = $success;
  }
}

sub parse_mailbox {

  # Split mailbox into messages. The big idea is that messages
  # are separated by a blank line (\n\n), and the first line
  # is a "From " line with a date. Also the header is separated
  # from the message body by a blank line too.
  
  my ($folder, $text, @mails, $mail, $count, $header);
  
  $folder = shift; 
  print "Doing $folder\n";

  open (FILE, "<$folder");
  $text = <FILE>;
  close (FILE);
  
  # Get rid of carriage returns
  $text =~ s/\r//g;

  # Below is the trickiest part in the entire script,
  # splitting an email into messsages
  # Note that this removes whitespace between messages.
  @mails = split ("(?=\n\nFrom .*?\\d:\\d\\d:\\d\\d)", $text);

  # Lots of ugly heuristic below. Getting obsessed about the above
  # line doing a good job at splitting messages
  
  $count = 0;
  foreach $mail (@mails){
    $mail =~ s/^\s*//g; # rm whitespace at the beginning

    $count++;
    #print "$count$mail\n\n*********************************\n\n";
    
    # Check if the message has a header
    if ($mail =~ /^(.*?)(\n\n|$)/s){
      $header = $1;
    }else{
      print "Can't locate header!\n";
      print "$mail\n";
      exit(0);
    }

    # Check if the message id is missing
    if ($header !~ /\nMessage-ID:\s+\<.*?\>/i){
      print "Error, no message id!\n";
      print "Message is: $mail\n";
      exit(0);
    }

    # check if there is more than one message id in the header    
    if ( $header =~ /\nMessage-ID:\s+\<([^\n]*?)\>.*?\nMessage-ID:\s+\<([^\n]*?)\>/si ) {
      my $id1 = $1; my $id2 = $2;
      if ($id1 eq $id2){
         print "\n\nDuplicate message id!!! Must be Thunderbird bug! Will continue!\n";
      }else{
         print "Error, more than one message id! Will exit!!!\n";
         exit(0);
      }
      print "$mail\n\n";
    }
 
    #    print "$mail\n";
    #    print "z" x 1000 . "\n"; 
  } 

  return @mails;
}

sub send_message_to_gmail_via_procmail {

  my ($message, $tmp_file, $procmailrc_file);

  $message = shift;

  $tmp_file = "Tmp_file.txt";
  open(FILE, ">$tmp_file");
  print FILE "$message";
  close(FILE);

  $procmailrc_file = $ENV{HOME} . '/gmail_procmailrc';
  if (!-e $procmailrc_file){
    print "Error! $procmailrc_file does not exist!!! Exiting.\n";
    exit(0);
  }
  
  print "cat $tmp_file \| /usr/bin/procmail $procmailrc_file\n";
  print `cat $tmp_file \| /usr/bin/procmail $procmailrc_file` . "\n";

}
