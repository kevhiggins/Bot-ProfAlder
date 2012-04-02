#!/usr/bin/perl 
BEGIN { unshift @INC, "./../lib"; }

package parse_search;

#use Yahoo::Search;
use LWP::Simple qw/get $ua/;;
use HTML::Strip;
use Lingua::EN::Tagger;
use Lingua::EN::Conjugate;
use Lingua::EN::VerbTense;
use Google;
use strict;

sub get_pertinent;
sub load_info;
sub get_web_info;

#Takes a sentence to attempt to create a web response to a query
sub get_web_info {
  my $query        = shift;
  print "$query\n";

  #Google the query
  my @Results = Google::google_search($query . "pokemon");
  my $answer;
  
  #Check each site found until phrase found
  for my $Result (@Results) {

    print $Result;
    $answer = get_answer($query, get_html_stripped($Result));
    last if(defined($answer));
  }
  return $answer;
}

#Finds a response online via noun and past tense verb
sub get_answer {
    my($question, $text) = @_;

    #Penn-Treebank Tag and get nouns
    my $p = new Lingua::EN::Tagger;
    my @keywords = $p->get_readable($question) =~ /(\w+)\/N/g;

    #Get Past verb tense
    my (undef, undef, $inf) = verb_tense($question);
    my $stuff = Lingua::EN::Conjugate::past($inf);
    $stuff =~ /(\w+)/;
    $stuff = $1;

    #Finalize array of keywods
    push(@keywords, $stuff);
    return undef if(scalar(@keywords) == 0);

    #Remove unwanted symbols
	  $text =~ s/[\(\)*\#"{}`;:]|'\s|\s'/ /g;
	  $text =~ s/(,)/ \1 /g;
	  #Convert Mac/Windows/DOS to Unix/Linux
	  $text =~ s/\r\n|\r/\n/g;
	  #Remove text headers
	  $text =~ s/([^\?!\.]|\.[^\s\.])*?\n\n+/ /g;
	  #Remove newlines and set to lowercase
	  $text =~ s/[\n]/ /g;
	  $text = lc($text);	
	  #Tokenize textin by sentence
	  my @sentences = $text =~ /([^\?\.!]*[\?\.!]+)/g;

    my $cur = undef;
    my $counter = 0;


    #Finds a sentence if it contains all keywords
    foreach my $sentence (@sentences) {
      foreach my $key (@keywords) {
        if($sentence =~ /$key/i) {
          $counter++;
        } else { last; }
        $cur = $sentence if($counter == scalar(@keywords));
      }
      last if(defined($cur));
      $counter = 0;
    }
    return $cur;  
}

#Old Grumpy Yahoo
#sub load_info {
#  my $yahoo_query = shift;
#  print "check1\n";
#  my @Results     = Yahoo::Search->Results(Doc => "$yahoo_query",
#    AppId => "LkLBrYrV34HYay0sN2OBS4TWieRQuynilFAlwWxINblC_mOAFh9FX6jMHP1AG1ePmg--",
#"ySDteKPV34EMoQDcbmEqUdipOCoagNdD2DudPMUw3u3VpkwrWlhf.vg81AVu537SpBcpo4O6u1TJBGBRmV5yWiQ-",
    # The following args are optional.
    # (Values shown are package defaults).
#    Mode         => 'all', # all words
#    Start        => 0,
#    Count        => 1,
#    Type         => 'any', # all types
#    AllowAdult   => 0, # no porn, please
#    AllowSimilar => 0, # no dups, please
#    Language     => undef,
#    );
#  warn $@ if $@; # report any errors
#  print "check2\n";
  
#  return @Results;
#}

#strips html
sub get_html_stripped {
  my $url = "http://" . shift;
  my $content = get($url);
  return " " unless defined $content;

  my $stripper = HTML::Strip->new();
  my $naked    = $stripper->parse($content);
  $stripper->eof();
  return $naked;
}
1;


