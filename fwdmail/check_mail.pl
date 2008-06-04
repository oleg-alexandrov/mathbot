#!/usr/bin/perl
use strict;		      # 'strict' insists that all variables be declared
use diagnostics;	      # 'diagnostics' expands the cryptic warnings

require 'mail_utils.pl'; # utils for doing some common tasks
undef $/; # undefines the separator. Can read one whole file in one scalar.

# use main to avoid the curse of global variables
MAIN: {


  my ($mail_dir, @folders, $folder, @messages, $message, $header, $body);
  my ($error, $folder_bk);

  $mail_dir = $ENV{HOME} . "/old_mail";
  @folders = <$mail_dir/*/*>;
  
  foreach $folder (@folders){
    next if (-d $folder); # ignore directories
    next if ($folder =~ /\.(msf|dat)$/); # odd Thunderbird thingies

    @messages = &parse_mailbox($folder);

    # check if the mail is not corrupt or if it was split well
    if (1 == 1){
      open(FILE, ">>Corrupted_old_mail");
      foreach $message (@messages){
        
        ($header, $body, $error) = &split_in_header_body($message);
        
        if ($error){
          print "\n----------------\n$header\n------------\n";
          print FILE $header . $body;
          
          #exit(0);
        }
      }
      close(FILE);
      sleep 1;

    }

  }
}
