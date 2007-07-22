sub merge_bluetext_to_existing_bluetext_subpages{
  my ($existing_prefix, $all_bluetext, $letter, @letters, $file, $text, $bighash, $line, @lines, $link, $total_blues);
  $existing_prefix = shift; $all_bluetext = shift; 

  @letters=(0, "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K",  "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W",  "X", "Y", "Z");

  # put all bluetext into one fat string
  foreach $letter (@letters){

    $file = $existing_prefix . $letter . ".wiki";
    $text = &fetch_file_nosave($file, 100, 1);

    $all_bluetext = $all_bluetext . $text . "\n";
  }

  # group the lines in the bluetext by letter
  @lines = split ("\n", $all_bluetext);
  foreach $line (@lines){

    next unless ($line =~ /\[\[(.*?)\]\]/);
    $link = $1;
    $link =~ s/^(.)/uc($1)/eg;

    next unless ($link =~ /^(.)/);
    $letter = $1; 
    $letter = "0" if ($letter !~ /[A-Z]/);
    $bighash->{$letter}->{$link} = $line;
  }

  # merge the lines into chunks of text and submit
  $total_blues=0;
  foreach $letter (sort {$a cmp $b} keys %$bighash){

    $text = "";
    foreach $link ( sort {$a cmp $b} keys %{$bighash->{$letter}} ){
      $text = $text . $bighash->{$letter}->{$link} . "\n";
      $total_blues++;
    }

    $file = $existing_prefix . $letter . ".wiki";
    print "--------------------$file\n";
    &submit_file_nosave($file, "Move bluelines from the math lists at [[Wikipedia:Missing_science_topics]]", $text, 10, 5);
  }
  return $total_blues;
}

1;
