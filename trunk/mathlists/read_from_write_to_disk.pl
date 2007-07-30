require 'bin/perlwikipedia_utils.pl'; # my own packages, this and the one below
require 'bin/html_encode_decode_string.pl';
undef $/; # undefines the separator. Can read one whole file in one scalar.

sub read_from_disk_or_wikipedia {

  my $Editor=wikipedia_login();
  
  my ($article_name, $file, $attempts, $sleep, $text);
  
  $article_name=shift;
  $file = &article_to_filename ($article_name);
  
  if ( -e $file) {
    open (FILE_RWD, "<", $file); $text = <FILE_RWD>; close(FILE_RWD);
  }else{
    
    print "Fetching $article_name as $file does not exist on disk.\n";
    $sleep = 1; $attempts=10;
    $text = wikipedia_fetch($Editor, $article_name . '.wiki',  $attempts, $sleep);

    print "Writing $article_name to $file\n";
    open (FILE_RWD, ">", "$file"); print FILE_RWD "$text\n"; close(FILE_RWD);
  }

  return $text;
}

sub write_to_disk {

  my ($article_name, $article_text, $dir, $file);

  $article_name=shift; $article_text=shift;

  $file = &article_to_filename ($article_name);
  
  print "Writing $article_name to $file\n";
  open(FILE_RWD, ">$file");  print FILE_RWD "$article_text\n";  close(FILE_RWD);
}

sub article_to_filename {

  my ($file, $dir, $dir_path);

#  $dir_path = '/m1/aoleg/wp/articles';
  $dir_path = '/tmp/articles';

  $file = shift; $file = &html_encode_string ($file) . '.wiki';

  # encode the slash character, so that a subdirectory need not be created 
  $file =~ s/\//\%2F/g; 

  $dir = "0";
  if ($file =~ /^([0-9A-Z])/i){
    $dir = uc ($1);
  }
  
  return $dir_path . '/' . $dir . '/' . $file;
}

1;
