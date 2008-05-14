package WWW::Mediawiki::Client;

use warnings;
use strict;
use File::Spec;
use File::Find;
use LWP::UserAgent;
use HTML::TokeParser;
use HTTP::Request;
use HTTP::Request::Common;
use HTTP::Cookies;
use URI::Escape;
use Algorithm::Diff qw(diff);
use Algorithm::Merge qw(merge);
use Data::Dumper;
use WWW::Mediawiki::Client::Exceptions;

=head1 NAME

WWW::Mediawiki::Client

=cut

=head1 SYNOPSIS
  
  use WWW::Mediawiki::Client;

  my $filename = 'Subject.wiki';
  my $mvs = WWW::Mediawiki::Client->new(
      host => 'www.wikitravel.org'
  );

  # like cvs update
  $mvs->do_update($filename);

  # like cvs commit
  $mvs->do_commit($filename, $message);

  #aliases
  $mvs->do_up($filename);
  $mvs->do_com($filename, $message);

=cut

=head1 DESCRIPTION

WWW::Mediawiki::Client provides a very simple cvs-like interface for
Mediawiki driven WikiWiki websites, such as
L<http://www.wikitravel.org|Wikitravel> or
L<http://www.wikipedia.org|Wikipedia.>  
The interface mimics the two most basic cvs commands: update and commit
with similarly named methods.  Each of these has a shorter alias, as in
cvs.  

=cut

=head1 CONSTANTS

=cut

use constant ACTION => 'action';

use constant TITLE => 'title';

use constant SUBMIT => 'submit';

use constant LOGIN => 'submit';

use constant LOGIN_TITLE => 'Special:Userlogin';

use constant EDIT => 'edit';

# defaults for various known Mediawiki installations
my %DEFAULTS;

$DEFAULTS{'www.wikitravel.org'} =
    {
        'host'          => 'www.wikitravel.org',
        'space_substitute'  => '_',
        'wiki_path'      => 'wiki/__LANG__/index.php',
    };

$DEFAULTS{'www.wikipedia.org'} =
    {
        'host'          => '__LANG__.wikipedia.org',
        'space_substitute'  => '+',
        'wiki_path'      => 'w/wiki.phtml',
    };

use constant SPACE_SUBSTITUTE => '+';
use constant WIKI_PATH => 'wiki/wiki.phtml';
use constant LANGUAGE_CODE => 'en';

=head3 $VERSION 

=cut 

our $VERSION = 0.26;

=head2 Update Status

=head3 STATUS_UNKNOWN

Indicates that C<WWW::Mediawiki::Client> has no information about the file.

=head3 STATUS_UNCHANGED

Indicates that niether the file nor the server page have changed.

=head3 STATUS_LOCAL_ADDED

Indicates that the file is new locally, and does not exist on the server.

=head3 STATUS_LOCAL_MODIFIED

Indicates that the file has been modified locally.

=head3 STATUS_SERVER_MODIFIED

Indicates that the server page was modified, and that the modifications
have been successfully merged into the local file.

=head3 STATUS_CONFLICT

Indicates that there are conflicts in the local file resulting from a
failed merge between the server page and the local file.

=cut

use constant STATUS_UNKNOWN         => '?';
use constant STATUS_UNCHANGED       => '=';
use constant STATUS_LOCAL_ADDED     => 'A';
use constant STATUS_LOCAL_MODIFIED  => 'M';
use constant STATUS_SERVER_MODIFIED => 'U';
use constant STATUS_CONFLICT        => 'C';

=head2 Mediawiki form widgets

=head3 TEXTAREA_NAME

=head3 COMMENT_NAME

=head3 EDIT_SUBMIT_NAME

=head3 EDIT_SUBMIT_VALUE

=head3 EDIT_TIME_NAME

=head3 EDIT_TOKEN_NAME

=head3 EDIT_WATCH_NAME

=head3 EDIT_MINOR_NAME

=head3 CHECKED

=head3 UNCHECKED

=head3 USERNAME_NAME

=head3 PASSWORD_NAME

=head3 REMEMBER_NAME

=head3 LOGIN_SUBMIT_NAME

=head3 LOGIN_SUBMIT_VALUE

=cut

