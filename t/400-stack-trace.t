use Test2::V0;

package MyTest {
  use Log::Any::Simple ':default';
  sub f { fatal('foo'); }
  sub g { f(); }
}

like(dies { MyTest::g() }, qr/foo.*at t\/400(?!.*\bcalled\b)/s, 'dies with short message');

Log::Any::Simple::die_with_stack_trace('long');
like(dies { MyTest::g() }, qr/foo.*at t\/400.*\bcalled\b/s, 'dies with long message');

Log::Any::Simple::die_with_stack_trace('none');
like(dies { MyTest::g() }, qr/^foo\n$/s, 'dies with no trace');

Log::Any::Simple::die_with_stack_trace('short');
like(dies { MyTest::g() }, qr/foo.*at t\/400(?!.*\bcalled\b)/s, 'dies with short again');

Log::Any::Simple::die_with_stack_trace(main => 'long');
like(dies { MyTest::g() }, qr/foo.*at t\/400(?!.*\bcalled\b)/s, 'still dies with short message');

Log::Any::Simple::die_with_stack_trace(MyTest => 'long');
like(dies { MyTest::g() }, qr/foo.*at t\/400(?!.*\bcalled\b)/s, 'still dies with short message again');

Log::Any::Simple::die_with_stack_trace(undef);
like(dies { MyTest::g() }, qr/foo.*at t\/400.*\bcalled\b/s, 'dies with long message again');

done_testing;
