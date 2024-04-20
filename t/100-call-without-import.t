use Test2::V0;
use Log::Any::Test;    # should appear before 'use Log::Any'!
use Log::Any qw($log);

{
  use Log::Any::Simple;
  Log::Any::Simple::info('foo %s baz', 'bar');
  is($log->msgs(), [{category => 'main', level => 'info', message => 'foo bar baz'}], 'log info default import');
  $log->clear();
}

{
  use Log::Any::Simple ();
  Log::Any::Simple::info('foo %s baz', 'bar');
  is($log->msgs(), [{category => 'main', level => 'info', message => 'foo bar baz'}], 'log info no import');
  $log->clear();
}

{
  use Log::Any::Simple ':category' => 'bin';
  Log::Any::Simple::info('foo %s baz', 'bar');
  is($log->msgs(), [{category => 'bin', level => 'info', message => 'foo bar baz'}], 'log info explicit category');
  $log->clear();
}

{
  use Log::Any::Simple ':die_at' => 'info';
  like(dies { Log::Any::Simple::info('foo %s baz', 'bar') }, qr/foo bar baz/, 'dies at info');
  is($log->msgs(), [{category => 'main', level => 'info', message => 'foo bar baz'}], 'log info with die_at');
  $log->clear();
}

{
  package Foo::Bar;
  use Log::Any::Simple;
  Log::Any::Simple::info('foo');
  ::is($::log->msgs(), [{category => 'Foo::Bar', level => 'info', message => 'foo'}], 'log info in package');
  $::log->clear();
}

done_testing;
