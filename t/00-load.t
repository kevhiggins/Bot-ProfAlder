#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Bot::Giles' ) || print "Bail out!\n";
}

diag( "Testing Bot::Giles $Bot::Giles::VERSION, Perl $], $^X" );
