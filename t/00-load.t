#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::Modo' ) || print "Bail out!\n";
}

diag( "Testing Acme::Modo $Modo::VERSION, Perl $], $^X" );
