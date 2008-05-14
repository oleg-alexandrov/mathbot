package VCS::Lite;

use strict;
use warnings;
our $VERSION = '0.07';

=head1 NAME

VCS::Lite - Minimal version control system

=head1 SYNOPSIS

  use VCS::Lite;

  # diff

  my $lit = VCS::Lite->new('/home/me/foo1.txt');
  my $lit2 = VCS::Lite->new('/home/me/foo2.txt');
  my $difftxt = $lit->delta($lit2)->diff;
  print OUTFILE $difftxt;

  # patch

  my $delt = VCS::Lite::Delta->new('/home/me/patch.diff');
  my $lit3 = $lit->patch($delt);
  print OUTFILE $lit3->text;

  # merge

  my $lit4 = $lit->merge($lit->delta($lit2),$lit->delta($lit3));
  print OUTFILE $lit4->text;

=head1 DESCRIPTION

This module provides the functions normally associated with a version
control system, but without needing or implementing a version control
system. Applications include wikis, document management systems and
configuration management.

It makes use of the module Algorithm::Diff. It provides the facility
for basic diffing, patching and merging.

=head2 new

The underlying object of VCS::Lite is an array. The members of the
array can be anything that a scalar can represent (including
references to structures and objects). The default is for the object
to hold an array of scalars as strings corresponding to lines of text.
If you want other underlying types, it is normal to subclass VCS::Lite
for reasons which will become apparent,

The basic form of the constructor is as follows:

  my $lite = VCS::Lite->new( '/my/file');

which slurps the file to make an object. The full form is as follows:

  my $lite = VCS::Lite->new( $object_id, $separator, $source, ...);

$object_id here is a string to identify what is being diffed, patched or
merged, in the application's environment. 

$separator here is a regexp by which to split strings into tokens. 
The default is to use the natural perl mechanism of $/ (which is emulated 
when not reading from a file).  The resulting VCS::Lite objects are 
unchomped by default.

$source if unspecified causes $object_id to be opened as a file and its
entire contents read in. The alternative is to supply $source, which can
be one of the following:

=over 4

=item *

scalar - This is a string which is tokenized using $separator

=item *
arrayref - Array of tokens

=item *
filehandle or globref - contents of file are slurped

=item *
callback - This is called successively to obtain tokens until received undef.

=back

In the Perl spirit of DWIM, new assumes that given an arrayref, you
have already done all the work of making your list of whatevers. Given
a string (filename) or a file handle, the file is slurped, reading
each line of text into a member of the array. Given a callback, the
routine is called successively with arguments $p1, $p2, etc. and is
expected to return a scalar which is added (pushed on) to the array.

=head2 apply

  $lite->apply($lite2);
  $lite->apply($lite3, base => 'original');

This method call corresponds approximately to a version control system's
check-in function. This causes $lite to be modified, so that its contents
now reflect those of $lite2.

$lite does retain the original contents, available via L<original>. However,
unlike in a version control system, the object holds only the first original 
and latest contents.

The VCS::Lite object passed in can also have its own original version. If 
this is the case, merging will be performed to incorporate the change as if
it had come from a different branch. To facilitiate the merging process,
optionally specify a base version, which can be the string 'original', 
'contents' (the default) or a VCS::Lite object whose contents will be used.
This corresponds to the "common ancestor" in version control systems.

=head2 text

  my $foo = $lite->text;
  my $bar = $lit2->text('|');
  my @baz = $lit3->text;

In scalar context, returns the equivalent of the file contents slurped
(the optional separator parameter, defaulting to $_, is used to join
the strings together). In list context, returns the list of lines or
records.

=head2 id

  my $fil = $lite->id

Returns the name associated with the VCS::Lite element when it was created
by new. This is usually the file name.

=head2 delta

  my $delt = $lit->delta($lit2);

Perform the difference between two VCS::Lite objects. This object returns
a L<VCS::Lite::Delta> object.

=head2 patch

  my $lit3 = $lit->patch($delt);

Applies a patch to a VCS::Lite object. Accepts a file handle or file
name string. Reads the file in diff format, and applies it. Returns a
VCS::Lite object for the patched source.

=head2 merge

  my $lit4 = $lit->merge($lit1,$lit2,\&confl);

Performs the "parallelogram of merging". This applies two different
change streams represented by VCS::Lite objects. Returns a VCS::Lite
object with both sets of changes merged.

The third parameter to the method is a sub which is called whenever a
merge conflict occurs. This needs to either resolve the conflict or
insert the necessary text to highlight the conflict.

=head1 COPYRIGHT

Copyright (c) Ivor Williams, 2002-2005

=head1 LICENCE

You may use, modify and distribute this module under the same terms 
as Perl itself.

=head1 SEE ALSO

L<Algorithm::Diff>.

=cut

use Carp;
use Algorithm::Diff qw(traverse_sequences);

