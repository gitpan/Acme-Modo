use inc::Module::Install;

name     'Acme-Modo';
all_from 'lib/Acme/Modo.pm';
author   q{Brad Haywood <brad@perlpowered.com>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