use constant TEXTAREA_NAME      => 'wpTextbox1';
use constant COMMENT_NAME       => 'wpSummary';
use constant EDIT_SUBMIT_NAME   => 'wpSave';
use constant EDIT_SUBMIT_VALUE  => 'Save Page';
use constant EDIT_TIME_NAME     => 'wpEdittime';
use constant EDIT_TOKEN_NAME    => 'wpEditToken';
use constant EDIT_WATCH_NAME    => 'wpWatchthis';
use constant EDIT_MINOR_NAME    => 'wpMinoredit';
use constant CHECKED            => 1;
use constant UNCHECKED          => 0;
use constant USERNAME_NAME      => 'wpName';
use constant PASSWORD_NAME      => 'wpPassword';
use constant REMEMBER_NAME      => 'wpRemember';
use constant LOGIN_SUBMIT_NAME  => 'wpLoginattempt';
use constant LOGIN_SUBMIT_VALUE => 'Log In';

=head2 Files

=head3 CONFIG_FILE

  .mediawiki

=head3 COOKIE_FILE

  .mediawiki.cookies

=head3 SAVED_ATTRIBUTES

Controls which attributes get saved out to the config file.

=cut

use constant CONFIG_FILE => '.mediawiki';
use constant COOKIE_FILE => '.mediawiki_cookies.dat';
use constant SAVED_ATTRIBUTES => (
    qw(site_url host language_code space_substitute username password wiki_path
       watch minor_edit)
);  # It's important that host goes first since it has side effects


=head1 CONSTRUCTORS

=cut

=head2 new

  my $mvs = WWW::Mediawiki::Client->new(host = 'www.wikitravel.org');

Accepts name-value pairs which will be used as initial values for any of
the fields which have accessors below.  Throws the same execptions as the
accessor for any field named.

=cut

sub new {
    my $pkg = shift;
    my %init = @_;
    my $self = bless {};
    $self->load_state;
    foreach my $attr (SAVED_ATTRIBUTES) {
        next unless $init{$attr};
        $self->$attr($init{$attr});
    }
    $self->{ua} = LWP::UserAgent->new();
    my $agent = 'WWW::Mediawiki::Client/' . $VERSION;
    $self->{ua}->agent($agent);
    $self->{ua}->env_proxy;
    my $cookie_jar = HTTP::Cookies->new(
        file => COOKIE_FILE,
        autosave => 1,
    );
    $self->{ua}->cookie_jar($cookie_jar);
    return $self;
}

=head1 ACCESSORS

=cut

=head2 host

  my $url = $mvs->host('www.wikipediea.org');

  my $url = $mvs->host('www.wikitravel.org');

The C<host> is the name of the Mediawiki server from which you want to
obtain content, and to which your submissions will be made.  There is no
default.  This has to be set before attempting to use any of the methods
which attempt to access the server.

B<Side Effects:>

=over 4

=item Server defaults

If WWW::Mediawiki::Client knows about the path settings for the Mediawiki
installation you are trying to use then the various path fields will also
be set as a side-effect.

=item Trailing slashes

Any trailing slashes are deleted I<before> the value of C<host> is set.

=back

=cut

