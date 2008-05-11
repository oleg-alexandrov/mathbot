sub percent_support_calc {

  my ($support, $oppose)=@_;
  
  if ($support =~ /^\d+$/ && $oppose =~ /^\d+$/){
    return  100*$support/( ($support + $oppose) || 1 );
  }else{
    return "?"; 
  }
}

sub calc_votes{

  my ($text, $count, $vote, @votes);
  
  $text = shift;

  $count=0;
  @votes = split ("\n", $text);
  
  foreach $vote (@votes){

    # ignore all lines but valid votes
    next unless ($vote =~ /^\#/ && $vote =~ /^\#.*?\w/  && $vote !~ /^\#[\#\:\*]/); 
    $count++;
  }
  
  return $count;
  
}


1;
