#!/usr/bin/perl -w

use strict;                   # 'strict' insists that all variables be declared
use diagnostics;              # 'diagnostics' expands the cryptic warnings
use Encode;

use lib $ENV{HOME} . '/public_html/wp/modules'; # path to perl modules
require 'bin/wikipedia_fetch_submit.pl'; # my own packages, this and the one below
require 'bin/wikipedia_login.pl';
require 'bin/html_encode_decode.pl';
require 'bin/get_html.pl';
undef $/;		      # undefines the separator. Can read one whole file in one scalar.


MAIN: {

  my ($gallery_name, $exclude_from, $sleep, $attempts, $text, $gal_st, $gal_et, $top, $bottom);
  my (@lines, $image, %images, %excluded_images, $caption, %captions, $image_no, $new_text, $count);
  my ($edit_summary);
  
  &wikipedia_login('Mathbot');  $sleep = 2; $attempts=10;

  $gallery_name='User:Oleg Alexandrov/Pictures'; $gallery_name .= '.wiki';
  $gal_st ='<gallery>'; $gal_et ='</gallery>';

  # fetch the current gallery. Extract the text between the gallery tags and the images.
  $text = &wikipedia_fetch($gallery_name, $attempts, $sleep);
  if ($text =~ /^(.*?\Q$gal_st\E\s*?\n)(.*?)(\Q$gal_et\E.*?)$/si) {
    $top = $1; $text = $2; $bottom = $3;
  } else {
    $top = $gal_st . "\n"; $bottom=$gal_et . "\n"; 
  }
  $image_no = &put_images_into_hash($text, \%images, \%captions);

  # Fetch the images which we won't want in the gallery (for whatever reasons)
  $exclude_from='User:Oleg Alexandrov/Pictures/Exclude'; $exclude_from .= '.wiki';
  $text = &wikipedia_fetch($exclude_from, $attempts, $sleep);
  &put_images_into_hash($text, \%excluded_images, \%captions);
  
  # Extract the new images from commons, they will be added to the gallery.
  # Reverse their order, so that the newest are at the bottom
  $image_no = $image_no + 1000000; 
  open(FILE, "<Gallery.php.html");  $text=<FILE>; close(FILE);
  @lines = ($text =~ /\<td valign=\'top\' title=\'Thumb\'.*?img src=.*?\?f=(.*?)\&amp;/ig);
  foreach $image (@lines){
    $image = &html_decode($image);

    next if (exists $images{$image});
    $images{$image} = $image_no; $image_no--;
    $captions{$image} = "";
  }

  # Combine the curent gallery with the recently uploaded images, and remove
  # the ones to be excluded.
  $text="";
  $count = 0;
  foreach $image (sort { $images{$a} <=> $images{$b} } keys %images){

    next if (exists $excluded_images{$image});
    
    $text = $text . 'Image:' . $image . ' | ' . $captions{$image} . "\n";

    # space the images when printing
    $count++;
    if ($count > 4){
      $text = $text . "\n";
      $count = 0;
    }

  }
  $text = $top . $text . $bottom;
  print "$text\n";

  # submit the updated gallery
  $edit_summary = "Update the gallery";

  &wikipedia_submit($gallery_name, $edit_summary, $text, $attempts, $sleep);
}

sub put_images_into_hash{

  my ($text, $images, $captions, $image, $caption, $image_no, @lines);

  ($text, $images, $captions) = @_;
  
  # extract the current images in the gallery
  @lines = ($text =~ /Image:(.*?)(?:\]\]|\n|$)/ig);
  $image_no = 1;

  foreach $image (@lines) {
    $image =~ s/^(.)/uc($1)/eg; # upcase

    # Strip any mention of "thumb" and "frame". The <gallery> tags take care of that
    $image =~ s/\s*\|\s*(center|frame|thumb|right).*?$//g;
    
    # extract the caption
    if ($image =~ /^(.*?)\s*\|\s*?(.*?)$/){
      $image = $1; $caption = $2;
    }else{
      $caption = ""; 
    }
    
    $images->{$image} = $image_no; $image_no++;
    $captions->{$image} = $caption;
  }

  return $image_no;
}
