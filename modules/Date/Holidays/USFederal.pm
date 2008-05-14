package Date::Holidays::USFederal;
use strict;
use warnings;
use base qw(Exporter);
our $VERSION = '0.01';
our @EXPORT = qw( is_usfed_holiday );

=head1 NAME

Date::Holidays::USFederal - Determine US Federal Public Holidays

=head1 SYNOPSIS

  use Date::Holidays::USFederal;
  my ($year, $month, $day) = (localtime)[ 5, 4, 3 ];
  $year  += 1900;
  $month += 1;
  print "Woohoo" if is_usfed_holiday( $year, $month, $day );

=head1 DESCRIPTION

The naming convention for the module follows that of L(Date::Holidays:UK)
as where the format for this module was also taken.

=head1 SUBROUTINES

=head2 is_usfed_holiday( $year, $month, $day )

Returns the name of the Holiday that falls on the given day, or undef
if there is none.

=cut

# 
# 
our %holidays;

$holidays{ 1997,  1,  1 } =
$holidays{ 1998,  1,  1 } =
$holidays{ 1999,  1,  1 } =
$holidays{ 1999, 12, 31 } =
$holidays{ 2001,  1,  1 } =
$holidays{ 2002,  1,  1 } =
$holidays{ 2003,  1,  1 } =
$holidays{ 2004,  1,  1 } =
$holidays{ 2004, 12, 31 } =
$holidays{ 2006,  1,  2 } =
$holidays{ 2007,  1,  1 } =
$holidays{ 2008,  1,  1 } = 
$holidays{ 2009,  1,  1 } = 
$holidays{ 2010,  1,  1 } = "New Year's Day";

$holidays{ 1997,  1, 20 } =
$holidays{ 1998,  1, 19 } =
$holidays{ 1999,  1, 18 } =
$holidays{ 2000,  1, 17 } =
$holidays{ 2001,  1, 15 } =
$holidays{ 2002,  1, 17 } =
$holidays{ 2003,  1, 20 } =
$holidays{ 2004,  1, 19 } =
$holidays{ 2005,  1, 17 } =
$holidays{ 2006,  1, 16 } =
$holidays{ 2007,  1, 15 } =
$holidays{ 2008,  1, 21 } = 
$holidays{ 2009,  1, 19 } = 
$holidays{ 2010,  1, 18 } = "Martin Luther King, Jr. Birthday";

$holidays{ 1997,  2, 17 } =
$holidays{ 1998,  2, 16 } =
$holidays{ 1999,  2, 15 } =
$holidays{ 2000,  2, 21 } =
$holidays{ 2001,  2, 19 } =
$holidays{ 2002,  2, 18 } =
$holidays{ 2003,  2, 17 } =
$holidays{ 2004,  2, 16 } =
$holidays{ 2005,  2, 21 } =
$holidays{ 2006,  2, 20 } =
$holidays{ 2007,  2, 19 } =
$holidays{ 2008,  2, 18 } = 
$holidays{ 2009,  2, 16 } = 
$holidays{ 2010,  2, 15 } ="Washington's Birthday / Presidents Day";

$holidays{ 1997,  5, 26 } =
$holidays{ 1998,  5, 25 } =
$holidays{ 1999,  5, 31 } =
$holidays{ 2000,  5, 29 } =
$holidays{ 2001,  5, 28 } =
$holidays{ 2002,  5, 27 } =
$holidays{ 2003,  5, 26 } =
$holidays{ 2004,  5, 31 } =
$holidays{ 2005,  5, 28 } =
$holidays{ 2006,  5, 29 } =
$holidays{ 2007,  5, 28 } =
$holidays{ 2008,  5, 26 } = 
$holidays{ 2009,  5, 25 } = 
$holidays{ 2010,  5, 31 } = "Memorial Day";

$holidays{ 1997,  7,  4 } =
$holidays{ 1998,  7,  5 } =
$holidays{ 1999,  7,  4 } =
$holidays{ 2000,  7,  4 } =
$holidays{ 2001,  7,  4 } =
$holidays{ 2002,  7,  4 } =
$holidays{ 2003,  7,  4 } =
$holidays{ 2004,  7,  5 } =
$holidays{ 2005,  7,  4 } =
$holidays{ 2006,  7,  4 } =
$holidays{ 2007,  7,  4 } =
$holidays{ 2008,  7,  4 } = 
$holidays{ 2009,  7,  3 } = 
$holidays{ 2010,  7,  5 } = "Independence Day";

