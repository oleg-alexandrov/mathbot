#!/usr/bin/perl
use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings
use MIME::Tools;
use MIME::QuotedPrint;
use Encode;
use Mail::MboxParser;
undef $/; # undefines the separator. Can read one whole file in one scalar.

# Sometimes when I save mail with mutt not all mail gets saved into folders. Very weird
#and unacceptable. Do something about that.

MAIN: {

  my ($backupdir, @folders, %saved_ids, $saved_ids_file, $saved_mail_file, @ids, $id);
  my ($mail_dir, $new_mail, $folder, $text, $mailbox, $message, $date);

  # place to store the mail. This directory will grow larger (primary because of attachments)
  $backupdir = '/m1/aoleg/backupmail';
  chdir $backupdir;

  # save mail in inbox and sent-mail.
  $mail_dir = "$ENV{HOME}/mail";
  @folders = ("$mail_dir/i", "$mail_dir/s");
  
  $saved_ids_file = "all_saved_mail_ids";
  $date = &local_date_with_numbers();
  $saved_mail_file = "saved_mail" . "_" .  $date;

  # read saved ids
  if (open(FILE, "<$saved_ids_file") ){
    @ids = split ("\n", <FILE>);
    close(FILE);
  }
  foreach $id (@ids){
    $saved_ids{$id} = 1;
  }

  # save new mail
  $new_mail = "";
  foreach $folder (@folders){

    $mailbox = Mail::MboxParser->new($folder, decode => 'ALL');
    foreach $message ($mailbox->get_messages){

      # need to make this give warnings
      next unless ($message =~ /Message-ID\:\s*\<(.*?)\>/i);
      $id = $1;

      # bypass mail which was already saved
      next if (exists $saved_ids{$id});

      $saved_ids{$id} = 1;
      $new_mail .= $message;
      
    }
  }

  # append new mail to $saved_mail_file;
  open(FILE, ">>$saved_mail_file");  print FILE "$new_mail"; close(FILE);

  # save the ids
  open(FILE, ">$saved_ids_file");
  foreach $id (keys %saved_ids){
    print FILE "$id\n";
  }
  
}

sub local_date_with_numbers {  # returns a date in the format 2006-12-25

  my $days_in_future = 0;
  
  my ($year);
  my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings)
     = localtime( time() + $days_in_future*24*60*60 );
  
  $year = 1900 + $yearOffset;
  $month = $month + 1; $month = '0' . $month if ($month < 10);
  $dayOfMonth = '0' . $dayOfMonth if ($dayOfMonth < 10);
  
  return "$year-$month-$dayOfMonth";
  
}
