The script for updating the list of mathematicians is
"update_mathematicians.pl".

The script for updating the list of mathematics articles is
"update_mathematics.pl".

The second script weakly depends on the data generated by the first
script, but with a few complaints will run independently from it.

The file 'Countries.txt' maps nationalities to countries, it is needed
by the mathematicians script.

Overall, the "update_mathematics.pl" script is simpler and easier to
understand than the one updating the mathematicians. 

Both scripts use subroutines from the 'modules' directory, the correct
path to that directory needs to be specified on the "use lib" line in
both scripts.

The other codes in this directory are either dependencies of the above
two codes or independent housekeeping scripts.

