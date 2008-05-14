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
use Algorithm::Diff::Apply qw(apply_diffs);
use Carp qw(croak carp confess);
use Data::Dumper;

=head1 NAME

WWW::Mediawiki::Client

=cut

=head1 SYNOPSIS
  
  use WWW::Mediawiki::Client;

  my $filename = 'Subject.wiki';
  my $wmc = WWW::Mediawiki::Client->new(
      site_url => 'http://www.wikitravel.org/en'
  );

  # output info messages, but not debug
  $wmc->set_output_level(WWW::Mediawiki::Client::INFO);

  # like cvs update
  $wmc->do_update($filename);

  # like cvs commit
  $wmc->do_commit($filename, $message);

  #aliases
  $wmc->do_up($filename);
  $wmc->do_com($filename, $message);

=cut

=head1 DESCRIPTION

WWW::Mediawiki::Client provides a very simple cvs-like interface for
Mediawiki driven WikiWiki websites, such as
L<http://www.wikitravel.org|Wikitravel> or
L<http://www.wikipedia.org|Wikipedia.>  The interface mimics the two most
basic cvs commands: update and commit with similarly named methods.  Each
of these has a shorter alias, as in cvs.  Verbosity is controled through an
output_level accessor method.

=cut

##############################################################################
# Constants                                                                  #
##############################################################################
# output level definitions
use constant QUIET => -1;
use constant ERROR => 0;
use constant INFO => 1;
use constant DEBUG => 2;
# update status
use constant STATUS_UNKNOWN         => '?';
use constant STATUS_ADD             => 'A';
use constant STATUS_LOCAL_MODIFIED  => 'M';
use constant STATUS_SERVER_MODIFIED => 'U';
use constant STATUS_CONFLICT        => 'C';
# for saving attributes
use constant SAVED_ATTRIBUTES => (
    qw(action_path edit_path login_path space_substitute
       username password site_url output_level)
);
# constants which derive from Mediawiki
use constant URL_SPACE_SUBSTITUTE => '+';
# URL components
use constant EDIT_PATH => 
        'wiki/wiki.phtml?action=edit&title=';
use constant ACTION_PATH => 
        'wiki/wiki.phtml?action=submit&title=';
use constant LOGIN_PATH => 
        'wiki/wiki.phtml?action=submit&title=Special:Userlogin';
# edit form widgets
use constant TEXTAREA_NAME      => 'wpTextbox1';
use constant COMMENT_NAME       => 'wpSummary';
use constant EDIT_SUBMIT_NAME   => 'wpSave';
use constant EDIT_SUBMIT_VALUE  => 'Save Page';
use constant EDIT_TIME_NAME     => 'wpEdittime';
use constant EDIT_TOKEN_NAME    => 'wpEditToken';
use constant EDIT_WATCH_NAME    => 'wpWatchthis';
use constant EDIT_MINOR_NAME    => 'wpMinoredit';
# login form widgets
use constant USERNAME_NAME      => 'wpName';
use constant PASSWORD_NAME      => 'wpPassword';
use constant REMEMBER_NAME      => 'wpRemember';
use constant LOGIN_SUBMIT_NAME  => 'wpLoginattempt';
use constant LOGIN_SUBMIT_VALUE => 'Log In';
# our files
use constant CONFIG_FILE => '.mediawiki';
use constant COOKIE_FILE => '.mediawiki_cookies.dat';
# stuff for perlism
our $VERSION = 0.23;

=head1 CONSTRUCTORS

=head2 new

  my $wmc = WWW::Mediawiki::Client->new(site_url = 'http://www.wikitravel.org');

Accepts name-value pairs which will be used as initial values for any of
the fields which have accessors below.  Throws the same execptions as the
accessor for any field named.

=cut

