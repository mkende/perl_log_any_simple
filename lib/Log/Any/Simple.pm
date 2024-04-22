package Log::Any::Simple;

use strict;
use warnings;
use utf8;

use Carp qw(croak shortmess longmess);
use Data::Dumper;
use Log::Any;
use Log::Any::Adapter::Util 'logging_methods', 'numeric_level';
use Readonly;

our $VERSION = '0.01';

Readonly::Scalar my $DIE_AT_DEFAULT => numeric_level('fatal');
Readonly::Scalar my $DIE_AT_KEY => 'Log::Any::Simple/die_at';
Readonly::Scalar my $CATEGORY_KEY => 'Log::Any::Simple/category';
Readonly::Scalar my $PREFIX_KEY => 'Log::Any::Simple/prefix';
Readonly::Scalar my $DUMP_KEY => 'Log::Any::Simple/dump';

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
    } elsif ($arg eq ':prefix') {
      my $prefix = shift;
      croak 'Invalid :prefix value' unless $prefix;
      $^H{$PREFIX_KEY} = $prefix;
    } elsif ($arg eq ':dump_long') {
      $^H{$DUMP_KEY} = 'long';
    } elsif ($arg eq ':dump_short') {
      $^H{$DUMP_KEY} = 'short';
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
  my $hint_hash = \%^H;

  my $category = _get_category($call_pkg, $hint_hash);
  my $logger = _get_logger($category, $hint_hash);
  my $log_method = $method.'f';
  my $sub;
  if (_should_die($method, $hint_hash)) {
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

sub _get_formatter {
  my ($hint_hash) = @_;
  my $dump = ($hint_hash->{$DUMP_KEY} // 'short') eq 'short' ? \&_dump_short : \&_dump_long;
  return sub {
    my (undef, undef, $format, @args) = @_;  # First two args are the category and the numeric level.
    for (@args) {
      $_ = $_->() if ref eq 'CODE';
      $_ = '<undef>' unless defined;
      next unless ref;
      $_ = $dump->($_);
    }
    return sprintf($format, @args);
  };
}

sub _get_logger {
  my ($category, $hint_hash) = @_;
  my @args = (category => $category);
  push @args, prefix => $hint_hash->{$PREFIX_KEY} if exists $hint_hash->{$PREFIX_KEY};
  push @args, formatter => _get_formatter($hint_hash);
  return Log::Any->get_logger(@args);
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

sub _dump_short {
  my ($ref) = @_;  # Can be called on anything but intended to be called on ref.
  local $Data::Dumper::Indent = 0;
  local $Data::Dumper::Pad = '';
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Sortkeys = 1;
  local $Data::Dumper::Sparseseen = 1;
  local $Data::Dumper::Quotekeys = 0;
  # Consider Useqq = 1
  return Dumper($ref);  
}

sub _dump_long {
  my ($ref) = @_;  # Can be called on anything but intended to be called on ref.
  local $Data::Dumper::Indent = 2;
  local $Data::Dumper::Pad = '    ';
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Sortkeys = 1;
  local $Data::Dumper::Sparseseen = 1;
  local $Data::Dumper::Quotekeys = 0;
  # Consider Useqq = 1
  return Dumper($ref);  
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
    my $logger = _get_logger($category, $hint_hash);
    my $method = $name.'f';
    my $msg = $logger->$method(@_);
    _die($category, $msg) if _should_die($name, $hint_hash);
  };
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Log::Any::Simple

=head1 SYNOPSIS

=head1 DESCRIPTION

Feature

=over 4

=item *

Purely functional interface with no object to manipulate.

=item *

Supports dying directly from call to the log function, so that the application
can control the amount of logging produced by dying.

=item *

Support for lazy logged data

=back

=head2 Importing

=head2 Logging

=head1 VARIABLES

=cut
