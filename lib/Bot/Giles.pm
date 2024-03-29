package Bot::Giles;

=pod

=head1 NAME

Bot::Giles - A bot to talk to when you are lonely and need a friend

=head1 VERSION

Version 0.50

=head1 SYNOPSIS

use Bot::Giles;

my $giles = Bot::Giles->new();

print $giles->talk_giles("I am lonely. Save me Giles!");

=head1 HOW TO INSTALL

Not currently necessary

=head1 PURPOSE

Will respond to inputted messages in its own special botly way to keep you company

=cut


use 5.006001;
use strict;
use warnings;
use HTML::Strip;
use Bot::Giles::Barrel;
use parse_search;
use Switch;
use Pokeget;

our $VERSION = '0.50';

=pod

=head3 METHODS

=over 4

=item new ()

Creates a new C<Bot::Giles> object which contains a barrel object (This will be changed in Beta to a list of users so as to keep track of different conversations)

=cut

sub new {
    my $class = shift;
    my $self  = {};
    $self->{BARREL} = Bot::Giles::Barrel->new();
    
    #Create a list of people spoken to
    $self->{BUDDY_LIST} = {};
    if(-e "profs_friends.txt") {
      open(FRIENDS, "<profs_friends.txt") or die $!;
      my $buddies = do { local( $/ ) ; <FRIENDS> } or die $!;
      close(FRIENDS);
      my @tmp_ID = $buddies =~ /'(.*)' '.*'/g;
      my @tmp_name = $buddies =~ /'.*' '(.*)'/g;
      for(0..scalar(@tmp_ID)-1) {
        $self->{BUDDY_LIST}->{$tmp_ID[$_]} = [];
        $self->{BUDDY_LIST}->{$tmp_ID[$_]}->[0] = $tmp_name[$_];
        $self->{BUDDY_LIST}->{$tmp_ID[$_]}->[1] = 0; #Waiting on name?
        $self->{BUDDY_LIST}->{$tmp_ID[$_]}->[2] = 1; #Conversation state
      }

    } else {
      open(FRIENDS, ">profs_friends.txt") or die $!;
      print FRIENDS "'Professor Alder' 'Professor Oak'\n";
      close(FRIENDS);
    }
    bless ($self, $class);
    return $self;
}

=pod

=item talk_giles (message)

Responds to a message in a elizaish manner

=over 4

=item message

The message Giles will respond to

=back

=cut

#Returns a random sentence
sub random_sent {
  my $array_ptr = shift;
  srand(time());
  my $num = int(rand(scalar(@{$array_ptr})));
  return $array_ptr->[$num];
}

#Chcks what state the professor is in and responds appropriately
sub state_check {
  my($self, $query, $sender) = @_;
  if(exists($self->{BUDDY_LIST}->{$sender})){
    my $tmp = $self->{BUDDY_LIST}->{$sender}->[2];
    $self->{BUDDY_LIST}->{$sender}->[2] = 3;
    switch($tmp) {
      case 0  {
        return "Excellent, what's your favorite pokemon?" if($query =~ /[Yy]es/);

        return "That's alright I happen to be a pokemon researcher! Things I'm particularly interested in are Pokemon and their attributes, so if you'd like to hear what my current pokemon of study are, or where to find them, what color they are... pokenumber, let me know." if($query =~ /[Nn]o/);
      }
      case 1 { 
        my @responses = (
          "Hey there " . $self->{BUDDY_LIST}->{$sender}->[0] . " how have your pokemon travels been going?",
          "Hello again ". $self->{BUDDY_LIST}->{$sender}->[0] .  ", how are your pokemon doing?",
          "Nice to see you again ". $self->{BUDDY_LIST}->{$sender}->[0] .". Any pokenews?"
        );
        return random_sent(\@responses);
      
      }
      else {return undef;}
    }
  }
}

#Gets new friends name
sub name_waiting {
  my($self, $query, $sender) = @_;
  if(exists($self->{BUDDY_LIST}->{$sender})){
    if($self->{BUDDY_LIST}->{$sender}->[1] == 1) {
      $self->{BUDDY_LIST}->{$sender}->[1] = 0;
      $query =~ /(\w+)$/;
      open(FRIENDS, ">>profs_friends.txt") or die $!;
      $self->{BUDDY_LIST}->{$sender}->[0] = $1;
      print FRIENDS "'$sender' '$1'\n";
      close(FRIENDS);
      $self->{BUDDY_LIST}->{$sender}->[2] = 0;
      return "Nice to meet you $1. Do you know anything about pokemon?";
    }
  }
  return undef;
}