sub new {
    my $pkg = shift;
    my %init = @_;
    my $self = bless {};
    $self->output_level(INFO);
    $self->edit_path(EDIT_PATH);
    $self->action_path(ACTION_PATH);
    $self->login_path(LOGIN_PATH);
    $self->space_substitute(URL_SPACE_SUBSTITUTE);
    $self->load_state;
    $self->output_level($init{output_level});
    $self->site_url($init{site_url});
    $self->edit_path($init{edit_path});
    $self->action_path($init{action_path});
    $self->login_path($init{login_path});
    $self->username($init{username});
    $self->password($init{password});
    $self->space_substitute($init{space_substitute});
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
};

=head1 ACCESSORS

=head2 site_url

  my $url = $wmc->site_url($url);

The site URL is the base url for reaching the Mediawiki server who's
content you wish to edit.  There is no default.  This has to be set before
attempting to use any of the methods which attempt to access the server.

=cut

sub site_url {
    my ($self, $site_url) = @_;
    $self->{site_url} = $site_url if $site_url;
    return $self->{site_url};
}

=head2 site_url

  my $char = $wmc->space_substitute($char);

Mediawiki allows article names to have spaces, for instance the default
Meidawiki main page is called "Main Page".  The spaces need to be converted
for the URL, and to avoid the normal but somewhat difficult to read URL
escape the Mediawiki software substitutes some other character.  Wikipedia
uses a '+', as in "Main+Page" and Wikitravel uses a '_' as in "Main_page".
WWW::Mediawiki::Client always writes wiki files using the '_', but converts
them to whatever the C<space_substitute> is set to for the URL.

=cut

sub space_substitute {
    my ($self, $char) = @_;
    $self->{space_substitute} = $char if $char;
    return $self->{space_substitute};
}

=head2 username

  my $url = $wmc->username($url);

The username to use if WWW::Mediawiki::Client is to log in to the Mediawiki server as a given
user.

=cut

sub username {
    my ($self, $username) = @_;
    $self->{username} = $username if $username;
    return $self->{username};
}

=head2 password

  my $url = $wmc->password($url);

The password to use if WWW::Mediawiki::Client is to log in to the Mediawiki server as a given
user.  Note that this password is sent I<en clair>, so it's probably not a
good idea to use an important one.

=cut

sub password {
    my ($self, $password) = @_;
    $self->{password} = $password if $password;
    return $self->{password};
}

=head2 edit_path

  my $path = $wmc->edit_path($path);

The edit path is a string which given the site URL and a page name can be
used to construct the balance of the URL to the edit page for that page on
the wikimedia server.  You shouldn't have to worry about this unless the
Mediawiki software on your server has been altered or is very out-of-date.

=cut

sub edit_path {
    my ($self, $edit_path) = @_;
    $self->{edit_path} = $edit_path if $edit_path;
    return $self->{edit_path};
}

=head2 action_path

  my $path = $wmc->action_path($path);

The action path is a string which given the site URL and a page name can be
used to construct the balance of the URL to the action page for that page on
the wikimedia server.  You shouldn't have to worry about this unless the
Mediawiki software on your server has been altered or is very out-of-date.

=cut

sub action_path {
    my ($self, $action_path) = @_;
    $self->{action_path} = $action_path if $action_path;
    return $self->{action_path};
}

=head2 login_path

  my $path = $wmc->login_path($path);

The login path is a string which given the site URL and a page name can be
used to construct the balance of the URL to the login page for that page on
the wikimedia server.  You shouldn't have to worry about this unless the
Mediawiki software on your server has been altered or is very out-of-date.

=cut

sub login_path {
    my ($self, $login_path) = @_;
    $self->{login_path} = $login_path if $login_path;
    return $self->{login_path};
}

=head2 output_level

  my $ol = $wmc->output_level(WWW::Mediawiki::Client::INFO);

This output level accessor provides for verbosity control.  There are a
number of different output levels:

=over

=item WWW::Mediawiki::Client::QUIET

=item WWW::Mediawiki::Client::ERROR

=item WWW::Mediawiki::Client::INFO

=item WWW::Mediawiki::Client::DEBUG

=back

=cut

