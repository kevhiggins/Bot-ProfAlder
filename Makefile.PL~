use inc::Module::Install;

name     'Bot-Giles';
all_from 'lib/Bot/Giles.pm';
author   q{Kevin Higgins <kev.higgins@gmail.com>};
license  'perl';

build_requires 'Test::More';

requires 'Net::OSCAR' => 0;
requires 'LWP' => 0;
requires 'HTML::Strip' => 0;
requires 'Lingua::EN::Tagger' => 0;
requires 'Lingua::EN::Conjugate' => 0;
requires 'Lingua::EN::VerbTense' => 0;

auto_install;

WriteAll;

