#!/usr/bin/perl
use strict;                # 'strict' insists that all variables be declared
use diagnostics;           # 'diagnostics' expands the cryptic warnings
use POSIX;                 # the strftime function

# a louse reminder program
my $curdate=strftime("%m/%d/%y", localtime(time));

undef $/;
open (FILE, "<$ENV{HOME}/diverse/reminder.txt");
my $lines=<FILE>;
close(FILE); 

my $send_to;
if ( $lines =~ /\#begin.*?\n(.*?)\n\#end/s ){
  $send_to = $1;
  print "Will send mail to $send_to\n";
}else{
  print "Can't send mail, no recepients\n";
  exit(0);
}
$lines =~ s/\n\s*\n/\n\n/g;

my @rems = split("\n\n", $lines); # reminders
my ($date, $message, $subject, @mes);

my $rem;

foreach (@rems) {
  $rem=$_; # store this

  s/\#.*?\n/\n/g;
  s/\#.*?$/\n/g;
  s/^\s*//g;
  s/\s*$//g;
  s/^\s*$//g;
  next if (/^\s*$/s); # ignore empty reminders
  
  next unless (/^(.*?)\s(.*?$)/s); # identify the date and the message
  
  $date=$1; $message=$2;
  $date=&format_date($date); # put the date in standard format
  
  if ($date eq $curdate) {

    $message = $message . "\n";
    $message =~ /(^.*?)\n(.*?$)/sg;
    ($subject, @mes)=split("\n", $message);
    $message=join("\n", @mes);
#     print "sub: $subject\n";
#     print "mes: $message\n";

    open(SENDMAIL, "|/usr/sbin/sendmail -t");
    
    print SENDMAIL "$send_to\n";   # Send an email
    print SENDMAIL "Subject: Reminder: $subject\n"; # The subject field
    
    print SENDMAIL "\n$message";

  }
}

sub format_date { 
  my (@data, $weekday);
  my $date=$_[0];
  $date =~ s/://g; # tend to put this character sometimes
  
  my $SECONDS_PER_DAY = 60 * 60 * 24;
  my $i=0;
  if ($date =~ /^\d/){ # that is a numerical date. if needed, autocomplete, or pad with zeros
    @data=split('/', $date);

    # iterate through the month/date/year fields. if they don't exist, generate them
    for ($i=0 ; $i < 3 ; $i++){

      if ($i <= $#data ){
	$_=$data[$i];
      }else{
	$_="";
      }
      
      if ($_ =~ /^\s*$/){ # if that's an empty string, autocomplete
	
	if ($i==0){# today's month
	  $_=strftime("%m", localtime(time));
	  
	}elsif ($i==1){ # today's date
	  $_=strftime("%d", localtime(time));
	  
	}else{ # today's year
	  $_=strftime("%y", localtime(time));
	}
	
      }else{
	$_=sprintf("%0.2d", $_);
      }

      $data[$i]=$_;

    }
    $date=join('/', @data);
    
  }else{ # if I specify the date as Mo, Tu, We, Th, Fr, Sa, or Su, which means this coming day
    $date = substr($date, 0, 3); # keep at most the first three characters
    $weekday=strftime ("%a", localtime(time));
    while ($weekday !~ /$date/i){
      $i++;
      $weekday=strftime ("%a", localtime(time()+$i*$SECONDS_PER_DAY));

      if ($i > 100){ # infinite loop it seems
	$date=strftime("%m/%d/%y", localtime(time()));
	return $date;
      }

    }
    $date=strftime("%m/%d/%y", localtime(time()+$i*$SECONDS_PER_DAY));
  }
  return $date;
}





















