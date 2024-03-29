package Bot::Giles::Barrel;
use strict;
use warnings;

# Canned responses for when Giles gets confused
my @barrel;
$barrel[0] = "You should go catch some pokemon";
$barrel[1] = "Do you have a squirtle?";
$barrel[2] = "How long have you been training pokemon?";
$barrel[3] = "That's strange.";
# Make BOB the user's name
$barrel[4] = "Do you need to know anything about Pokemon?";
$barrel[5] = "That could be a problem.";
$barrel[6] = "Could you try to clarify that for me?";
$barrel[7] = "I may have heard about this from one of those pokemaniacs. Please elaborate.";
$barrel[8] = "Let's see if I'm getting this straight then, could you summarize for me?";
$barrel[9] = "I see... go on.";
$barrel[10] = "That's pretty crazy! Tell me more.";
$barrel[11] = "Get off mah pokelawn!";

# Creates a barrel object... honestly though, this was more OOP practice. This will just be an external
# file to store these responses in the future, since I will have to maintain message locs for every user.
sub new {
    my $class = shift;
    my $self  = {};
    $self->{PULLNUM} = -1; 
    bless ($self, $class);
    return $self;
}

sub scrape_barrel{
  my $self = shift;
	$self->{PULLNUM}++;
	if($self->{PULLNUM} == scalar(@barrel)){ $self->{PULLNUM} = 0 }
  return $barrel[$self->{PULLNUM}];
}

1;