sub output_level {
    my ($self, $ol) = @_;
    return $self->{output_level} unless $ol;
    my $null = File::Spec->devnull;
    eval {
        open $self->{debug_fh}, ">$null";
        open $self->{info_fh}, ">$null";
        open $self->{error_fh}, ">$null";
    } or confess "Couldn't open $null.";
    open $self->{debug_fh}, ">&STDERR"
            or confess "Couldn't dup STDERR."
            if $ol >= DEBUG;
    open $self->{info_fh}, ">&STDERR"
            or confess "Couldn't dup STDERR."
            if $ol >= INFO;
    open $self->{error_fh}, ">&STDERR"
            or confess "Couldn't dup STDERR."
            if $ol >= ERROR;
    return $self->{output_level} = $ol;
};

=head2 commit_message

  my $msg = $wmc->commit_message($msg);

A C<commit_message> must be specified before C<do_commit> can be run.  This
will be used as the comment when submitting pages to the Mediawiki server.

=cut

sub commit_message {
    my ($self, $msg) = @_;
    $self->{commit_message} = $msg if $msg;
    return $self->{commit_message};
}

=head1 Instance Methods

=head2 do_login

  $wmc->do_login;

The C<do_login> method operates like the cvs login command.  The
C<site_url>, C<username>, and C<password> attributes must be set before
attempting to login.  Once C<do_login> has been called successfully any
successful commit from the same directory will be logged in the Mediawiki
server as having been done by C<username>.

=cut

sub do_login {
    my $self = shift;
    croak "No server URL specified." unless $self->{site_url};
    croak "Must have username and password to login."
            unless $self->{username} && $self->{password};
    print { $self->{info_fh} } 
            "Loging in as " . $self->{username} . "\n";
    my $url = $self->{site_url} . '/' . $self->{login_path};
    my $username_tag = USERNAME_NAME;
    my $password_tag = PASSWORD_NAME;
    my $remember_tag = REMEMBER_NAME;
    my $submit_tag = LOGIN_SUBMIT_NAME;
    my $submitval = LOGIN_SUBMIT_VALUE;
    my $res = $self->{ua}->request(POST $url,
        [ 
            $username_tag   => $self->{username},
            $password_tag   => $self->{password},
            $remember_tag   => 1,
            $submit_tag     => $submitval,
        ]
    );
    print { $self->{debug_fh} } "Saving cookie jar.\n";
    $self->{ua}->cookie_jar->save
            or croak "Could not save cookie jar.";
    $self->save_state;
    return $self;
}

=head2 do_li
  
  $wmc->do_li;

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
from the default conflict behavior of Algorithm::Diff::Apply):

  >>>>>> http://server.somewiki.org/en
  The line as it appears on the server
  >>>>>> Filename.wiki
  The line as it appears locally
  <<<<<<

After the merging, and conflict marking is complete the server version will
be copied into the reference version.

If either the reference version or the local version are empty, or if
either file does not exist they will both be created as a copy of the
current server version.

B<Throws:>

=over

=item CouldNotGetServerVersion

=back

=cut

