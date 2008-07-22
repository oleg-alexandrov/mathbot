use strict;
use lib '/home/oleg/public_html/wp/modules';
require Mediawiki::Edit;

use Encode;

require 'bin/language_definitions.pl';

my $ws_editor;
my $ws_count = 0;

# For debugging
# Set to 1 to disable uploading and divert uploads to a file instead
my $ws_fake = 0;
if ( defined $ENV{'WS_FAKE'} ) { 
  $ws_fake = $ENV{'WS_FAKE'};
  print "Set fake edits to: $ws_fake\n";
}


my $Credentials;

sub init_editor  {
  my %dict = &language_definitions();
  $Credentials = $dict{'Credentials'};

  $ws_editor = Mediawiki::Edit->new();
  $ws_editor->base_url('http://en.wikipedia.org/w');
  $ws_editor->login_from_file($Credentials);
  $ws_editor->debug_level(6);
  $ws_editor->maxlag(10);
}

sub prepare_editor { 
  if ( ! defined $ws_editor) { 
    init_editor();
  }
  if ( $ws_count % 100 == 0 ) { 
    $ws_editor->login_from_file($Credentials);
  }
  $ws_count++;
}

  
sub wikipedia_submit2 {
  my $pageName = shift;
  my $editSummary = shift;
  my $content = shift;

  $pageName = encode("utf-8", $pageName);
  $editSummary = encode("utf-8", $editSummary);
  $content = encode("utf-8", $content); 

  prepare_editor();

  $pageName =~ s/.wiki$//;

  if ( $ws_fake == 1) { 
    print "Fake submission $ws_count: \n";
    print "   page: $pageName<br/>\n";
    open WSOUT, ">>/home/oleg/EditLog";

    # Turns out it's already UTF-8 encoded
#    binmode WSOUT, ":utf8";

    print WSOUT "-------------------- Page: $pageName\n";
    print WSOUT $content;
    print WSOUT "\n";
    print WSOUT "-------------------- END ---------------- \n\n";
    close WSOUT;

    return;
  }

  $_ =  $ws_editor->edit($pageName, $content, $editSummary);
  print "\n";

#  exit;
  return $_;
}


## return success upon loading
1;
