sub sectioning {

  my ($text, $line, @lines, $seccount, $head);
  
  $text = shift;
  @lines = split ("\n", $text);

  $seccount=1000;
  $text = "";
  foreach $line (@lines){
    $seccount++;
    
    next unless ($line =~ /\[\[(.*?)\]\]/);
    $head=$1;

    # if the current section is too long, add section headings
    if ($seccount >= 15) { 
      if ($head =~ /^(...)/){
	$head = $1;
      }
      $head = &strip_accents($head);
      
      $text = $text . "==$head==\n";
      $seccount=0;
    }
    
    $text = $text . $line . "\n";
  }

  return $text;
}

1;
