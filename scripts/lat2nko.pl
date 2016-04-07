#!/usr/bin/perl

use utf8 ;
use Encode ; # qw(encode decode is_utf8) ;

binmode( STDIN,  ':utf8' );
binmode( STDOUT, ':utf8' );


@ny = () ;   @nny = () ;   @newny = () ;

open( IN_ny, "<:utf8", "___ny.ny" );
$size_ny = -1;
$l = <IN_ny> ;
while($l = <IN_ny>){ chop($l) ;   push(@ny,$l) ;   $size_ny++ ; }
close( IN_ny ) ;

open( IN_ny, "<:utf8", "___nny.ny" );
$size_nny = -1;
$l = <IN_ny> ;
while($l = <IN_ny>){ chop($l) ;   push(@nny,$l) ;   $size_nny++ ; }
close( IN_ny ) ;


while ($l = <STDIN>)
{
  chomp($l) ;  
  $_ = lc($l) ;
  
###  if(/^</){ print "$_\n" ; next; }
  if(/<s>/){ next ; }
###  s/<t>//g ;   s/<\/t>//g ;

###### NY closed list follows: ######
   s/\bbɛnnyɔɔnya\b/ߓߍ߲ߢߐ߲߱ߧߊ/g ;
   s/\bdɛnnyɔgɔnnya\b/ߘߍ߲߬ߢߐ߬ߜߐ߲߬ߧߊ/g ;
   s/\bsiginyɔgɔnnya\b/ߛߜߌ߬ߢߐ߬ߜߐ߲߬ߧߊ/g ;
   s/\byilanyilan\b/ߦߌߟߊ߲ߦߌߟߊ߲/g ;
   
   s/\bdɛnyɔonnu\b/ߘߍ߲߬ߢߐ߲߰ߣߎ/g ;   # опечатка, должно быть dɛ̀nɲɔɔnnu
   s/\bdɛnyɔɔ\b/ߘߍ߬ߢߐ߲߰/g ;   # неправильное написание, надо dɛ̀ɲɔɔn 
   s/\bnadanya\b/ߣߊߘߊ߲ߢߊ/g ;   # nadanya  = nadannya
   s/(ɲinynkali|ɲunynkali)/ɲininkali/g ;  # some typo
#####################################
   s/\bny/ߢ/g ;
   
###### test for NY with lists #######
  if(/ny/)
  {   
    @line = split(/\b/, $_ ) ;
    $_ = "" ;
    foreach $word(@line)
    {
      if($word =~ /ny/)
	  {
	    $i = 0 ;
	    while( ($word ne $ny[$i])&&($i<=$size_ny) ){ $i++ ; }
	    if($i<=$size_ny){ $word =~ s/ny/ߢ/g ; }
	    else
	    {
          $i = 0 ;
	      while( ($word ne $nny[$i])&&($i<=$size_nny) ){ $i++ ; }
	      if($i<=$size_nny){ $word =~ s/n*ny/\x{07F2}\x{07E7}/g ; }
	      else { push(@newny, $word) ; }
	    }
	  }
	  $_ .= " ".$word ;
    }
	$_ .= "\n" ;
	s/\s+$//g ;
	s/^\s+//g ;
  }	 
#####################################  
  
###### nny -> nɲ -> n+NYA-woloso
  s/\bnny/ߒߧ/g ;
  s/nny/\x{07F2}\x{07E7}/g ;
######  ny ->  ɲ
  s/ny/ߢ/g ;
#####################################

  s/ng/ߢ߭/g ;   s/ŋ/ߢ߭/g ;
  
  s/\bn'/ߣߴ/g ;
  s/\bn([^aeiouɛɔn])/\x{07D2}\1/g ;
  s/\bn/ߣ/g ;
  s/([aeiouɛɔ])n\b/\1\x{07F2}/g ;
  s/([aeiouɛɔ])n([^aeiouɛɔ])/\1\x{07F2}\2/g ;
  s/\bn\b/ߒ/g ;
  s/n/ߣ/g ;
  
  s/gb/ߜ/g ;
  s/sh/ߛ߭/g ;   s/ʃ/ߛ߭/g ;
  s/th/ߛ߳/g ;   s/θ/ߛ߳/g ;
  s/kp/ߜ߳/g ;
  s/rr/ߚ/g ;
  s/g/ߜ߭/g ;
  s/v/ߝ߭/g ;
  s/z/ߖ߭/g ;
  s/ħ/ߤ߭/g ;
  s/kh/ߞ߭/g ;    s/x/ߞ߭/g ;
  s/q/ߞ߫/g ;
  s/gh/ߜ߫/g ;   s/ɣ/ߜ߫/g ;
  s/zh/ߗ߭/g ;   s/dj/ߗ߭/g ;   s/ʒ/ߗ߭/g ;   s/ð/ߗ߭/g ;
  s/ʕa/ߊ߳/g ;   s/ʕ/ߊ߳/g ;
  s/bh/ߓ߭/g ;   s/ɓ/ߓ߭/g ;
  s/dh/ߘ߳/g ;   s/ɗ/ߘ߳/g ;
  
  s/b/ߓ/g ;
  s/c/ߗ/g ;
  s/d/ߘ/g ;
  s/f/ߝ/g ;
  s/h/ߤ/g ;
  s/j/ߖ/g ;
  s/k/ߞ/g ;
  s/l/ߟ/g ;
  s/m/ߡ/g ;
  s/ɲ/ߢ/g ;
  s/p/ߔ/g ;
  s/s/ߛ/g ;
  s/t/ߕ/g ;
  s/r/ߙ/g ;
  s/w/ߥ/g ;
  
  s/y/ߦ/g ;
  
  s/aa/ߊ߯/g;
  s/ɛɛ/ߍ߯/g;
  s/ee/ߋ߯/g;
  s/ii/ߌ߯/g;
  s/ɔɔ/ߐ߰/g;
  s/oo/ߏ߯/g;
  s/uu/ߎ߯/g;
  
  s/a/ߊ/g ;   s/á/ߊ/g ;
  s/ɛ/ߍ/g ;
  s/e/ߋ/g ;
  s/i/ߌ/g ;
  s/ɔ/ߐ/g ;
  s/o/ߏ/g ;
  s/u/ߎ/g ;
  
#  s/^(.)/ \1/g ;   s/(.)$/\1 /g ; 
#  s/([^\d])(\d)(\d)(\d)(\d)(\d)(\d)(\d)([^\d])/\1\8\7\6\5\4\3\2\9/g ;
#  s/([^\d])(\d)(\d)(\d)(\d)(\d)(\d)([^\d])/\1\7\6\5\4\3\2\8/g ;
#  s/([^\d])(\d)(\d)(\d)(\d)(\d)([^\d])/\1\6\5\4\3\2\7/g ;
#  s/([^\d])(\d)(\d)(\d)(\d)([^\d])/\1\5\4\3\2\6/g ;
#  s/([^\d])(\d)(\d)(\d)([^\d])/\1\4\3\2\5/g ;
#  s/(\D)(\d)(\d)(\D)/\1\2\3\4/g ;
#  
#  s/^ //g ;   s/ $//g ;
  
  s/0/߀/g;   s/1/߁/g;   s/2/߂/g;   s/3/߃/g;   s/4/߄/g;
  s/5/߅/g;   s/6/߆/g;   s/7/߇/g;   s/8/߈/g;   s/9/߉/g;
  
  s/,/،/g ;   s/\?/؟/g ;   s/!/߹/g ;   s/;/؛/g ;
  s/'/ߴ/g ;
  
  s/([߹؟،߸!\.:\(\)\-\x{2329}\x{232A}«»])\s*$/\1\x{200F}/g ;  # RTL mark after punctuation
  s/([߹؟،߸!\.:\(\)\-\x{2329}\x{232A}«»])\s*</\1\x{200F}</g ;  # RTL mark after punctuation

  s/<ߤ>/<h>/g ;   s/<\/ߤ>/<\/h>/g ;
  s/<ߛ>/<s>/g ;   s/<\/ߛ>/<\/s>/g ;
  s/<ߕ>/<t>/g ;   s/<\/ߕ>/<\/t>/g ;
  s/<ߕߓ>/<tb>/g ;   s/<\/ߕߓ>/<\/tb>/g ;
  s/<ߓߙ>/<br>/g ;   s/<ߓߙ\/>/<br\/>/g ;

  print "$_\n" ;
  
#  @line = split (/\s/, $_) ;
#  foreach $word(@line)
#  {
#    $_ = $word ;
#	if( /(ny|NY)/ ){  print NY "$_\n" ; }
#  }  
}  

open (NY, ">>:utf8", "new.ny" ) ;
%seen=();
@unique = grep { ! $seen{$_} ++ } @newny;
foreach $word (@unique){  print NY "$word\n" ;  }
close( NY );


close (NY) ;

exit(0) ;
