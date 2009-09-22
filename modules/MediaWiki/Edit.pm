package Mediawiki::Edit;
# $Revision: 1.1 $
# Carl Beckhorn, 2008
# Copyright: GPL 2.0

use strict;
use Data::Dumper;
use LWP::UserAgent;
use HTTP::Cookies;
use HTML::TokeParser;
use Encode;

#   # Usage:
#
#   # Initialize
#   require Mediawiki::Edit;
#   my $client = Mediawiki::Edit->new();
#   $client->base_url('http://en.wikipedia.org/w');
#
#   # Log in
#   $client->login($user, $pass);
#    # OR #
#   $client->login_from_file($credentials_file_name);
#
#   # Edit
#   $client->edit($page, $text, $summary, $minor, $watch);
#   $client->append($talkpage, $text, $sectiontitle, 0, 0);

###########################################################

sub new { 
  my $self = {};

  $self->{'agent'} = new LWP::UserAgent;
  $self->{'agent'}->cookie_jar(HTTP::Cookies->new());

  $self->{'baseurl'} = 'http://192.168.1.71/~mw/wiki';
  $self->{'indexurl'} = 'http://192.168.1.71/~mw/wiki/index.php';
  $self->{'apiurl'} = 'http://192.168.1.71/~mw/wiki/api.php';
  $self->{'loggedin'} = 'false';
  $self->{'maxRetryCount'} = 40;
  $self->{'debugLevel'} = 1;
  $self->{'maxlag'} = 5;
  $self->{'requestCount'} = 0;
  $self->{'htmlMode'} = 0;
  $self->{'decodeprint'} = 1;

  $self->{'dbLockedMessage'} = 'Database locked';

  $self->{'editFailedDelay'} = 5;

  bless($self);
  return $self;
}

#############################################################

sub base_url () { 
  my $self = shift;
  my $newurl = shift;

  if ( defined $newurl)  {
    $self->{'baseurl'} = $newurl;
    $self->{'indexurl'} = $newurl . "/index.php";
    $self->{'apiurl'} = $newurl . "/api.php";
    $self->print(1, "A Editor: Set base URL to: $newurl");
  }
  return $self->{'baseurl'};
}

####################################3

sub debug_level { 
  my $self = shift;
  my $level = shift;

  if ( defined $level) { 
    $self->{'debugLevel'} = $level;
    $self->print(1,"A Editor: Set debug level to: $level");
  }

  return $self->{'debugLevel'};
}

########################################################

sub html_mode  {
  my $self = shift;
  my $mode = shift;
  if ( defined $mode)  {
    $self->{'htmlMode'} = $mode;
    if ( $self->{'htmlMode'} > 0 ) { 
      $self->print(1, "A Enable HTML mode");
    } else {
      $self->print(1, "A Disable HTML mode");
    }
  }

  return $self->{'htmlMode'};
}


#####################################################3

sub maxlag { 
  my $self = shift;
  my $maxlag = shift;

  if ( defined $maxlag) { 
    $self->{'maxlag'} = $maxlag;
    $self->print(1,"A Editor: Maxlag set to " . $self->{'maxlag'});
  }

  return $self->{'maxlag'};
}


#############################################################3

sub login { 
  my $self = shift;
  my $userName = shift;
  my $userPassword = shift;

  $self->print(1,"A Editor: Logging in");

  my $res = $self->makeHTMLrequest('post',
           [ 'title' =>  'Special:Userlogin',
             'action' => 'submitlogin',
             'type' => 'login',
               wpName     => $userName,
               wpPassword => $userPassword,
               wpRemember => 1] );

  $res = $self->makeHTMLrequest('post',
        ['title'=>'Special:Userlogin','wpCookieCheck'=>'login']);

  my $content = $res->content();

  if ( $content =~ m/var wgUserName = "$userName"/ ) {
    $self->print(1,"R Editor: Login successful");
    $self->{'loggedin'} = 'true';
  } else {
    if ( $content =~ m/There is no user by the name/ ) {
       $self->{errstr} = qq/Login  failed: User does not exist/;
    } elsif ( $content =~ m/Incorrect password entered/ ) {
       $self->{errstr} = qq/Login failed: Bad password/;
    } elsif ( $content =~ m/Password entered was blank/ ) {
       $self->{errstr} = qq/Login failed: Blank password/;
    }
    $self->print(1,  "E Editor: Login error.");
    exit;
  }
}

##################################

