#!perl
use Test::More;
use Acme::Modo;

enum Bool => ( 'True:1', 'False:0' );

ok Bool->True, 'Boolean type True works';
is Bool->False, 0, 'Boolean type False works';

done_testing;