sub host {
    my ($self, $host) = @_;
    if ($host) {
        $host =~ s{/*$}{}; # remove any trailing /s
        $self->{host} = $host;
        my $defaults = $DEFAULTS{$host};
        foreach my $k (keys %$defaults) {
            $self->{$k} = $defaults->{$k};
        }
    }
    return $self->{host};
}

=head2 language_code

  my $lang = $mvs->language_code($lang);

Most Mediawiki projects have multiple language versions.  This field can be
set to target a particular language version of the project the client is
set up to address.  When the C<filename_to_url> and C<pagename_to_url> methods
encounter the text '__LANG__' in any part of their constructed URL the
C<language_code> will be substituted.

C<language_code> defaults to 'en'.

=cut

sub language_code {
    my ($self, $char) = @_;
    $self->{language_code} = $char if $char;
    $self->{language_code} = LANGUAGE_CODE 
            unless $self->{language_code};
    return $self->{language_code};
}

=head2 space_substitute

  my $char = $mvs->space_substitute($char);

Mediawiki allows article names to have spaces, for instance the default
Meidawiki main page is called "Main Page".  The spaces need to be converted
for the URL, and to avoid the normal but somewhat difficult to read URL
escape the Mediawiki software substitutes some other character.  Wikipedia
uses a '+', as in "Main+Page" and Wikitravel uses a '_' as in "Main_page".
WWW::Mediawiki::Client always writes wiki files using the '_', but converts
them to whatever the C<space_substitute> is set to for the URL.

B<Throws:>

=over

=item WWW::Mediawiki::Client::URLConstructionException

=back

=cut

sub space_substitute {
    my ($self, $char) = @_;
    if ($char) {
        WWW::Mediawiki::Client::URLConstructionException->throw(
                "Illegal Character in space_substitute $char" )
            if $char =~ /[\&\?\=\\\/]/;
        $self->{space_substitute} = $char;
    }
    $self->{space_substitute} = SPACE_SUBSTITUTE 
            unless $self->{space_substitute};
    return $self->{space_substitute};
}

=head2 wiki_path

  my $path = $mvs->wiki_path($path);

C<wiki_path> is the path to the php page which handles all request to
edit or submit a page, or to login.  If you are using a Mediawiki site
which WWW::Mediawiki::Client knows about this will be set for you when you
set the C<host>.  Otherwise it defaults to the 'wiki/wiki.phtml' which is
what you'll get if you follow the installation instructions that some with
Mediawiki.

B<Side effects>

=over

=item Leading slashes

Leading slashes in any incoming value will be stripped.

=back

=cut

sub wiki_path {
    my ($self, $wiki_path) = @_;
    if ($wiki_path) {
        $wiki_path =~ s{^/*}{}; # strip leading slashes
        $self->{wiki_path} = $wiki_path;
    }
    $self->{wiki_path} = WIKI_PATH 
            unless $self->{wiki_path};
    return $self->{wiki_path};
}

=head2 username

  my $url = $mvs->username($url);

The username to use if WWW::Mediawiki::Client is to log in to the Mediawiki server as a given
user.

=cut

sub username {
    my ($self, $username) = @_;
    $self->{username} = $username if $username;
    return $self->{username};
}

=head2 password

  my $url = $mvs->password($url);

The password to use if WWW::Mediawiki::Client is to log in to the Mediawiki server as a given
user.  Note that this password is sent I<en clair>, so it's probably not a
good idea to use an important one.

=cut

sub password {
    my ($self, $password) = @_;
    $self->{password} = $password if $password;
    return $self->{password};
}

=head2 commit_message

  my $msg = $mvs->commit_message($msg);

A C<commit_message> must be specified before C<do_commit> can be run.  This
will be used as the comment when submitting pages to the Mediawiki server.

=cut

sub commit_message {
    my ($self, $msg) = @_;
    $self->{commit_message} = $msg if $msg;
    return $self->{commit_message};
}

=head2 watch

  my $bool = $mvs->watch($bool);

Mediawiki allows users to add a page to thier watchlist at submit time
using using the "Watch this page" checkbox.  The field C<watch> allows
commits from this library to add or remove the page in question to/from
your watchlist.

=cut

sub watch {
    my ($self, $m) = @_;
    $self->{watch} = $m if $m;
    $self->{watch} = 0 unless defined $self->{watch};
    return $self->{watch};
}

=head2 minor_edit

  my $bool = $mvs->minor_edit($bool);

Mediawiki allows users to mark some of their edits as minor using the "This
is a minor edit" checkbox.  The field C<minor_edit> allows a commit from
the mediawiki client to be marked as a minor edit.

=cut

sub minor_edit {
    my ($self, $m) = @_;
    $self->{minor_edit} = $m if $m;
    $self->{minor_edit} = 0 unless defined $self->{minor_edit};
    return $self->{minor_edit};
}

=head2 status

  my $status = $mvs->status;

This field will be C<undef> until do_update has been called, after which it
will be set to one of the following (see CONSTANTS for discriptions):

=item WWW::Mediawiki::Client::STATUS_UNKNOWN;

=item WWW::Mediawiki::Client::STATUS_UNCHANGED;

=item WWW::Mediawiki::Client::STATUS_LOCAL_ADDED;

=item WWW::Mediawiki::Client::STATUS_LOCAL_MODIFIED;

=item WWW::Mediawiki::Client::STATUS_SERVER_MODIFIED;

=item WWW::Mediawiki::Client::STATUS_CONFLICT;

=cut

sub status {
    my ($self, $arg) = @_;
    WWW::Mediawiki::Client::ReadOnlyFieldException->throw(
            "Tried to set read-only field 'status' to $arg.") if $arg;
    return $self->{status};
}

=head2 site_url DEPRICATED

  my $url = $mvs->site_url($url);

The site URL is the base url for reaching the Mediawiki server who's
content you wish to edit.  This field is now depricated in favor of the
C<host> field which is basically the same thing without the protocol
string.


B<Side Effects:>

=over 4

=item Server defaults

If WWW::Mediawiki::Client knows about the path settings for the Mediawiki
installation you are trying to use then the various path fields will also
be set as a side-effect.

=item Trailing slashes

Any trailing slashes are deleted I<before> the value of C<site_url> is set.

=back

=cut

sub site_url {
    my ($self, $host) = @_;
    my ($pkg, $caller, $line) = caller;
    warn "Using depricated method 'site_url' at $caller line $line."
            unless $pkg =~ "WWW::Mediawiki::Client";
    $host =~ s{^http://}{} if $host;
    $host = $self->host($host);
    return "http://" . $host if $host;
}

=head1 Instance Methods

=cut

=head2 do_login

  $mvs->do_login;

The C<do_login> method operates like the cvs login command.  The
C<host>, C<username>, and C<password> attributes must be set before
attempting to login.  Once C<do_login> has been called successfully any
successful commit from the same directory will be logged in the Mediawiki
server as having been done by C<username>.

B<Throws:>

=over

=item WWW::Mediawiki::Client::AuthException

=item WWW::Mediawiki::Client::CookieJarException

=item WWW::Mediawiki::Client::LoginException

=item WWW::Mediawiki::Client::URLConstructionException

=back

=cut

sub do_login {
    my $self = shift;
    WWW::Mediawiki::Client::URLConstructionException->throw(
            "No Mediawiki host specified.")
            unless $self->{host};
    WWW::Mediawiki::Client::URLConstructionException->throw(
            "No wiki_path specified.")
            unless $self->{wiki_path};
    WWW::Mediawiki::Client::AuthException->throw(
        "Must have username and password to login.")
            unless $self->{username} && $self->{password};
    my $host = $self->host;
    my $path = $self->wiki_path;
    my $lang = $self->language_code;
    $host =~ s/__LANG__/$lang/;
    $path =~ s/__LANG__/$lang/;
    my $url = "http://$host/$path"
            . "?" . ACTION . "=" . LOGIN
            . "&" . TITLE  . "=" . LOGIN_TITLE;
    $self->{ua}->cookie_jar->clear;
    $self->{ua}->cookie_jar->save
            or WWW::Mediawiki::Client::CookieJarException->throw(
            "Could not save cookie jar.");
    my $res = $self->{ua}->request(POST $url,
        [ 
            &USERNAME_NAME      => $self->{username},
            &PASSWORD_NAME      => $self->{password},
            &REMEMBER_NAME      => 1,
            &LOGIN_SUBMIT_NAME  => &LOGIN_SUBMIT_VALUE,
        ]
    );
    # success == Mediawiki gave us a Password cookie
    if ($self->{ua}->cookie_jar->as_string =~ /UserID=/) {
        $self->save_state;
        $self->{ua}->cookie_jar->save
                or WWW::Mediawiki::Client::CookieJarException->throw(
                "Could not save cookie jar.");
        return $self;
    } elsif ($res->is_success) {  # got a page, but not what we wanted
        WWW::Mediawiki::Client::LoginException->throw(
                error => "Login did not work, please check username and password.\n",
                res => $res,
                cookie_jar => $self->{ua}->cookie_jar,
            );
    } else { # something else went wrong, send all the data in exception
        my $err = "Login to $url failed.";
        WWW::Mediawiki::Client::LoginException->throw(
                error => $err, 
                res => $res,
                cookie_jar => $self->{ua}->cookie_jar,
            );
    }
}

=head2 do_li
  
  $mvs->do_li;

An alias for C<do_login>.

=cut

sub do_li {
    do_login(@_);
}

=head2 do_update
  
  $self->do_update($filename, ...);

The C<do_update> method operates like a much-simplified version of the cvs
update command.  The argument is a list of filenames, whose contents will
be compared to the version on the WikiMedia server and to a locally stored
reference copy.  Lines which have changed only in the server version will
be merged into the local version, while lines which have changed in both
the server and local version will be flagged as possible conflicts, and
marked as such, somewhate in the manner of cvs (actually this syntax comes
from the default conflict behavior of Algorithm::Merge):

  <!-- ------ START CONFLICT ------ -->
  The line as it appears on the server
  <!-- ---------------------------- -->
  The line as it appears locally
  <!-- ------  END  CONFLICT ------ -->

After the merging, and conflict marking is complete the server version will
be copied into the reference version.

If either the reference version or the local version are empty, or if
either file does not exist they will both be created as a copy of the
current server version.

B<Throws:>

=over

=item WWW::Mediawiki::Client::URLConstructionException

=item WWW::Mediawiki::Client::FileAccessException

=item WWW::Mediawiki::Client::FileTypeException

=item WWW::Mediawiki::Client::ServerPageException

=item WWW::Mediawiki::Client::AbsoluteFileNameException

=back

=cut

sub do_update {
    my $self = shift;
    my $filename = shift;
    WWW::Mediawiki::Client::URLConstructionException->throw(
            "No server URL specified.") unless $self->{host};
    my ($vol, $dirs, $fn) = $self->_check_path($filename);
    my $sv = $self->get_server_page($self->filename_to_pagename($filename));
    my $lv = $self->get_local_page($filename);
    my $rv = $self->_get_reference_page($filename);
    my $nv = $self->_merge($filename, $rv, $sv, $lv);
    $self->{status} = $self->_get_update_status($rv, $sv, $lv, $nv);
    return unless $self->{status};  # nothing changes, nothing to do
    return $self->{status} 
            if $self->{status} eq STATUS_LOCAL_ADDED
                or $self->{status} eq STATUS_UNKNOWN
                or $self->{status} eq STATUS_UNCHANGED;
    # save the newly retrieved and/or merged version as our local copy
    my @dirs = split '/', $dirs;
    for my $d (@dirs) {
        mkdir $d;
        chdir $d;
    }
    for (@dirs) {
        chdir '..';
    }
    open OUT, ">$filename" or WWW::Mediawiki::Client::FileAccessException->throw(
            "Cannot open $filename for writing.");
    print OUT $nv;
    # save the server version out as the reference file
    $filename = $self->_get_ref_filename($filename);
    open OUT, ">$filename" or WWW::Mediawiki::Client::FileAccessException->throw(
            "Cannot open $filename for writing.");
    print OUT $sv;
    close OUT;
    return $self->{status};
}

=head2 do_up

An alias for C<do_update>.

=cut

sub do_up {
    do_update(@_);
}

=head2 do_commit
  
  $self->do_commit($filename);

As with C<do_update> the C<do_commit> method operates like a much
simplified version of the cvs commit command.  Again, the argument is a
filename.  In keeping with the operation of cvs, C<do_commit> does not
automatically do an update, but does check the server version against the
local reference copy, throwing an error if the server version has changed,
thus forcing the user to do an update.  A different error is thrown if the
conflict pattern sometimes created by C<do_update> is found.

After the error checking is done the local copy is submitted to the server,
and, if all goes well, copied to the local reference version.

B<Throws:>

=over

=item WWW::Mediawiki::Client::CommitMessageException

=item WWW::Mediawiki::Client::ConflictsPresentException

=item WWW::Mediawiki::Client::FileAccessException

=item WWW::Mediawiki::Client::FileTypeException

=item WWW::Mediawiki::Client::URLConstructionException

=item WWW::Mediawiki::Client::UpdateNeededException

=back

=cut

sub do_commit {
    my ($self, $filename) = @_;
    WWW::Mediawiki::Client::CommitMessageException->throw(
            "No commit message specified")
        unless $self->{commit_message};
    WWW::Mediawiki::Client::URLConstructionException->throw(
            "No server URL specified.") unless $self->{host};
    WWW::Mediawiki::Client::FileAccessException->throw("No such file!") 
        unless -e $filename;
    my $text = $self->get_local_page($filename);
    my $sp = $self->get_server_page($self->filename_to_pagename($filename));
    my $ref = $self->_get_reference_page($filename);
    chomp ($text, $sp, $ref);
    WWW::Mediawiki::Client::UpdateNeededException->throw(
            error => $self->filename_to_pagename($filename) 
                   . " has changed on the server.",
        ) unless $sp eq $ref;
    WWW::Mediawiki::Client::ConflictsPresentException->throw(
            "$filename appears to have unresolved conflicts")
        if $self->_conflicts_found_in($text);
    my $minorbox = $self->{minor_edit} ? EDIT_MINOR_NAME : '';
    my $watchbox = $self->{watch} ? EDIT_WATCH_NAME : '';
    my $url = $self->filename_to_url($filename, SUBMIT);
    my $res = $self->{ua}->request(POST $url,
        [ 
            &TEXTAREA_NAME      => $text,
            &COMMENT_NAME       => $self->{commit_message},
            &EDIT_SUBMIT_NAME   => &EDIT_SUBMIT_VALUE,
            &EDIT_TIME_NAME     => $self->{server_date},
            &EDIT_TOKEN_NAME    => $self->{server_token},
            $watchbox           => $self->{watch} ? CHECKED : UNCHECKED,
            $minorbox           => $self->{minor_edit} ? CHECKED : UNCHECKED,
        ]
    );
    # save the local version as the reference version
    my $refname = $self->_get_ref_filename($filename);
    open OUT, ">$refname" or WWW::Mediawiki::Client::FileAccessException->throw(
            "Cannot open $refname for writing.");
    print OUT $text;
    close OUT;
}

=head2 do_com

This is an alias for C<do_commit>.

=cut

sub do_com {
    do_commit(@_);
}

=head2 save_state
  
  $mvs->save_state;

Saves the current state of the wmc object in the current working directory.

B<Throws:>

=over

=item WWW::Mediawiki::Client::FileAccessException

=back

=cut

sub save_state {
    my $self = shift;
    my $conf = CONFIG_FILE;
    my %init;
    foreach my $attr (SAVED_ATTRIBUTES) {
        $init{$attr} = $self->$attr;
    }
    open OUT, ">$conf" or WWW::Mediawiki::Client::FileAccessException->throw(
            "Cannot write to config file, $conf.");
    print OUT Dumper(\%init);
    close OUT;
}

=head2 load_state

  $mvs = $mvs->load_state;

Loads the state of the wmc object from that saved in the current working
directory.

B<Throws:>

=over

=item WWW::Mediawiki::Client::CorruptedConfigFileException

=back

=cut

sub load_state {
    my $self = shift;
    my $config = CONFIG_FILE;
    return $self unless -e $config;
    our $VAR1;
    do $config or 
            WWW::Mediawiki::Client::CorruptedConfigFileException->throw(
            "Could not read config file: $config.");
    my %init = %$VAR1;
    foreach my $attr (SAVED_ATTRIBUTES) {
        $self->$attr($init{$attr});
    }
    return $self;
}

=head2 get_server_page

  my $wikitext = $mvs->get_server_page($pagename);

Returns the wikitext of the given Mediawiki page name.

B<Throws:>

=over

=item WWW::Mediawiki::Client::ServerPageException

=back

=cut

sub get_server_page {
    my ($self, $pagename) = @_;
    my $url = $self->pagename_to_url($pagename, EDIT);
    my $res = $self->{ua}->get($url);
    WWW::Mediawiki::Client::ServerPageException->throw(
            error => "Couldn't fetch \"$pagename\" from the server.",
            res => $res,
        ) unless $res->is_success;
    my $doc = $res->content;
    my $text = $self->_get_wiki_text($doc);
    $self->{server_date} = $self->_get_edit_date($doc);
    $self->{server_token} = $self->_get_edit_token($doc);
    my $headline = $self->_get_page_headline($doc);
    unless (lc($headline) eq lc("Editing $pagename")) {
        WWW::Mediawiki::Client::ServerPageException->throw(
	        error => "The server could not resolve the page name
                        '$pagename', but responded that it was '$headline'.",
                res   => $res,
            ) if ($headline && $headline =~ /^Editing /);
        WWW::Mediawiki::Client::ServerPageException->throw(
	        error => "Error message from the server: '$headline'.",
                res   => $res,
            ) if ($headline);
        WWW::Mediawiki::Client::ServerPageException->throw(
                error => "Could not identify the error in this context.",
                res   => $res,
            );
    }
    chomp $text;
    return $text;
}

=head2 get_local_page

  my $wikitext = $mvs->get_local_page($filename);

Returns the wikitext from the given local file;

B<Throws:>

=over

=item WWW::Mediawiki::Client::FileAccessException

=item WWW::Mediawiki::Client::FileTypeException

=item WWW::Mediawiki::Client::AbsoluteFileNameException 

=back

=cut

sub get_local_page {
    my ($self, $filename) = @_;
    $self->_check_path($filename);
    return '' unless -e $filename;
    open IN, $filename or 
            WWW::Mediawiki::Client::FileAccessException->throw(
            "Cannot open $filename.");
    local $/;
    my $text = <IN>;
    close IN;
    return $text;
}

=head2 pagename_to_url

  my $url = $mvs->pagename_to_url($pagename);

Returns the url at which a given pagename will be found on the Mediawiki
server to which this instance of points.

B<Throws:>

=over

=item WWW::Mediawiki::Client::URLConstructionException;

=back

=cut

sub pagename_to_url {
    my ($self, $name, $action) = @_;
    WWW::Mediawiki::Client::URLConstructionException->throw(
            error => 'No action supplied.',
        ) unless $action;
    WWW::Mediawiki::Client::URLConstructionException->throw(
            error => "Page name $name ends with '.wiki'.",
        ) if $name =~ /.wiki$/;
    my $char = $self->space_substitute;
    $name =~ s/ /$char/;
    my $lang = $self->language_code;
    my $host = $self->host;
    $host =~ s/__LANG__/$lang/g;
    my $wiki_path = $self->wiki_path;
    $wiki_path =~ s/__LANG__/$lang/g;
    return "http://$host/$wiki_path?" . ACTION . "=$action&" . TITLE . "=$name";
}

=head2 filename_to_pagename

  my $pagename = $mvs->filname_to_pagename($filename);

Returns the cooresponding server page name given a filename.

B<Throws:>

=over

=item WWW::Mediawiki::Client::AbsoluteFileNameException

=item WWW::Mediawiki::Client::FileTypeException 

=back

=cut

sub filename_to_pagename {
    my ($self, $name) = @_;
    $self->_check_path($name);
    $name =~ s/.wiki$//;
    $name =~ s/_/ /g;
    return ucfirst $name;
}

=head2 filename_to_url

  my $pagename = $mvs->filname_to_url($filename);

Returns the cooresponding server URL given a filename.

B<Throws:>

=over

=item WWW::Mediawiki::Client::AbsoluteFileNameException

=item WWW::Mediawiki::Client::FileTypeException 

=back

=cut

sub filename_to_url {
    my ($self, $name, $action) = @_;
    $name = $self->filename_to_pagename($name);
    return $self->pagename_to_url($name, $action);
}

=head2 pagename_to_filename

  my $filename = $mvs->pagename_to_filename($pagename);

Returns a local filename which cooresponds to the given Mediawiki page
name.

=cut

sub pagename_to_filename {
    my ($self, $name) = @_;
    $name =~ s/ /_/;
    $name .= '.wiki';
    return $name;
}

=head2 url_to_filename
  
  my $filename = $mvs->url_to_filename($url);

Returns the local filename which cooresponds to a given URL.

=cut

sub url_to_filename {
    my ($self, $url) = @_;
    my $char = '\\' . $self->space_substitute;
    $url =~ s/$char/_/g;
    $url =~ m/&title=([^&]*)/;
    return "$1.wiki";
}

=head2 list_wiki_files

  @filenames = $mvs->list_wiki_files;

Returns a recursive list of all wikitext files in the local repository.

=cut

sub list_wiki_files {
    my $self = shift;
    my @files;
    my $dir = File::Spec->curdir();
    find(sub { 
        return unless /^[^.].*\.wiki\z/s;
        my $name = $File::Find::name;
        $name = File::Spec->abs2rel($name);
        push @files, $name;
    }, $dir);
    return @files;
}

=begin comment

=head1 Private Methods

=cut

sub _merge {
    my ($self, $filename, $ref, $server, $local) = @_;
    my @r = split /\n/, $ref;
    my @s = split /\n/, $server;
    my @l = split /\n/, $local;
    my @merged;
    eval { @merged = merge(\@r, \@s, \@l) };
    return join "\n", @merged;
}

sub _get_wiki_text {
    my ($self, $doc) = @_;
    my $p = HTML::TokeParser->new(\$doc);
    $p->get_tag("textarea");
    my $text = $p->get_text;
    $text =~ s///gs;                      # convert endlines
    return $text;
}

sub _get_page_headline {
    my ($self, $doc) = @_;
    my $p = HTML::TokeParser->new(\$doc);
    $p->get_tag("h1");
    my $text = $p->get_text;
    $text =~ s///gs;                      # convert endlines
    return $text;
}

sub _get_edit_date {
    my ($self, $doc) = @_;
    my $p = HTML::TokeParser->new(\$doc);
    my $date;
    while (my $tag = $p->get_tag('input')) {
        next unless $tag->[1]->{type} eq 'hidden';
        next unless $tag->[1]->{name} eq EDIT_TIME_NAME;
        $date = $tag->[1]->{value};
    }
    return $date;
}

sub _get_edit_token {
    my ($self, $doc) = @_;
    my $p = HTML::TokeParser->new(\$doc);
    my $token;
    while (my $tag = $p->get_tag('input')) {
        next unless $tag->[1]->{type} eq 'hidden';
        next unless $tag->[1]->{name} eq 'wpEditToken';
        $token = $tag->[1]->{value};
    }
    return $token;
}

sub _check_path {
    my ($self, $filename) = @_;
    WWW::Mediawiki::Client::FileTypeException->throw(
            "'$filename' doesn't appear to be a wiki file.")
            unless $filename =~ /\.wiki$/;
    WWW::Mediawiki::Client::AbsoluteFileNameException->throw(
            "No absolute filenames allowed!")
            if File::Spec->file_name_is_absolute($filename);
    return File::Spec->splitpath($filename);
}

sub _get_reference_page {
    my ($self, $filename) = @_;
    return '' unless -e $filename;
    $filename = $self->_get_ref_filename($filename);
    my $ref = $self->get_local_page($filename);
    return $ref;
}

sub _get_ref_filename {
    my ($self, $filename) = @_;
    WWW::Mediawiki::Client::FileTypeException->throw(
            "Not a .wiki file.") unless $filename =~ /\.wiki$/;
    my ($vol, $dirs, $fn) = File::Spec->splitpath($filename);
    $fn =~ s/(.*)\.wiki/.$1.ref.wiki/;
    return File::Spec->catfile('.', $dirs, $fn);
}

sub _conflicts_found_in {
    my ($self, $text) = @_;
    return 1 if $text =~ /^<!-- ------ START CONFLICT ------ -->$/m;
    return 0;
}

sub _get_update_status {
    my ($self, $rv, $sv, $lv, $nv) = @_;
    chomp ($rv, $sv, $lv, $nv);
    my $status = STATUS_UNKNOWN;
    return $status unless $sv || $lv;
    $status = STATUS_UNCHANGED if $sv eq $lv;
    $status = STATUS_LOCAL_MODIFIED if $lv ne $rv;
    $status = STATUS_SERVER_MODIFIED if $sv && $rv ne $sv;
    $status = STATUS_LOCAL_ADDED unless $sv;
    $status = STATUS_CONFLICT if $self->_conflicts_found_in($nv);
    return $status;
}

1;

__END__

=end comment

=head1 AUTHORS

=item Mark Jaroski <mark@geekhive.net> 

Author

=item Mike Wesemann <mike@fhi-berlin.mpg.de>

Added support for Mediawiki 1.3.10+ edit tokens

=item Bernhard Kaindl <bkaindl@ffii.org>

Improved error messages.

=head1 LICENSE

Copyright (c) 2004 Mark Jaroski. 

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

