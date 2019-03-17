#!/bin/bash

# Set the path to the 'modules' directory. This can be alternatively
# specified in each of the perl codes below.

export PERL5LIB=$HOME/public_html/wp/modules:$HOME/public_html/wp/mathlists:$PERL5LIB

# go to the working directory
cd $(dirname $0) 

uname -a

./recent.pl

# ------------------------ mathematicians -------------------------

./update_mathematicians.pl

sleep 10

# ----------------------- mathematics -----------------------------
./update_mathematics.pl




