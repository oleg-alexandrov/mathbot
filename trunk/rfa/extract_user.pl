# given an admin's candidate page, get the user name of the candidate

sub extract_user {

  my ($nomin_text, $user);

  $nomin_text = shift;

 if ($nomin_text =~ /\{\{\s*(User|Admin)\s*\|\s*(.*?)\s*\}\}/i){
    $user=$2;
    print "User is $user<br><br>\n\n";
    
 }elsif ($nomin_text =~ /===*\s*\[\[\s*User\s*:\s*(.*?)\s*(\||\]\])/) {
    $user=$1;
    print "User is $user<br><br>\n\n";
    
  } else {
    $user="";
    print "Unknown user, there is a problem somewhere!!!!!!!!!!<br><br>\n\n";
  }

  return $user;
}

1;