sub new {
	my ($class,$id,$sep,$src,@args) = @_;

# DWIM logic, based on $src parameter.

# Case 0: $src missing. Use $id as file name, becomes case 3
	open $src,$id or croak("failed to open '$id': $!") unless $src;
	
	my $atyp = ref $src;
	local $/ = $sep if $sep;
	my $sep_re = $sep || qr(^)m;
	$sep ||= '';
	my @contents;

# Case 1: $src is string
	if (!$atyp) {
	    @contents = split $sep_re,$src;
	}
# Case 2: $src is arrayref
	elsif ($atyp eq 'ARRAY') {
	    @contents = @$src;
	}
# Case 3: $src is globref (file handle)
	elsif ($atyp eq 'GLOB') {
	    @contents = <$src>;
	}
# Case 4: $src is coderef - callback
	elsif ($atyp eq 'CODE') {
	    while (my $item=&$src(@args)) {
		push @contents,$item;
	    }
	}
# Case otherwise is an error.
	else {
	    croak "Invalid argument";
	}
	
	bless { id => $id,
		contents => \@contents,
		separator => $sep },$class;
}

sub original {
	my $self = shift;

	my $pkg = ref $self;

	exists($self->{original}) ?
		bless ({ id => $self->id,
			contents => $self->{original},
			separator => $self->{separator}}, $pkg ) :
		$self;
}

sub apply {
	my ($self,$other,%par) = @_;

	my $pkg = ref $self;
	my $base = $par{base};
	$base ||= 'contents';
	$base = $pkg->new( $self->id,
			$self->{separator},
			$self->{$base})
		unless ref $base;
	my $cbase = exists($other->{original}) ? $other->original : $base;
	my $mrg = $cbase->merge($base,$other);
	my $mrg2 = $base->merge($self,$mrg);
	$self->{original} ||= $self->{contents};
	$self->{contents} = [$mrg2->text];
}
	
sub text {
	my ($self,$sep) = @_;
	
	$sep ||= $self->{separator};

	wantarray ? @{$self->{contents}} : join $sep,@{$self->{contents}};
}

sub id {
	my $self = shift;

	@_ ? ($self->{id} = shift) : $self->{id};
}

use VCS::Lite::Delta;

sub delta {
	my $lite1 = shift;
	my $lite2 = shift;
	my %par = @_;
	
	my @wl1 = $lite1->_window($par{window});
	my @wl2 = $lite2->_window($par{window});
	my @d = map { [map { [$_->[0], $_->[1],
		ref($_->[2]) ? $_->[2]{line} : $_->[2]] } @$_ ] }
	Algorithm::Diff::diff(\@wl1,\@wl2,sub { $_[0]{window}; })
		or return undef;

	VCS::Lite::Delta->new(\@d,$lite1->id,$lite2->id);
}

sub _window {
	my $self = shift;

	my $win = shift || 0;
	my ($win_from,$win_to) = ref($win) ? (-$win->[0],$win->[1]) : 
						(-$win,$win);
	my @wintxt;
	my $max = $#{$self->{contents}};
	for (0..$max) {
	    my $win_lb = $_ + $win_from;
	    $win_lb = 0 if $win_lb < 0;
	    my $win_ub = $_ + $win_to;
	    $win_ub = $max if $win_ub > $max;
	    push @wintxt, join $self->{separator}, 
	    	@{$self->{contents}}[$win_lb .. $win_ub];
	}

	map { {line => $self->{contents}[$_], window => $wintxt[$_]} } 
		(0..$max);
}

sub diff {
	my $self = shift;

	$self->delta(@_)->diff;
}

sub patch {
	my $self = shift;
	my $patch = shift;
	$patch = VCS::Lite::Delta->new($patch,@_) 
		unless ref $patch eq 'VCS::Lite::Delta';
	my @out = @{$self->{contents}};
	my $id = $self->id;
	my $pkg = ref $self;
	my @pat = $patch->hunks;

	for (@pat) {
		for (@$_) {
			my ($ind,$lin,$txt) = @$_;
			next unless $ind eq '-';
			_error($lin,'Patch failed'),return undef
				if $out[$lin] ne $txt;
		}
	}

	my $line_offset = 0;

	for (@pat) {
		my @txt1 = grep {$_->[0] eq '-'} @$_;
		my @txt2 = grep {$_->[0] eq '+'} @$_;
		my $base_line = @txt2 ? $txt2[0][1] : $txt1[0][1] + $line_offset;
		splice @out,$base_line,scalar(@txt1),map {$_->[2]} @txt2;
		$line_offset += @txt2 - @txt1;
	}

	$pkg->new($id,'',\@out);
}

