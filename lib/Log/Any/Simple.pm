package Log::Any::Simple;

use strict;
use warnings;
use utf8;

use Carp qw(croak shortmess longmess);
use Log::Any;
use Log::Any::Adapter::Util 'logging_methods', 'numeric_level';
use Readonly;

our $VERSION = '0.01';

Readonly::Scalar my $DIE_AT_DEFAULT => numeric_level('fatal');
Readonly::Scalar my $DIE_AT_KEY => 'Log::Any::Simple/die_at';
Readonly::Scalar my $CATEGORY_KEY => 'Log::Any::Simple/category';

Readonly::Array my @ALL_LOG_METHODS =>
    (Log::Any::Adapter::Util::logging_methods(), Log::Any::Adapter::Util::logging_aliases);
Readonly::Hash my %ALL_LOG_METHODS => map { $_ => 1 } @ALL_LOG_METHODS;

Readonly::Array my @DEFAULT_LOG_METHODS => qw(trace debug info warn error fatal);

# The index of the %^H hash in the list returned by "caller".
Readonly::Scalar my $HINT_HASH => 10;

# This is slightly ugly but the intent is that the user of a module using this
# module will set this variable to 1 to get full backtrace.
our $DIE_WITH_FULL_STACK_TRACE;
our %DIE_WITH_FULL_STACK_TRACE;

sub import {  ## no critic (RequireArgUnpacking)
  my (undef) = shift @_;  # This is the package being imported, so our self.

  my %to_export;

  while (defined (my $arg = shift)) {
    if ($arg eq ':default') {  ## no critic (ProhibitCascadingIfElse)
      $to_export{$_} = 1 for @DEFAULT_LOG_METHODS;
    } elsif ($arg eq ':all') {
      $to_export{$_} = 1 for @ALL_LOG_METHODS;
    } elsif (exists $ALL_LOG_METHODS{$arg}) {
      $to_export{$arg} = 1;
    } elsif ($arg eq ':die_at') {
      my $die_at = numeric_level(shift);
      croak 'Invalid :die_at level' unless defined $die_at;
      $^H{$DIE_AT_KEY} = $die_at;
    } elsif ($arg eq ':category') {
      my $category = shift;
      croak 'Invalid :category name' unless $category;
      $^H{$CATEGORY_KEY} = $category;
    } else {
      croak "Unknown parameter: $arg";
    }
  }

  # We export all the methods at the end, so that all the modifications to the
  # %^H hash are already done and can be used by the _export method.
  _export($_) for keys %to_export;

  @_ = 'Log::Any';
  goto &Log::Any::import;
}

sub _export {
  my ($method) = @_;
  my $call_pkg = caller(1);

  my $category = _get_category($call_pkg, \%^H);
  my $logger = _get_logger($category);
  my $log_method = $method.'f';
  my $sub;
  if (_should_die($method, \%^H)) {
    $sub = sub { _die($category, $logger->$log_method(@_)) };
  } else {
    $sub = sub { $logger->$log_method(@_); return };
  }
  no strict 'refs';  ## no critic (ProhibitNoStrict)
  *{"${call_pkg}::${method}"} = $sub;
  return;
}

sub _get_category {
  my ($pkg_name, $hint_hash) = @_;
  return $hint_hash->{$CATEGORY_KEY} // $pkg_name;
}

sub _get_logger {
  my ($category) = @_;
  return Log::Any->get_logger(category => $category);
}

sub _should_die {
  my ($level, $hint_hash) = @_;
  return numeric_level($level) <= ($hint_hash->{$DIE_AT_KEY} // $DIE_AT_DEFAULT);
}

# This method is meant to be called only at logging time (and not at import time
# like the methods above)
sub _die {
  my ($category, $msg) = @_;
  my $full_trace = $DIE_WITH_FULL_STACK_TRACE || $DIE_WITH_FULL_STACK_TRACE{$category};
  my $die_msg = $full_trace ? longmess($msg) : shortmess($msg);
  # The message returned by shortmess and longmess always end with a new line,
  # so it’s fine to use die here.
  die $die_msg;  ## no critic (ErrorHandling::RequireCarping)
}

# This blocks generates in the Log::Any::Simple namespace logging methods
# that can be called directly by the user (although the standard approach would
# be to import them in the caller’s namespace). These methods are slower because
# They need to retrieve a logger each time.
for my $name (logging_methods()) {
  no strict 'refs';  ## no critic (ProhibitNoStrict)
  *{$name} = sub {
    my @caller = caller(0);
    my $hint_hash = $caller[$HINT_HASH];
    my $category = _get_category($caller[0], $hint_hash);
    my $logger = _get_logger($category);
    my $method = $name.'f';
    my $msg = $logger->$method(@_);
    _die($category, $msg) if _should_die($name, $hint_hash);
  };
}

1;

__END__
 
    my $dumper = sub {
        my ($value) = @_;
 
        return Data::Dumper->new( [$value] )->Indent(0)->Sortkeys(1)->Quotekeys(0)
        ->Terse(1)->Useqq(1)->Dump();
    };
 
