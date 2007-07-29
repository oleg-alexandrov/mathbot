use LWP::Simple;
use LWP::UserAgent;

# get html source code in a robust manner
sub get_html {

  my ($link, $text, $error, $counter);

  $link = shift;
  
  for ($counter=0 ; $counter <= 100  ; $counter++){

    my ($ua, $req, $res);
    
    $ua = LWP::UserAgent->new;
    $ua->agent("Mozilla/8.0"); # pretend we are very capable browser
    $ua->agent("$0/0.1 " . $ua->agent);
    
    $req = HTTP::Request->new(GET => $link);
    $req->header('Accept' => 'text/html');
        
    # send request
 #   print "<!-- Getting $link ... -->";
    $res = $ua->request($req); 

    # check the outcome. If outcome is success, save the text and exit the loop
    $error=0;
    if ($res->is_success ){

      $text = $res->decoded_content;
      #print "<!-- Sucess! -->\n";
      last;
      
    }else{
      
      print "Get $link failed in attempt $counter!\n";
      $error=1;
      
    }

    if ($counter > 0){
      print "Sleeping for 10 seconds\n";
      sleep 10;
    }
    
  }

  if ($error == 1){
    print "Failed to get $link! Exiting...\n";
    exit(0);
  }
  
  return ($text, $error);
}

1;
