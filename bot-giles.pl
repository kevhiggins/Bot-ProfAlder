#!/usr/bin/perl

BEGIN { unshift @INC, "./lib"; }

=pod

=head1 NAME

kevin-alpha.pl - Combines the C<Net::OSCAR> module with the C<Bot::Giles> module to allow bot communication over AIM.

=head1 INSTALLATION

=head2 HOW TO INSTALL

Currently, no installation should be required since both required modules are in a local directory and automatically included.
Future versions will change this. Just run the script.

=head2 DEPENDENCIES

This modules requires C<Net::OSCAR> and C<Bot::Giles> which are both currently in a local directory. I'd imagine that you'll
primarily want to look at Bot::Giles in the future, since this is more of a main function to get these two modules working together.

=head1 HOW THINGS WORK

=head2 Net::OSCAR

In order to satisfy the alpha criteria of allowing my Eliza bot to talk to people over an IM client, I started by choosing AIM for the client.
Next, I googled AIM bots and discovered the easy to use C<Net::OSCAR> module. Everything needed to be done to set up an OSCAR object is done within
L<oscar_init()|/"oscar_init ()">


=head2 Bot::Giles

I created the C<Bot::Giles> module as a convenient way to allow for future expansion upon my existing Eliza bot. To create an instance of the module,
all that needs to be done is to create a giles object as seen below. To utilize it, just call $giles->talk_giles($message); with $message being
what is being said to giles. The function will return his response.

=head2 Talking to Giles

Download and install pidgin from http://www.pidgin.im/download/. Go to http://dashboard.aim.com/aim and create an AIM screenname if you don't have one. Add "BotGiles" as an AIM contact. I have you use Pidgin, because the regular AIM client adds some html code to sent messages. This should be an easy fix via regex, but it just wasn't a priority yet since it works fine on Pidgin. 

=cut

use strict;
use warnings;
use Net::OSCAR qw(:standard);
use Bot::Giles;
use Pokeget;

sub oscar_init;
sub im_in;

=pod

=head3 MAIN

Creates an OSCAR and Giles object. Waits for input via OSCAR.

=cut

#Parses out the current list of pokemon from bulbapedia
Pokeget::update_pokemon();

my $aim = oscar_init();
my $giles = Bot::Giles->new();

while(1) {
	$aim->do_one_loop();
}

=pod

=head3 METHODS

=over 4

=item oscar_init ()

1) Initialize an OSCAR object.
2) Tell the object to call L<im_in ($oscar, $sender, $message, $is_away)|/"im_in ($oscar, $sender, $message, $is_away)"> when it recieves a text message
3) Sign on to a prexisting aim account for OSCAR to take over.

=cut

sub oscar_init{
  my $oscar = Net::OSCAR->new(
	  capabilities => [qw(extended_status typing_status buddy_icons)]
  );
  $oscar->set_callback_im_in(\&im_in);
  $oscar->signon("Professor Alder", "nlpclass");
 # $oscar->signon("BotGiles", "nlpclass");
 # open(PIC,"<profalder.jpeg") or die $!;
 # $oscar->set_icon(binmode(PIC));
#  $oscar->commit_buddylist();
  return $oscar;
}

=pod

=item im_in ($oscar, $sender, $message, $is_away)

Directs messages recieved by OSCAR to Giles. Sends Giles' response back to the user.

=over 4

=item oscar

The OSCAR object which recieved a message.

=item sender

The username of the person who sent OSCAR a message.

=item message

The content of the message

=item is_away

whether or not the user's status was away.

=cut


sub im_in {
	my($oscar, $sender, $message, $is_away) = @_;
	print "[AWAY] " if $is_away;
	print "$sender: $message\n";
  my $response = $giles->talk_giles($message, $sender);
  print "$response\n";
	$oscar->send_im($sender, $response, 0 );
}







