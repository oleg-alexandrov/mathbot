use POSIX 'chmod';
use strict;

my $Watchdog_filename;
my $Watchdog_filename_global;

sub create_watchdog_file {
  my $pid = $$;
  $Watchdog_filename = "/home/oleg/run/wp10.$$";
  $Watchdog_filename_global = '/home/oleg/run/wp10.all';

  if ( -e $Watchdog_filename && ! -w $Watchdog_filename) { 
    die "Can't create watchdog file $Watchdog_filename: $!\n";
  }

  open OUT, ">", $Watchdog_filename
    or die "Can't create watchdog file $Watchdog_filename: $!\n";
  print OUT "$$\n";
  close OUT; 
  chmod 0666, $Watchdog_filename;

  print "X Creating watchdog file $Watchdog_filename.<br/>\n";
}

sub check_watchdog_file {
  if ( ! -e $Watchdog_filename) { 
     die "Watchdog file $Watchdog_filename was removed; aborting.\n";
  }
  if ( -e $Watchdog_filename_global) { 
     remove_watchdog_file();
     die "Watchdog file $Watchdog_filename_global found; aborting.\n";
  }
}

sub remove_watchdog_file {
  unlink $Watchdog_filename
    or die "Error unlinking $Watchdog_filename: $!\n";
  print "Removing watchdog file $Watchdog_filename.<br/>\n";
}


sub test_watchdog { 
  create_watchdog_file();
  my $i;
  for ( $i = 0; $i < 5; $i++) { 
    print "$i\n";
    check_watchdog_file();
    sleep 5;
  }
  remove_watchdog_file();
}

1; #Return success upon loading
