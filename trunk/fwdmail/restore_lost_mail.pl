#!/usr/bin/perl
use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use MIME::Tools;
use MIME::QuotedPrint;
use Encode;
use Mail::MboxParser;
undef $/; # undefines the separator. Can read one whole file in one scalar.

# identify mail which exists in the back up but which went missing from the mailbox
# put it back in lost_mail folder
MAIN: {

  my ($backupdir, @mail_folders, %saved_ids, $saved_ids_file, $saved_mail_file, @ids, $id);
  my ($mail_dir, $new_mail, $folder, $text, $mailbox, $message, $date, %existing_mail_ids, $lost_mail_folder);
  my (@backup_folders, $lost_mail_text);
  
  # place the mail is backed up at
  $backupdir = '/m1/aoleg/backupmail';
  chdir $backupdir;
  @backup_folders=<saved_mail*>;

  # mail settings
  $mail_dir = "$ENV{HOME}/mail";
  @mail_folders = (<$mail_dir/*>);
  $lost_mail_folder = "$mail_dir/lost_mail";

  # read ids of mail which is in the mailbox
  foreach $folder (@mail_folders){

    print "$folder\n";
    $mailbox = Mail::MboxParser->new($folder, decode => 'ALL');
    foreach $message ($mailbox->get_messages){

      # need to make this give warnings
      next unless ($message =~ /Message-ID\:\s*\<(.*?)\>/i);
      $id = $1;

      $existing_mail_ids{$id} = 1;
    }
  }

  # recover lost mail, which exists in the back up but not in the mail directory
  # Put it in $lost_mail_folder
  $lost_mail_text="";
  foreach $folder (@backup_folders){

    print "$folder\n";
    $mailbox = Mail::MboxParser->new($folder, decode => 'ALL');
    foreach $message ($mailbox->get_messages){

      # need to make this give warnings
      next unless ($message =~ /Message-ID\:\s*\<(.*?)\>/i);
      $id = $1;

      # ignore mail which was not lost
      next if (exists $existing_mail_ids{$id});
      
      print "Restoring lost mail with id $id\n";
      $lost_mail_text .= $message;
    }
  }


  # append new mail to $lost_mail_folder
  open(FILE, ">>$lost_mail_folder");  print FILE "$lost_mail_text"; close(FILE);

}

