use Test2::V0; 

BEGIN {
  push @ARGV, qw(foo --log debug bar);
  pipe READ_STDERR, NEW_STDERR;
  open REAL_STDERR, '>&', STDERR;
  close STDERR;
  open STDERR, '>&', NEW_STDERR;
  close NEW_STDERR;
}

use Log::Any::Simple 'info', 'debug', 'trace', ':from_argv';

info 'foo';
debug 'bar';
trace 'baz';

close STDERR;
open STDERR, '>&', REAL_STDERR;
close REAL_STDERR;

my @log = <READ_STDERR>;
is(\@log, ["INFO - foo\n", "DEBUG(main) - bar\n"]);
is(\@ARGV, ['foo', 'bar']);

done_testing;
