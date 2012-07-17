#!perl
use Test::More;
use Acme::Modo;

my $arr = Array->new(qw< Hello >);
$arr = $arr + ['World'];

my $str = ($arr /= ' ') + " How are you?";
is $str->WHAT, 'Str', 'Converted to Str class through join';
is $str->val, "Hello World How are you?", "Concatted string";

my $weekdays = Array->new(qw< Mon Tue Wed Thu Fri >);
ok $weekdays ~~ 'Tue', 'Array matching is working';

$weekdays = $weekdays << ['Sun'];
is $weekdays->first, 'Sun', 'Unshifting operator is working';
done_testing;

