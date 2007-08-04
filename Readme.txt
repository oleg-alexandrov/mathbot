The directory 'modules' contains some general purpose routines used by
mathbot in its work. The routines depend on Perlwikipedia.pm, which is
not included.

The file perlwikipedia_utils_prototype.pl in 'modules/bin' needs to be
renamed to perlwikipedia_utils.pl and a Wikipedia login and password
needs to be specified in there.

The directory 'mathlists' contains the code mathbot uses to update the
lists of mathematicians and mathematics articles. Those codes depend
on the 'modules' directory. See the file 'Readme.txt' in 'mathlists'
for more information.

The directory 'missingscience' contains the scripts that are used to
update the mathematics section in the list of missing science topics
on Wikipedia. These codes need the package WWW::Mediawiki::Client.pm
version 0.23 and its dependencies. I hope to convert those codes to 
using Perlwikipedia.pm instead at some point.

The routine wikipedia_login_prototype.pl in modules/bin needs the same
treatment as perlwikipedia_utils_prototype.pl in order for the codes
in 'missingscience' to work.
