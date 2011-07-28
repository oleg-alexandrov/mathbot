#!/opt/ts/bin/bash

# Set the path to the 'modules' directory. This can be alternatively
# specified in each of the perl codes below.

#export PERL5LIB=$HOME/public_html/wp/modules

# go to the working directory
cd $HOME/public_html/wp/mathlists

./recent.pl

# ------------------------ mathematicians -------------------------

./update_mathematicians.pl

sleep 10;

# ----------------------- mathematics -----------------------------
./update_mathematics.pl