#Filters output of garbage
sub talk_giles {
  my($self, $query, $sender) = @_;
  my $answer = talk_decision($self, $query, $sender);
 # $answer =~ s/\n//g;
  $answer =~ s/^\s+//g;
  $answer =~ s/ ([,\.\?!])/$1/g;
  $answer =~ s/poké/poke/g;
  $answer =~ s/ +/ /g;
  $answer =~ s/([^\.\?!])$/$1\./;
  return $answer;
}

sub talk_decision {
 # my $self = shift;
 # if(@_){ $_ = shift }
  my($self, $query, $sender) = @_;
  
  #Strip html. This is a concern for people using an actual AIM client
  my $stripper = HTML::Strip->new();
  $query   = $stripper->parse($query);
  $stripper->eof();

  #Store punctuation here do determine if question asked
  my $punc;
  if($query =~ /([\.\?!])/) {
    $punc = $1;

  }
  else {$punc = 0;}

  #Remove punctuation
  $query = $1 if($query =~/(^[^\.|^\?|^!]+)/);

  #Fine, I'm bored -> I'm bored
  $query = $1 if($query =~ /^\w+, (.*)/);


  #Check if the sender was supposed to give a name
  my $waiting = name_waiting($self, $query, $sender);  
  return $waiting if(defined($waiting));

  #If we haven't met this person say so, and set sender to name waiting state
  if(!exists($self->{BUDDY_LIST}->{$sender})) {
    $self->{BUDDY_LIST}->{$sender} = [];
    $self->{BUDDY_LIST}->{$sender}->[1] = 1;
    
    return "Hello there! I'm Professor Alder... I don't believe we've met. What's your name?";
  }

  #Checks to see if the professor has a state to respond to
  my $answer = state_check($self, $query, $sender);
  return $answer if(defined($answer));  

  #Checks to see if the professor can respond with pokemon factoids
  $answer = Pokeget::poke_query($query);
  return $answer if(defined($answer)); 

  #Answers the question about pokemon
  return "Pokemon are animals raised by trainers and used to battle other trainers. For example, my Piplup... ask me about my piplup :)" if($query =~ /(?:\bwhats?\b|\bwhat's\b).*?\bpokemon\b/i);

  #Talks about self if referred to
  $answer = Pokeget::talk_self() if($query =~ /(?:your?|you'?re|yours|you'?ve|you'?d)/i);
  return $answer if(defined($answer));

  #If we make it here, and a question was asked, find a poorly crafted response
  if($punc eq "?") {
    $answer = parse_search::get_web_info($query);
    return $answer if(defined($answer));
  } 

	#Some simple word matching
	if($query =~ /^[Nn]o/){
		return "That's too bad...";
	}
	elsif($query =~ /^[Yy]es/){
		return "Interesting, tell me more.";
	}
	elsif($query =~ /.*\b[Pp]okeball\b.*/){
		return "What's in your pokeball?";
	}
	elsif($query =~ /.*\b[Gg]ym\b.*/){
		return "Do you have any gym badges?";
	}
	elsif($query =~ /.*\b[Pp]okedex\b.*/){
		return "There are a lot of pokemon aren't there?";
	}
	elsif($query =~ /.*\b[Ee]lite\b.*/){
		return "The elite four scares me.";
	}
	#If "I am" used, transform sentence
  elsif($query =~ /^\b(I am)|(I'm)\b /) {
    $query =~ s/\byou\b/me/g;
    $query =~ s/\b(I am)|(I'm)\b/you/g;
    $query =~ s/\b[Mm]yself\b/yourself/g;
    $query =~ s/\b[Mm]y\b/your/g;
    $query =~ s/because//ig;
    return "Why are $query?";
  }
  #If "I" used, transform sentence
	elsif($query =~ /^\bI\b/){
    $query =~ s/\byou\b/me/g;
    $query =~ s/\bI\b/you/g;
    $query =~ s/\b[Mm]yself\b/yourself/g;
    $query =~ s/\b[Mm]y\b/your/g;	
    $query =~ s/\w*n'?t/not/g;	
		return "Why do $query?";
	}
  #I can't wait to leave.
  #Why can't you wait to leave?
  #I hate pokemon
  #Why do you hate pokemon?

	#If "My" used, transform sentence
	elsif($query =~ /^\bMy\b/){
		$query =~ s/\b[Mm]y\b/your/g;
		$query =~ s/\bI\b/you/g;
		$query =~ s/\bI'm\b/you're/g;
		return "Why do you think $query?";
	}
	else{ return $self->{BARREL}->scrape_barrel() }
  }

1;

