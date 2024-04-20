use Test2::V0;
use Log::Any::Test;    # should appear before 'use Log::Any'!
use Log::Any qw($log);

{
  package MyTest1;
  use Log::Any::Simple ':default';
  info('foo %s baz', 'bar');
  ::is($::log->msgs(), [{category => 'MyTest1', level => 'info', message => 'foo bar baz'}], 'log info default import');
  ::imported_ok(qw(trace debug info warn error fatal));
  ::not_imported_ok(qw(inform warning err crit critical alert emergency));
  $::log->clear();
}

{
  package MyTest2;
  use Log::Any::Simple ':all';
  info('foo %s baz', 'bar');
  ::is($::log->msgs(), [{category => 'MyTest2', level => 'info', message => 'foo bar baz'}], 'log info default import');
  ::imported_ok(qw(trace debug info warn error fatal));
  ::imported_ok(qw(inform warning err crit critical alert emergency));
  $::log->clear();
}

{
  package MyTest3;
  use Log::Any::Simple 'debug', 'crit';
  ::imported_ok(qw(debug crit));
  ::not_imported_ok(qw(trace info warn error fatal));
  ::not_imported_ok(qw(inform warning err critical alert emergency));
  $::log->clear();
}

{
  use Log::Any::Simple ':default', ':die_at' => 'info';
  like(dies { info('foo %s baz', 'bar') }, qr/foo bar baz/, 'dies at info');
  is($log->msgs(), [{category => 'main', level => 'info', message => 'foo bar baz'}], 'log info with die_at');
  $log->clear();
}

done_testing;
