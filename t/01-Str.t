#!perl
use Acme::Modo;
use Test::More;

my $str = Str->new("Hello, World!");
is $str->WHAT, 'Str', 'Got proper class type';

$str = $str + " foo";
is $str->val, "Hello, World! foo", "Added string to value";
is $str->first, "H", "Got first character";

done_testing;
