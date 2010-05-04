The directory 'modules' contains some general purpose routines used by
mathbot in its work. 

The directory 'mathlists' contains the code mathbot uses to update the
lists of mathematicians and mathematics articles. Those codes depend
on the 'modules' directory. See the file 'Readme.txt' in 'mathlists'
for more information.

The directory 'missingscience' contains the scripts that are used to
update the mathematics section in the list of missing science topics
on Wikipedia. These codes need the package WWW::Mediawiki::Client.pm
version 0.23 and its dependencies. I hope to convert those codes to 
using Perlwikipedia.pm instead at some point.

The routine wikipedia_login_prototype.pl in modules/bin needs to be
renamed to perlwikipedia_utils.pl and a user name and password needs 
to be specified in order for the codes in 'missingscience' to work.