$holidays{ 1997,  9,  1 } =
$holidays{ 1998,  9,  1 } =
$holidays{ 1999,  9,  6 } =
$holidays{ 2000,  9,  4 } =
$holidays{ 2001,  9,  3 } =
$holidays{ 2002,  9,  2 } =
$holidays{ 2003,  9,  1 } =
$holidays{ 2004,  9,  6 } =
$holidays{ 2005,  9,  5 } =
$holidays{ 2006,  9,  4 } =
$holidays{ 2007,  9,  3 } =
$holidays{ 2008,  9,  1 } = 
$holidays{ 2009,  9,  7 } = 
$holidays{ 2010,  9,  6 } = "Labor Day";

$holidays{ 1997, 10, 13 } =
$holidays{ 1998, 10, 13 } =
$holidays{ 1999, 10, 11 } =
$holidays{ 2000, 10,  9 } =
$holidays{ 2001, 10,  8 } =
$holidays{ 2002, 10, 14 } =
$holidays{ 2003, 10, 13 } =
$holidays{ 2004, 10, 11 } =
$holidays{ 2005, 10, 10 } =
$holidays{ 2006, 10,  9 } =
$holidays{ 2007, 10,  8 } =
$holidays{ 2008, 10, 13 } = 
$holidays{ 2009, 10, 12 } = 
$holidays{ 2010, 10, 11 } = "Columbus Day";

$holidays{ 1997, 11, 11 } =
$holidays{ 1998, 11, 11 } =
$holidays{ 1999, 11, 11 } =
$holidays{ 2000, 11, 10 } =
$holidays{ 2001, 11, 12 } =
$holidays{ 2002, 11, 11 } =
$holidays{ 2003, 11, 11 } =
$holidays{ 2004, 11, 11 } =
$holidays{ 2005, 11, 11 } =
$holidays{ 2006, 11, 10 } =
$holidays{ 2007, 11, 12 } =
$holidays{ 2008, 11, 11 } = 
$holidays{ 2009, 11, 11 } =
$holidays{ 2010, 11, 11 } = "Veterans Day";

$holidays{ 1997, 11, 27 } =
$holidays{ 1998, 11, 27 } =
$holidays{ 1999, 11, 25 } =
$holidays{ 2000, 11, 23 } =
$holidays{ 2001, 11, 22 } =
$holidays{ 2002, 11, 28 } =
$holidays{ 2003, 11, 27 } =
$holidays{ 2004, 11, 25 } =
$holidays{ 2005, 11, 24 } =
$holidays{ 2006, 11, 23 } =
$holidays{ 2006, 11, 24 } =
$holidays{ 2007, 11, 22 } =
$holidays{ 2007, 11, 23 } =
$holidays{ 2008, 11, 27 } = 
$holidays{ 2009, 11, 26 } = 
$holidays{ 2010, 11, 25 } = "Thanksgiving Day";

$holidays{ 1997, 12, 25 } =
$holidays{ 1998, 12, 25 } =
$holidays{ 1999, 12, 24 } =
$holidays{ 2000, 12, 25 } =
$holidays{ 2001, 12, 25 } =
$holidays{ 2002, 12, 25 } =
$holidays{ 2003, 12, 25 } =
$holidays{ 2004, 12, 24 } =
$holidays{ 2005, 12, 26 } =
$holidays{ 2006, 12, 25 } =
$holidays{ 2007, 12, 25 } = 
$holidays{ 2008, 12, 25 } = 
$holidays{ 2009, 12, 25 } = 
$holidays{ 2010, 12, 24 } = "Christmas Day";


sub is_usfed_holiday {
    my ($year, $month, $day) = @_;
    return $holidays{ $year, $month, $day };
}

1;
__END__
=head1 Holiday Data

The holidays are listed on the US Government Office of Personnel Management
web site - http://www.opm.gov/Fedhol/

=head1 CAVEATS

The module current only contains US Federal holiday information for years 1997-2010.

=head1 AUTHOR

Doug Morris <dougmorris at mail d0t nih D0T gov >

=head1 COPYRIGHT

US government.  All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 BUGS

None known.

Bugs should be reported to me via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date::Holidays::USFederal>.

=head1 SEE ALSO

L<Date::Holidays::UK>, L<Date::Japanese::Holiday>

=cut
