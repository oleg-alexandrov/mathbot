# How to install updated versions of modules
#cpan App::cpanminus
# /data/project/mathbot/public_html/wp/modules/bin/cpanm Crypt::SSLeay --force

# Run the tool
cd /data/project/mathbot/cgi-bin/wp/afd
./afd.cgi

# Sometimes the perl version running when executing a CGI script is not the same
# as the one from the command line. It is virtually impossible to debug this. 
# To debug, run a test cgi script from which run a shell script which
# will run the actual cgi script while redirecting all output and error 
# to a file. One may need to change some permissions and set some env
# variables for this to work.