sub login_from_file {
  my $self = shift;
  my $file = shift;
  open IN, "<$file" or die "Can't open file $file: $!\n";

  my ($a, $b, $user, $pass, $o);
  $o = $/;   # Paranoia
  $/ = "\n";
  while ( <IN> ) { 
    chomp;
    ($a, $b) = split /\s+/, $_, 2;
    if ( $a eq 'user') { $user = $b;}
    if ( $a eq 'pass') { $pass = $b;}
  }

  close IN;
  $/ = $o;

  if ( ! defined $user ) { 
    die "No username to log in\n";
  }

  if ( ! defined $pass ) { 
    die "No password to log in\n";
  }

  $self->login($user, $pass);
}

#############################################################3

sub cookie_jar {

  my $self = shift;
  return $self->{'agent'}->cookie_jar();

}

#############################################################3

sub add_maxlag_param {
  my $self = shift;
  my $arr = shift;

  if ( defined $self->{'maxlag'} && $self->{'maxlag'} >= 0 ) { 
    push @$arr, 'maxlag';
    push @$arr, $self->{'maxlag'};
  }
}


sub add_maxlag_url { 
  my $self = shift;
  my $url = shift;

  if ( defined $self->{'maxlag'} && $self->{'maxlag'} >= 0 ) { 
    $url .= '&maxlag=' . $self->{'maxlag'};
  }

  return $url;
}

######################################

sub makeHTMLrequest {
  my $self = shift;
  my $type = shift;
  my $args = shift;

  my $url = $self->{'indexurl'};

  $self->print(2, "A Editor: Making HTML request (" . $self->{'requestCount'} . ")");

  if ( $type eq 'post' ) {
    $self->add_maxlag_param($args);
    $self->print(5, "I Editor: URL: " . $url);

    my $k = 0;
    while ( $k < scalar @{$args}) { 
      $self->print(5, "I Editor:\t" . ${$args}[$k] . " => " . ${$args}[$k+1]);
      $k += 2;
    }
  } else { 
    $url = ${$args}[0];
    $url = $self->add_maxlag_url($url);
    $self->print(5, "I Editor: URL: " . $url);
  }

  my $retryCount = 0;
  my $delay = 4;
 
  my $res;

  while (1) { 
    $self->{'requestCount'}++;

    if ( $retryCount == 0) { 

    } else { 
      $self->print(1,"A Editor: Repeating request ($retryCount)");
    }

    if ( $type eq 'post') { 
      $res = $self->{'agent'}->post($url, $args);
    } else {
      $res = $self->{'agent'}->get($url);
    }

    last if $res->is_success();
    last if $res->is_redirect();

    $self->print(1, "I Editor: HTTP response code: " . $res->code() ) ;

    if (defined $res->header('x-squid-error')) { 
      $self->print(1,"I Editor:\tSquid error: " 
                               . $res->header('x-squid-error'));
      $self->print(5,Dumper($res));
    }

    $retryCount++;

#   $self->print(1, Dumper($res->headers));

    if ( defined $res->header('retry-after')) { 
      $delay = $res->header('x-database-lag');
      $self->print(2,"I Editor: Maximum server lag exceeded");
      $self->print(3,"I Editor: Current lag $delay, limit " 
                                             . $self->{'maxlag'});
      $retryCount--; # Shoudn't time out due to maxlag

#      print Dumper($res);
    }

    $self->print(1, "I Editor: sleeping for " . $delay . " seconds");

    sleep $delay;

    if ( $delay < 60) { 
      $delay = $delay * 2;
    } else { 
      $delay = 120;
    }
     
    if ( $retryCount > $self->{'maxRetryCount'}) { 
      my $errorString = 
           "Exceeded maximum number of tries for a single request.\n";
      $errorString .= 
       "Final HTTP error code was " . $res->code() . " " . $res->message . "\n";
      $errorString .= "Aborting.\n";
      die($errorString);
    }
  }

#  $self->print(6, Dumper($res));

  return $res;
}


#############################################################

sub dump { 
  my $self = shift;
  return Dumper($self);
}


##############################################


sub get_edit_token { 
  my $self = shift;
  my $page = shift;

  $self->print(1, "I Editor: Get token for $page");

  my $res = $self->makeHTMLrequest('get', 
             [ $self->{'indexurl'} . "?title=$page" . "&action=edit"]);

  my $content = $res->content();

  my $p = HTML::TokeParser->new(\$content);
  my $edittime;
  my $starttime;
  my $edittoken;
  my $edittext;
  my $tag;
  while ($tag = $p->get_tag('input')) {
    next unless $tag->[1]->{type} eq 'hidden';
    if ( $tag->[1]->{name} eq 'wpEdittime') { 
       $edittime = $tag->[1]->{value};
    } elsif ( $tag->[1]->{name} eq 'wpStarttime') { 
       $starttime =  $tag->[1]->{value}; 
    } elsif ( $tag->[1]->{name} eq 'wpEditToken') { 
       $edittoken =  $tag->[1]->{value}; 
    }
  }

  # Inefficient; should use HTML::Parser directly to avoid the second pass
  $p = HTML::TokeParser->new(\$content);
  while ($tag = $p->get_tag('textarea')) {
    if ( $tag->[1]->{name} eq 'wpTextbox1') { 
       $edittext =  $p->get_text();
    }
  }

  return ($edittoken, $edittime, $starttime, $edittext);
}