sub merge {
	my ($self,$d1,$d2) = @_;
	my $pkg = ref $self;

	# Equality of two array references (contents)
	
	sub equal
	{
		my ($a,$b) = @_;
	
		return 0 if @$a != @$b;
	
		foreach (0..$#$a)
		{
			return 0 if $a->[$_] ne $b->[$_];
		}
	
		1;
	}

	my $orig = [$self->text];
	my $chg1 = [$d1->text];
	my $chg2 = [$d2->text];
	my $out_title = $d1->{id} . '|' . $d2->{id};
	my %ins1;
	my $del1 = '';

	traverse_sequences( $self->{contents}, $chg1, {
		MATCH => sub { $del1 .= ' ' },
		DISCARD_A => sub { $del1 .= '-' },
		DISCARD_B => sub { push @{$ins1{$_[0]}},$chg1->[$_[1]] },
			} );

	my %ins2;
	my $del2 = '';

	traverse_sequences( $self->{contents}, $chg2, {
		MATCH => sub { $del2 .= ' ' },
		DISCARD_A => sub { $del2 .= '-' },
		DISCARD_B => sub { push @{$ins2{$_[0]}},$chg2->[$_[1]] },
			} );

# First pass conflict detection: deletion on file 1 and insertion on file 2

	$del1 =~ s(\-+){
		my $stlin = length $`;
		my $numdel = length $&;

		my @confl = map {exists $ins2{$_} ? ($_) : ()} 
			($stlin+1..$stlin+$numdel-1);
		@confl ? '*' x $numdel : $&;
	}eg;

# Now the other way round: deletion on file 2 and insertion on file 1

	$del2 =~ s(\-+){
		my $stlin = length $`;
		my $numdel = length $&;

		my @confl = map {exists $ins1{$_} ? ($_) : ()} 
			($stlin+1..$stlin+$numdel-1);
		@confl ? '*' x $numdel : $&;
	}eg;

# Conflict type 1 is insert of 2 into deleted 1, Conflict type 2 is insert of 1 into deleted 2
# @defer is used to hold the 'other half' alternative for the conflict

	my $conflict = 0;
	my $conflict_type = 0;
	my @defer;

	my @out;

	for (0..@{$self->{contents}}) {

# Get details pertaining to current @f0 input line 
		my $line = $self->{contents}[$_];
		my $d1 = substr $del1,$_,1;
		my $ins1 = $ins1{$_} if exists $ins1{$_};
		my $d2 = substr $del2,$_,1;
		my $ins2 = $ins2{$_} if exists $ins2{$_};

# Insert/insert conflict. This is not a conflict if both inserts are identical.

		if ($ins1 && $ins2 && !&equal($ins1,$ins2)) {
			push @out, ('*'x20)."Start of conflict ".(++$conflict).
			"  Insert to Primary, Insert to Secondary ".('*'x60)."\n";

			push @out, @$ins1, ('*'x100)."\n", @$ins2;
			push @out, ('*'x20)."End of conflict ".$conflict.('*'x80)."\n";
		} elsif (!$conflict_type) {	#Insert/Delete conflict

# Normal insertion - may be from $ins1 or $ins2. Apply the inser and junk both $ins1 and $ins2

			$ins1 ||= $ins2;

			push @out, @$ins1 if defined $ins1;

			undef $ins1;
			undef $ins2;
		}

# Detect start of conflict 1 and 2

		if (!$conflict_type && $d1 eq '*') {
			push @out, ('*'x20)."Start of conflict ".(++$conflict).
			"  Delete from Primary, Insert to Secondary ".('*'x60)."\n";

			$conflict_type = 1;
		}

		if (!$conflict_type && $d2 eq '*') {
			push @out, ('*'x20)."Start of conflict ".(++$conflict).
			"  Delete from Secondary, Insert to Primary ".('*'x60)."\n";

			$conflict_type = 2;
		}

# Handle case where we are in an Insert/Delete conflict block already

		if ($conflict_type == 1) {
			if ($d1 eq '*') {

# Deletion block continues...
				push @defer,(@$ins2) if $ins2;
				push @defer,$line if !$d2;
			} else {

# handle end of block, dump out @defer and clear it

				push @out, ('*'x100)."\n",@defer;
				undef @defer;
				push @out, ('*'x20)."End of conflict ".$conflict.('*'x80)."\n";
				$conflict_type = 0;
			}
		}

		if ($conflict_type == 2) {
			if ($d2 eq '*') {

# Deletion block continues...
				push @defer,(@$ins1) if $ins1;
				push @defer,$line if !$d1;
			} else {

# handle end of block, dump out @defer and clear it

				push @out, ('*'x100),"\n", @defer;
				undef @defer;
				push @out, ('*'x20)."End of conflict ".$conflict.('*'x80)."\n";
				$conflict_type = 0;
			}
		}
		last unless defined $line;	# for end of file, don't want to push undef
		push @out, $line unless ($d1 eq '-' || $d2 eq '-') && !$conflict_type;
	}
	$pkg->new($out_title, undef, \@out);
}

sub _error {};

1;
