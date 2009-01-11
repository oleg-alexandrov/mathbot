use open 'utf8';

require 'bin/perlwikipedia_utils.pl'; # my own packages, this and the one below
require 'bin/html_encode_decode_string.pl';
undef $/; # undefines the separator. Can read one whole file in one scalar.

sub read_from_disk_or_wikipedia {

  my ($Editor, $article_name, $file, $attempts, $sleep, $article_text);

  $Editor = shift;
  $article_name=shift;
  $file = &article_to_filename ($article_name);
  
  if ( -e $file) {
    open (FILE_RWD, "<", $file); $article_text = <FILE_RWD>; close(FILE_RWD);
  }else{
    
    print "Fetching $article_name as $file does not exist on disk.\n";
    
    $sleep = 1; $attempts=10;
    $article_text = wikipedia_fetch($Editor, $article_name . '.wiki',  $attempts, $sleep);

    # Since we got the data anyway, save it to disk
    &write_to_disk($article_name, $article_text);
  }

  return $article_text;
}

sub write_to_disk {

  my ($article_name, $article_text, $dir, $file);

  $article_name=shift; $article_text=shift;

  $file = &article_to_filename ($article_name);

  &create_dir_path_if_necessary($file);
  
  print "Writing $article_name to $file.\n";
  open(FILE_RWD, ">$file");  print FILE_RWD "$article_text\n";  close(FILE_RWD);
}

sub article_to_filename {

  my ($file, $letter_dir, $destination_dir);

  # Will store all articles to write to disk in this directory.
  $destination_dir = '/tmp/articles';

  $file = shift; $file = &html_encode_string ($file) . '.wiki';

  # encode the slash character, so that a subdirectory need not be created 
  $file =~ s/\//\%2F/g; 

  # Store the article in a subdirectory whose name is the starting letter.
  $letter_dir = "0";
  if ($file =~ /^([0-9A-Z])/i){
    $letter_dir = uc ($1);
  }
  
  return $destination_dir . '/' . $letter_dir . '/' . $file;
}

sub create_dir_path_if_necessary {

  # If a file to be written to is in a directory, first make sure
  # that directory exists.
  
  my ($file, $dir_path, $dir, @dirs);

  $file = shift;

  if ($file =~ /^(.*)\//){
    $dir_path = $1;
  }else{
    return; 
  }


  @dirs = split('/', $dir_path);
  $dir_path = '';

  # the special case of a directory starting with /
  $dir_path = "/" if ($dirs[0] =~ /^\s*$/); 

  foreach $dir (@dirs){

    next if ($dir =~ /^\s*$/);
    $dir_path = $dir_path . $dir . '/';

    if (-d $dir_path){
      #print "Directory $dir_path exists.\n";
    }else{

      print "Creating directory $dir_path\n";
      mkdir $dir_path;
      
      if (! -d $dir_path){
        print "Error! Could not create directory $dir_path!!!\n";
        exit(0);
      }
      
    }
    
  }
}

1;
