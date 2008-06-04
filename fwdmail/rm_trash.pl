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
  my ($mail_dir, $new_mail, $folder, $text, $mailbox, $message, $date, %trash_ids, $trash_folder, $folder_text);
  my (@backup_folders, $lost_mail_text);
  
  # place the mail is backed up at
  $backupdir = '/m1/aoleg/backupmail';
  chdir $backupdir;
  @backup_folders=<saved_mail*>;

  # mail settings
  $mail_dir = "$ENV{HOME}/mail";
  $trash_folder = "$mail_dir/trash";

  # read the trash mail
  $mailbox = Mail::MboxParser->new($trash_folder, decode => 'ALL');
  foreach $message ($mailbox->get_messages){

    # need to make this give warnings
    next unless ($message =~ /Message-ID\:\s*\<(.*?)\>/i);
    $id = $1;
    
    $trash_ids{$id} = 1;
  }

  # rm the trash mail from the backup
  foreach $folder (@backup_folders){

    print "$folder\n";
    $folder_text = "";
    $mailbox = Mail::MboxParser->new($folder, decode => 'ALL');
    foreach $message ($mailbox->get_messages){

      # need to make this give warnings
      next unless ($message =~ /Message-ID\:\s*\<(.*?)\>/i);
      $id = $1;

      # ignore trash mail
      next if (exists $trash_ids{$id});

      $folder_text .= $message;
    }

    open(FILE, ">$folder"); print FILE "$folder_text"; close(FILE);
  }
}

