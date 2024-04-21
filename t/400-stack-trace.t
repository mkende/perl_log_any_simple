use Test2::V0;

package MyTest {
  use Log::Any::Simple ':default';
  sub f { fatal('foo'); }
  sub g { f(); }
}

like(dies { MyTest::g() }, qr/foo.*at t\/400(?!.*\bcalled\b)/s, 'dies with short message');
{
  local $Log::Any::Simple::DIE_WITH_FULL_STACK_TRACE = 1;
  like(dies { MyTest::g() }, qr/foo.*at t\/400.*\bcalled\b/s, 'dies with long message');
}
like(dies { MyTest::g() }, qr/foo.*at t\/400(?!.*\bcalled\b)/s, 'dies with short again');
{
  local $Log::Any::Simple::DIE_WITH_FULL_STACK_TRACE{main} = 1;
  like(dies { MyTest::g() }, qr/foo.*at t\/400(?!.*\bcalled\b)/s, 'still dies with short message');
}
{
  local $Log::Any::Simple::DIE_WITH_FULL_STACK_TRACE{MyTest} = 1;
  like(dies { MyTest::g() }, qr/foo.*at t\/400.*\bcalled\b/s, 'dies with long message');
}

done_testing;
