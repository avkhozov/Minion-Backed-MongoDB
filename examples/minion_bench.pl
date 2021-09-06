use Mojo::Base -strict;

use Mojo::File qw(curfile);
use lib curfile->dirname->sibling('lib')->to_string;

use Minion;
use Time::HiRes 'time';

my $ENQUEUE     = 10000;
my $DEQUEUE     = 1000;
my $REPETITIONS = 2;
my $WORKERS     = 4;
my $INFO        = 100;
my $STATS       = 100;
my $REPAIR      = 100;
my $LOCK        = 1000;
my $UNLOCK      = 1000;

die 'set TEST_ONLINE to enable this benchmark' unless $ENV{TEST_ONLINE};

# A benchmark script for comparing backends and evaluating the performance
# impact of proposed changes
my $minion = Minion->new(MongoDB => $ENV{TEST_ONLINE});
$minion->add_task(foo => sub { });
$minion->add_task(bar => sub { });
$minion->reset({all => 1});

my @ids;

# Enqueue
say "Clean start with $ENQUEUE jobs";
my @parents = map { $minion->enqueue('foo') } 1 .. 5;
my $before  = time;
push @ids, $minion->enqueue($_ % 2 ? 'foo' : 'bar' => [] => {parents => \@parents}) for 1 .. $ENQUEUE;

my $elapsed = time - $before;
my $avg     = sprintf '%.3f', $ENQUEUE / $elapsed;
say "Enqueued $ENQUEUE jobs in $elapsed seconds ($avg/s)";

# Dequeue
sub dequeue {
  my @pids;
  for (1 .. $WORKERS) {
    die "Couldn't fork: $!" unless defined(my $pid = fork);
    unless ($pid) {
      # when forked I must reconnect client
      $minion->backend->mongodb->client->reconnect();
      my $worker = $minion->repair->worker->register;
      say "$$ will finish $DEQUEUE jobs";
      my $before = time;
      $worker->dequeue(0.5)->finish for 1 .. $DEQUEUE;
      my $elapsed = time - $before;
      my $avg     = sprintf '%.3f', $DEQUEUE / $elapsed;
      say "$$ finished $DEQUEUE jobs in $elapsed seconds ($avg/s)";
      $worker->unregister;
      exit;
    }
    push @pids, $pid;
  }

  say "$$ has started $WORKERS workers";
  my $before = time;
  waitpid $_, 0 for @pids;
  my $elapsed = time - $before;
  my $avg     = sprintf '%.3f', ($DEQUEUE * $WORKERS) / $elapsed;
  say "$WORKERS workers finished $DEQUEUE jobs each in $elapsed seconds ($avg/s)";
}
dequeue() for 1 .. $REPETITIONS;

# Job info
say "Requesting job info $INFO times";
$before = time;
my $backend = $minion->backend;
$backend->list_jobs(0, 1, {ids => [$ids[$_]]}) for 1 .. $INFO;
$elapsed = time - $before;
$avg     = sprintf '%.3f', $INFO / $elapsed;
say "Received job info $INFO times in $elapsed seconds ($avg/s)";

# Stats
say "Requesting stats $STATS times";
$before = time;
$minion->stats for 1 .. $STATS;
$elapsed = time - $before;
$avg     = sprintf '%.3f', $STATS / $elapsed;
say "Received stats $STATS times in $elapsed seconds ($avg/s)";

# Repair
say "Repairing $REPAIR times";
$before = time;
$minion->repair for 1 .. $REPAIR;
$elapsed = time - $before;
$avg     = sprintf '%.3f', $REPAIR / $elapsed;
say "Repaired $REPAIR times in $elapsed seconds ($avg/s)";

# Lock
say "Acquiring locks $LOCK times";
$before = time;
$minion->lock($_ % 2 ? 'foo' : 'bar', 3600, {limit => int($LOCK / 2)}) for 1 .. $LOCK;
$elapsed = time - $before;
$avg     = sprintf '%.3f', $LOCK / $elapsed;
say "Acquired locks $LOCK times in $elapsed seconds ($avg/s)";

# Unlock
say "Releasing locks $UNLOCK times";
$before = time;
$minion->unlock($_ % 2 ? 'foo' : 'bar') for 1 .. $UNLOCK;
$elapsed = time - $before;
$avg     = sprintf '%.3f', $UNLOCK / $elapsed;
say "Releasing locks $UNLOCK times in $elapsed seconds ($avg/s)";