#######################################################

sub edit { 
  my $self = shift;
  my $page = shift;
  my $text     = shift;
  my $summary  = shift;
  my $is_minor = shift || '';
  my $is_watched = shift || '';

  my ($edittoken, $edittime, $starttime, $edittext);

  $self->print(1, "A Editor: Commit $page (edit summary: '$summary')");


  my $try = 0;
  my $maxtries = $self->{'maxRetryCount'};
  my $getToken = 1;

  while (1) { 
    $try++;

    if ( $getToken == 1) { 
      ($edittoken, $edittime, $starttime, $edittext) =  
                            $self->get_edit_token($page);

#      $getToken = 0;
#  Being more conservative here

     if ( $edittext eq $text) { 
       $self->print(2,"I Editor: text on server matches text to upload. Not making an edit");
       return;
     }

    }

    my $res = $self->makeHTMLrequest('post',
          [ "action" => "submit",
            "title" => $page,
            "wpTextbox1"    => $text,
            "wpSummary"     => $summary, 
            "wpSave"        => 'Save Page',
            "wpEdittime"    => $edittime,
            "wpStarttime" => $starttime,
            "wpEditToken"   => $edittoken,
            "wpWatchthis"   => $is_watched
          ] );

    if ( $res->code() == 302 ) { 
      $self->print(2, "Editor: Edit successful");
      last;
    } elsif ( $res->code() == 200) { 
      $self->print(1, "Editor: Edit unsuccessful ($try/$maxtries)");
     
      if ( $res->header('title') =~ /^\Q$self->{'dbLockedMessage'}\E/ ) {
        $self->print(2, "I  Databased locked, retrying\n");
        $try--;
        $getToken = 1;
      } else {    
        print Dumper($res);
      }

      sleep $self->{'editFailedDelay'};

      if ( $try >= $maxtries) { 
        $self->print(1, "E Editor: Too many tries, giving up");
        last;
      }
    }
  }
}


################################################################

sub append { 
  my $self = shift;
  my $page = shift;
  my $text     = shift;
  my $summary  = shift;
  my $is_minor = shift || '';
  my $is_watched = shift || '';

  my ($edittoken, $edittime, $starttime);

  $self->print(1, "E Editor: Commit $page (msg: $summary)");

  my $try = 0;
  my $maxtries = $self->{'maxRetryCount'};

  my $getToken = 1;

  while (1) { 
    $try++;

    if ( $getToken == 1) { 
      ($edittoken, $edittime, $starttime) =  
                            $self->get_edit_token($page);
# being more conservative
#       $getToken = 0;
    }

    my $res = $self->makeHTMLrequest('post',
          [ "action" => "submit",
            "title" => $page,
            "wpSection" => 'new',
            "wpTextbox1"    => $text,
            "wpSummary"     => $summary, 
            "wpSave"        => 'Save Page',
            "wpEdittime"    => $edittime,
            "wpStarttime" => $starttime,
            "wpEditToken"   => $edittoken,
            "wpWatchthis"   => $is_watched,
            "wpMinoredit"   => $is_minor,   ] );

    if ( $res->code() == 302 ) { 
      $self->print(2, "I Editor: Edit successful");
      last;
    } elsif ( $res->code() == 200) { 
      $self->print(1, "I Editor: Edit unsuccessful ($try/$maxtries)");

      if ( $res->header('title') =~ /^\Q$self->{'dbLockedMessage'}\E/ ) {
        $self->print(2, "I  Databased locked, retrying\n");
        $try--;  
        $getToken = 1;  
      } else {    
        print Dumper($res);
      }
      sleep $self->{'editFailedDelay'};

      if ( $try == $maxtries) { 
        $self->print(1, "I Editor: Too many tries, giving up");
        last;
      }
    }
  }
}

################################################################

sub print { 
  my $self = shift;
  my $limit = shift;
  my $message = shift;

  if ( $self->{'decodeprint'} == 1) { 
    $message = decode("utf8", $message);
  }

  if ( $limit <= $self->{'debugLevel'} ) {
    print $message;
    if ( $self->{'htmlMode'} > 0) { 
      print " <br/>\n";
    } else { 
      print "\n";
    }
  }
}


########################################################
## Return success upon loading class
1;