sub do_update {
    my $self = shift;
    my $filename = shift;
    croak "No server URL specified." unless $self->{site_url};
    print { $self->{debug_fh} } "Updating: $filename\n";
    $self->_check_path($filename);
    my $sv = $self->_get_server_page($filename);
    my $lv = $self->_get_local_page($filename);
    my $rv = $self->_get_reference_page($filename);
    my $nv = $self->_merge($filename, $rv, $sv, $lv);
    my $status = $self->_get_update_status($rv, $sv, $lv, $nv);
    print { $self->{info_fh} } "$status $filename\n" 
            if $status;
    # save the new merged version as our local copy
    return unless $status;  # nothing changes, nothing to do
    return if $status eq STATUS_ADD;
    open OUT, ">$filename" or confess "Cannot open $filename for writing.";
    print OUT $nv;
    # save the server version out as the reference file
    $filename = $self->_get_ref_filename($filename);
    open OUT, ">$filename" or confess "Cannot open $filename for writing.";
    print OUT $sv;
    close OUT;
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

=item UpdateNeeded

=item ConflictsPresent

=item CouldNotGetServerVersion

=item UploadFailed

=back

=cut

sub do_commit {
    my $self = shift;
    my $filename = shift;
    croak "No commit message specified" 
            unless $self->{commit_message};
    croak "No server URL specified." unless $self->{site_url};
    print { $self->{info_fh} } "commiting $filename\n";
    croak "No such file!" unless -e $filename;
    my $lv = $self->_get_local_page($filename);
    my $sv = $self->_get_server_page($filename);
    my $rv = $self->_get_reference_page($filename);
    chomp ($lv, $sv, $rv);
    return if $sv eq $lv;
    croak "$filename has changed on the server. "
            ."Please do an update and try again"
            unless $sv eq $rv;
    croak "$filename appears to have unresolved conflicts"
            if $self->_conflicts_found_in($lv);
    $self->_upload($filename, $lv);
    # save the local version as the reference version
    $filename = $self->_get_ref_filename($filename);
    open OUT, ">$filename" or die "Cannot open $filename for writing.";
    print OUT $lv;
    close OUT;
}

=head2 do_com

This is an alias for C<do_commit>.

=cut

sub do_com {
    do_commit(@_);
}

=head2 save_state
  
  $wmc->save_state;

Saves the current state of the wmc object in the current working directory.

=cut

sub save_state {
    my $self = shift;
    my $conf = CONFIG_FILE;
    my %init;
    foreach my $attr (SAVED_ATTRIBUTES) {
        $init{$attr} = $self->{$attr};
    }
    open OUT, ">$conf" or croak "Cannot write to config file.";
    print OUT Dumper(\%init);
    close OUT;
}

=head2 load_state

  $wmc = $wmc->load_state;

Loads the state of the wmc object from that saved in the current working
directory.

=cut

sub load_state {
    my $self = shift;
    my $conffile = CONFIG_FILE;
    return $self unless -e $conffile;
    my $VAR1;
    local $/;
    open IN, $conffile or croak "Could not open config";
    my $config = <IN>;
    close IN;
    eval $config
            or croak "Could not read corrupted config file: $config.";
    my %init = %$VAR1;
    foreach my $attr (SAVED_ATTRIBUTES) {
        $self->$attr($init{$attr});
    }
    return $self;
}


=begin comment

=head1 Private Methods

=cut

sub _merge {
    my ($self, $filename, $ref, $server, $local) = @_;
    my @r = split /\n/, $ref;
    my @s = split /\n/, $server;
    my @l = split /\n/, $local;
    my $sdiff = diff(\@r, \@s);
    my $ldiff = diff(\@r, \@l);
    my @merged = apply_diffs(\@r,
        $self->site_url()   => $sdiff,
        $filename           => $ldiff,
    );
    return join "\n", @merged;
}

sub _upload {
    my ($self, $filename, $text) = @_;
    print { $self->{debug_fh} } "Sending $filename";
    my $url = $self->_filename_to_action_url($filename);
    my $ref = $self->_get_ref_filename($filename);
    my $edit_time = $self->{server_date};
    my $edit_token = $self->{server_token};
    # take field names from defined constants
    my $textbox = TEXTAREA_NAME;
    my $comment = COMMENT_NAME;
    my $subname = EDIT_SUBMIT_NAME;
    my $subvalue = EDIT_SUBMIT_VALUE;
    my $timename = EDIT_TIME_NAME;
    my $tokenname = EDIT_TOKEN_NAME;
    my $watchbox = EDIT_WATCH_NAME;
    print { $self->{debug_fh} } " to $url.\n";
    my $res = $self->{ua}->request(POST $url,
        [ 
            $textbox    => $text,
            $comment    => $self->{commit_message},
            $subname    => $subvalue,
            $timename   => $edit_time,
            $tokenname   => $edit_token,
            $watchbox   => 1,
        ]
    );
}

sub _get_server_page {
    my ($self, $filename) = @_;
    my $url = $self->_filename_to_edit_url($filename);
    print { $self->{debug_fh} }"Fetching $url\n";
    my $res = $self->{ua}->get($url);
    croak "Couldn't fetch $filename from the server."
            . "HTTP get failed with: " . $res->code
            unless $res->is_success;
    my $doc = $res->content;
    my $text = $self->_get_wiki_text($doc);
    $self->{server_date} = $self->_get_edit_date($doc);
    $self->{server_token} = $self->_get_edit_token($doc);
    return $text;
}

sub _get_wiki_text {
    my ($self, $doc) = @_;
    my $p = HTML::TokeParser->new(\$doc);
    $p->get_tag("textarea");
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
        next unless $tag->[1]->{name} eq 'wpEdittime';
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

sub _get_local_page {
    my ($self, $filename) = @_;
    print { $self->{debug_fh} } "Loading $filename\n";
    return '' unless -e $filename;
    open IN, $filename or die "Cannot open $filename.";
    local $/;
    my $text = <IN>;
    close IN;
    return $text;
}

sub _check_path {
    my ($self, $filename) = @_;
    die "A filename ending in '.wiki'. is required." 
            unless $filename or ! $filename =~ /\.wiki$/;
    die "No absolute filenames allowed!\n"
            if File::Spec->file_name_is_absolute($filename);
    my ($vol, $dirs, $fn) = File::Spec->splitpath($filename);
    mkdir $dirs;
}

sub _get_reference_page {
    my ($self, $filename) = @_;
    return '' unless -e $filename;
    $filename = $self->_get_ref_filename($filename);
    my $ref = $self->_get_local_page($filename);
    return $ref;
}

sub _filename_to_url {
    my ($self, $filename, $path) = @_;
    confess "Not a .wiki file." unless $filename =~ s/\.wiki$//;
    confess "No URL path specified." unless $path;
    my $site_url = $self->{site_url};
    my ($vol, $dirs, $fn) = File::Spec->splitpath($filename);
    my @dir = File::Spec->splitdir($dirs);
    my $char = $self->{space_substitute};
    $fn =~ s/_/$char/;
    $site_url .= '/' unless $site_url =~ /\/$/;
    my $url = $site_url . $path
            . join('/', @dir) .$fn;
    return $url;
}

sub _filename_to_edit_url {
    my ($self, $fn) = @_;
    return $self->_filename_to_url($fn, $self->{edit_path});
}

sub _filename_to_action_url {
    my ($self, $fn) = @_;
    return $self->_filename_to_url($fn, $self->{action_path});
}

sub _url_to_filename {
    my $self = shift;
    return shift() . ".wiki";
}

sub _get_ref_filename {
    my ($self, $filename) = @_;
    confess "Not a .wiki file." unless $filename =~ /\.wiki$/;
    my ($vol, $dirs, $fn) = File::Spec->splitpath($filename);
    $fn =~ s/(.*)\.wiki/.$1.ref.wiki/;
    return File::Spec->catfile('.', $dirs, $fn);
}

sub _conflicts_found_in {
    my ($self, $text) = @_;
    return 1 if $text =~ /^>>>>>> /m;
    return 0;
}

sub _get_update_status {
    my ($self, $rv, $sv, $lv, $nv) = @_;
    chomp ($rv, $sv, $lv, $nv);
    my $status;
    $status = STATUS_LOCAL_MODIFIED if $lv ne $rv;
    $status = STATUS_SERVER_MODIFIED if $sv && $rv ne $sv;
    $status = STATUS_ADD unless $sv;
    $status = STATUS_CONFLICT if $self->_conflicts_found_in($nv);
    return $status;
}

sub _list_wiki_files {
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

1;

__END__

=end comment

=head1 AUTHORS

=item Mark Jaroski <mark@geekhive.net> 

Original author

=item Mike Wesemann <mike@fhi-berlin.mpg.de>

Added support for Mediawiki 1.3.10+ edit tokens

=head1 LICENSE

Copyright (c) 2004 Mark Jaroski. 

All rights reserved. This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

