package Log::Any::Functions;

use strict;
use warnings;
use utf8;

use Carp;
use Log::Any;
use Log::Any::Adapter::Util 'logging_methods', 'numeric_level';
use Readonly;

Readonly::Scalar my $DIE_AT_DEFAULT => numeric_level('fatal');
Readonly::Scalar my $DIE_AT_KEY => 'Log::Any::Functions/die_at';
Readonly::Scalar my $CATEGORY_KEY => 'Log::Any::Functions/category';

Readonly::Array my @ALL_LOG_METHODS => (Log::Any::Adapter::Util::logging_methods(), Log::Any::Adapter::Util::logging_aliases);
Readonly::Hash my %ALL_LOG_METHODS => map { $_ => 1 } @ALL_LOG_METHODS;

Readonly::Array my @DEFAULT_LOG_METHODS => qw(trace debug info warn error fatal);

sub import {
  my (undef) = shift @_;  # This is the package being imported, so myself.

  while (defined (my $arg = shift)) {
    if ($arg eq ':default') {
      _export($_) for @DEFAULT_LOG_METHODS;
    } elsif ($arg eq ':all') {
      _export($_) for @ALL_LOG_METHODS;
    } elsif (exists $ALL_LOG_METHODS{$arg}) {
      _export($arg)
    } elsif ($arg eq ':die_at') {
       my $die_at = numeric_level(shift);
       croak "Invalid :die_at level" unless defined $die_at;
       $^H{$DIE_AT_KEY} = $die_at;
    } elsif ($arg eq ':category') {
       my $category = shift;
       croak "Invalid :category name" unless $category;
       $^H{$CATEGORY_KEY} = $category;
    } else {
      croak "Unknown parameter: $arg";
    }
  }

  @_ = 'Log::Any';
  goto &Log::Any::import;
}

sub _export {
  my ($method) = @_;
  my $call_pkg = caller(1);
  no strict 'refs';
  # TODO: actually generates methods, with the right logger, etc., so that they
  # are faster.
  *{"${call_pkg}::${method}"} = \&{$method};
}

# This blocks generates in the Log::Any::Functions namespace logging methods
# that can be called directly by the user (although the standard approach would
# be to import them in the caller’s namespace). These methods are slower because
# They need to retrieve a logger each time.
foreach my $name (logging_methods())
{
    no strict 'refs';
    *{$name} = sub {
        my @caller = caller(0);
        my $logger = Log::Any->get_logger(category => ($caller[10]{$CATEGORY_KEY} // $caller[0]));
        my $method = $name.'f';
        my $msg = $logger->$method(@_);
        my $pkg_hash = (caller())[10];
        if (numeric_level($name) <= ($caller[10]{$DIE_AT_KEY} // $DIE_AT_DEFAULT)) {
          die $msg;
        }
    };
}

1;


__END__
 
    my $dumper = sub {
        my ($value) = @_;
 
        return Data::Dumper->new( [$value] )->Indent(0)->Sortkeys(1)->Quotekeys(0)
        ->Terse(1)->Useqq(1)->Dump();
    };
 