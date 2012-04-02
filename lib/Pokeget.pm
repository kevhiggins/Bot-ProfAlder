#!/usr/bin/perl
BEGIN { unshift @INC, "./../lib"; }
package Pokeget;

use strict;
use LWP::Simple qw/get $ua/;
use HTML::Strip;
use Lingua::EN::Tagger;

#Run on startup. Gets a list of every pokemon
sub update_pokemon {
    my $html = get_page("http://bulbapedia.bulbagarden.net/wiki/List_of_Pokémon_by_Kanto_Dex_number");
    my @pokemon_list = $html =~ /title="(.*?) \(Pok.mon\)">\1<\/a>/g;
    open(FOUT, ">current_pokemon.txt") or die $!;

    foreach(@pokemon_list){
        print FOUT;
        print FOUT "\n";
    }

    close(FOUT);
}

#Checks to see if $noun is a pokemon
sub is_pokemon {
    my $noun = shift;
    open(POKEMON, "current_pokemon.txt") or die $!;
    my $textin = do { local( $/ ) ; <POKEMON> } or die "Bad file name\n";
    close(POKEMON);
    if($textin =~ /\b$noun\b/i) {
        return 1;
    }    
    else {return 0;}
}

#The professor talks about himself
sub talk_self {
  my $stripper = HTML::Strip->new();
  my $html = get_page("http://bulbapedia.bulbagarden.net/wiki/Professor_Rowan");
  $html =~ /<span class="mw-headline">In the games<\/span><\/h2>(.*?)<a name="Name"><\/a><h3> <span class="mw-headline">Name<\/span><\/h3>/s;
  $html = $1;
  my $text = $stripper->parse($html);

	$text =~ s/[*\#"{}`;:]|'\s|\s'/ /g;
	$text =~ s/(,)/ \1 /g;
	#Convert Mac/Windows/DOS to Unix/Linux
	$text =~ s/\r\n|\r/\n/g;
	#Remove text headers
	$text =~ s/([^\?!\.]|\.[^\s\.])*?\n\n+/ /g;
	#Remove newlines and set to lowercase
	$text =~ s/[\n]/ /g;
	$text = lc($text);	
	
  $text =~ s/\(.*?\)//ig;
  $text =~ s/Professor Rowan/I/ig;
  $text =~ s/the professor/I/ig;
  $text =~ s/\bhe\b/I/ig;
  $text =~ s/\bhis\b/my/ig;
  $text =~ s/\bis\b/am/ig;
  $text =~ s/Rowan'?s/my/ig;
  $text =~ s/\bhas\b/have/ig;
  $text =~ s/\bhim\b/me/ig;
  my @factoids = $text =~ /([^\?\.!]*[\?\.!]+)/g;
  srand(time());
  return $factoids[int(rand(scalar(@factoids)))];
  


}

#Get's html poke info
sub get_poke_info {
    my $pokemon = ucfirst(shift);
    return get_page("http://bulbapedia.bulbagarden.net/wiki/".$pokemon."_(Pokémon)");
}

#Gets an HTML page
sub get_page {
    my $url = shift;
    $ua->agent("Professor Oak");
    return get($url);
}

#Gets the pokemons physiology
sub get_physiology {
    my $pokemon = ucfirst(shift);

    get_poke_info($pokemon) =~ /name="Physiology".*?<p>(.*?[\.\?!])/s;
    return $1;
}

#Gets the pokemon's location
sub get_location {
  my $pokemon = ucfirst(shift);
  my $stripper = HTML::Strip->new();
  $stripper->parse(get_poke_info($pokemon)) =~ /Habitat.*?Habitat.*?\n.*?\n(.*?(?:found|live|prefer).*?)[\.\?!,]/si;
  return $1 . ".";
}

#Gets what the pokemon evolves into
sub get_evolution {
    my $pokemon = ucfirst(shift);
    my $stripper = HTML::Strip->new();
    $stripper->parse(get_poke_info($pokemon)) =~ /(evolves into.*?)\s?[\.\?!,]/;
    return "$pokemon $1." ;
}

#Gets what evolves into the pokemon
sub get_devolution {
    my $pokemon = ucfirst(shift);
    my $stripper = HTML::Strip->new();
    $stripper->parse(get_poke_info($pokemon)) =~ /(evolves from.*?)\s?[\.\?!,]/;
    return "$pokemon $1.";
}

#Gets the pokemon's type
sub get_type {
    my $pokemon = ucfirst(shift);
    get_poke_info($pokemon) =~ /title="Elemental types">Types?<\/a>\n(<\/th>.*<\/a>)/;
    my $line = $1;
    my @types = $line =~ /title=".*?">(.*?)<\/a>/g;
    my $typers = shift(@types);
    foreach(@types) {
      $typers = $typers . "/" . "$_";
    }
    return $pokemon . lc(" is a $typers type pokemon.");
}

#Get the pokemon's color
sub get_color {
    my $pokemon = ucfirst(shift);
    get_poke_info($pokemon) =~ /Pokédex color<\/a>\n<\/th><td> (.*)/;
   
    return $pokemon . lc(" is $1.");
}

#Get the pokemons pokedex number
sub get_number {
  my $pokemon = ucfirst(shift);
  get_poke_info($pokemon) =~ /National Dex<\/a>\n<\/th><td> (.*)/;
  return $pokemon . " is $1 according to my pokedex.";
}

#Spout random pokemon trivia
sub get_trivia {
  my $pokemon = ucfirst(shift);
  get_poke_info($pokemon) =~ /Trivia<\/span><\/h2>\n(.*?)\n<a name="Origin"><\/a><h3> <span class="mw-headline">Origin<\/span><\/h3>/s;  
  my $stripper = HTML::Strip->new();
  my $text = $stripper->parse($1);
  $text =~ s/\n\s*?\n/\n/g;
  $stripper->eof();
  my @lines = split(/\n/, $text);
  srand(time());
  return $lines[int(rand(scalar(@lines)))];
}

#Checks what to say about a pokemon
sub info_get {
  my($noun, $query) = @_;
  return get_evolution($noun) if($query =~ /evolves? from $noun/i);
  return get_devolution($noun) if($query =~ /evolves? from/i);
  return get_evolution($noun) if($query =~ /evolves? into/i);
  return get_physiology($noun) if($query =~ /(?:what is|who is|does|do|appearance|visage|looks?)/i);
  return get_location($noun) if($query =~ /(?:find|found|locate|lives?|habitat|home|domain|territory|where)/i);
  return get_type($noun) if($query =~ /types?/);
  return get_color($noun) if($query =~ /(?:colou?r)/);
  return get_number($noun) if($query =~ /(?:number|#)/);
  return get_trivia($noun);
}

#Called to see if a query is pokemon info worthy
sub poke_query {
  my $query = shift;
  print $query;
  print "boo\n";
  my $p = new Lingua::EN::Tagger;
  my @keywords = $p->get_readable($query) =~ /(\w+)\/N/g;
  print "@keywords";
  my $answer = undef;
  foreach my $noun (@keywords) {
    if(is_pokemon($noun)) {
      $answer = info_get($noun, $query);
      last;
    }
  }
  return $answer;
  
}



1;
