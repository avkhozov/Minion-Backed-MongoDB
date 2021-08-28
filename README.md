# NAME

Minion::Backend::MongoDB - MongoDB backend for Minion

[![Build Status](https://travis-ci.org/avkhozov/Minion-Backend-MongoDB.png?branch=master)](https://travis-ci.org/avkhozov/Minion-Backend-MongoDB)

# VERSION

version 1.06

# SYNOPSIS

    use Minion::Backend::MongoDB;

    my $backend = Minion::Backend::MongoDB->new('mongodb://127.0.0.1:27017');

# DESCRIPTION

This is a [MongoDB](https://metacpan.org/pod/MongoDB) backend for [Minion](https://metacpan.org/pod/Minion) v10.01 (2019-12-16) derived from
[MongoDB::Minion::Pg](https://metacpan.org/pod/MongoDB%3A%3AMinion%3A%3APg) and which supports all its features.

# ATTRIBUTES

[Minion::Backend::MongoDB](https://metacpan.org/pod/Minion%3A%3ABackend%3A%3AMongoDB) inherits all attributes from [Minion::Backend](https://metacpan.org/pod/Minion%3A%3ABackend) and
implements the following new ones.

## mongodb

    my $mongodb = $backend->mongodb;
    $backend  = $backend->mongodb(MongoDB->new);

[MongoDB::Database](https://metacpan.org/pod/MongoDB%3A%3ADatabase) object used to store collections.

## jobs

    my $jobs = $backend->jobs;
    $backend = $backend->jobs(MongoDB::Collection->new);

[MongoDB::Collection](https://metacpan.org/pod/MongoDB%3A%3ACollection) object for `jobs` collection, defaults to one based on ["prefix"](#prefix).

## notifications

    my $notifications = $backend->notifications;
    $backend          = $backend->notifications(MongoDB::Collection->new);

[MongoDB::Collection](https://metacpan.org/pod/MongoDB%3A%3ACollection) object for `notifications` collection, defaults to one based on ["prefix"](#prefix).

## prefix

    my $prefix = $backend->prefix;
    $backend   = $backend->prefix('foo');

Prefix for collections, defaults to `minion`.

## workers

    my $workers = $backend->workers;
    $backend    = $backend->workers(MongoDB::Collection->new);

[MongoDB::Collection](https://metacpan.org/pod/MongoDB%3A%3ACollection) object for `workers` collection, defaults to one based on ["prefix"](#prefix).

# METHODS

[Minion::Backend::MongoDB](https://metacpan.org/pod/Minion%3A%3ABackend%3A%3AMongoDB) inherits all methods from [Minion::Backend](https://metacpan.org/pod/Minion%3A%3ABackend) and implements the following new ones.

## broadcast

    my $bool = $backend->broadcast('some_command');
    my $bool = $backend->broadcast('some_command', [@args]);
    my $bool = $backend->broadcast('some_command', [@args], [$id1, $id2, $id3]);

Broadcast remote control command to one or more workers.

## dequeue

    my $info = $backend->dequeue($worker_id, 0.5);

Wait for job, dequeue it and transition from `inactive` to `active` state or
return `undef` if queue was empty.

## enqueue

    my $job_id = $backend->enqueue('foo');
    my $job_id = $backend->enqueue(foo => [@args]);
    my $job_id = $backend->enqueue(foo => [@args] => {priority => 1});

Enqueue a new job with `inactive` state. These options are currently available:

- delay

        delay => 10

    Delay job for this many seconds from now.

- priority

        priority => 5

    Job priority, defaults to `0`.

## fail\_job

    my $bool = $backend->fail_job($job_id);
    my $bool = $backend->fail_job($job_id, 'Something went wrong!');

Transition from `active` to `failed` state.

## finish\_job

    my $bool = $backend->finish_job($job_id);

Transition from `active` to `finished` state.

## job\_info

    my $info = $backend->job_info($job_id);

Get information about a job or return `undef` if job does not exist.

## list\_jobs

    my $batch = $backend->list_jobs($skip, $limit);
    my $batch = $backend->list_jobs($skip, $limit, {state => 'inactive'});

Returns the same information as ["job\_info"](#job_info) but in batches.

These options are currently available:

- ids

        ids => ['23', '24']

    List only jobs with these ids.

- notes

        notes => ['foo', 'bar']

    List only jobs with one of these notes. Note that this option is EXPERIMENTAL
    and might change without warning!

- queues

        queues => ['important', 'unimportant']

    List only jobs in these queues.

- state

        state => 'inactive'

    List only jobs in this state.

- task

        task => 'test'

    List only jobs for this task.

These fields are currently available:

- args

        args => ['foo', 'bar']

    Job arguments.

- attempts

        attempts => 25

    Number of times performing this job will be attempted.

- children

        children => ['10026', '10027', '10028']

    Jobs depending on this job.

- created

        created => 784111777

    Epoch time job was created.

- delayed

        delayed => 784111777

    Epoch time job was delayed to.

- finished

        finished => 784111777

    Epoch time job was finished.

- id

        id => 10025

    Job id.

- notes

        notes => {foo => 'bar', baz => [1, 2, 3]}

    Hash reference with arbitrary metadata for this job.

- parents

        parents => ['10023', '10024', '10025']

    Jobs this job depends on.

- priority

        priority => 3

    Job priority.

- queue

        queue => 'important'

    Queue name.

- result

        result => 'All went well!'

    Job result.

- retried

        retried => 784111777

    Epoch time job has been retried.

- retries

        retries => 3

    Number of times job has been retried.

- started

        started => 784111777

    Epoch time job was started.

- state

        state => 'inactive'

    Current job state, usually `active`, `failed`, `finished` or `inactive`.

- task

        task => 'foo'

    Task name.

- time

        time => 78411177

    Server time.

- worker

        worker => '154'

    Id of worker that is processing the job.

## list\_locks

    my $results = $backend->list_locks($offset, $limit);
    my $results = $backend->list_locks($offset, $limit, {names => ['foo']});

Returns information about locks in batches.

    # Get the total number of results (without limit)
    my $num = $backend->list_locks(0, 100, {names => ['bar']})->{total};

    # Check expiration time
    my $results = $backend->list_locks(0, 1, {names => ['foo']});
    my $expires = $results->{locks}[0]{expires};

These options are currently available:

- names

        names => ['foo', 'bar']

    List only locks with these names.

These fields are currently available:

- expires

        expires => 784111777

    Epoch time this lock will expire.

- name

        name => 'foo'

    Lock name.

## list\_workers

    my $results = $backend->list_workers($offset, $limit);
    my $results = $backend->list_workers($offset, $limit, {ids => [23]});

Returns information about workers in batches.

    # Get the total number of results (without limit)
    my $num = $backend->list_workers(0, 100)->{total};

    # Check worker host
    my $results = $backend->list_workers(0, 1, {ids => [$worker_id]});
    my $host    = $results->{workers}[0]{host};

These options are currently available:

- ids

        ids => ['23', '24']

    List only workers with these ids.

These fields are currently available:

- id

        id => 22

    Worker id.

- host

        host => 'localhost'

    Worker host.

- jobs

        jobs => ['10023', '10024', '10025', '10029']

    Ids of jobs the worker is currently processing.

- notified

        notified => 784111777

    Epoch time worker sent the last heartbeat.

- pid

        pid => 12345

    Process id of worker.

- started

        started => 784111777

    Epoch time worker was started.

- status

        status => {queues => ['default', 'important']}

    Hash reference with whatever status information the worker would like to share.

## lock

    my $bool = $backend->lock('foo', 3600);
    my $bool = $backend->lock('foo', 3600, {limit => 20});

Try to acquire a named lock that will expire automatically after the given
amount of time in seconds. An expiration time of `0` can be used to check if a
named lock already exists without creating one.

These options are currently available:

- limit

        limit => 20

    Number of shared locks with the same name that can be active at the same time,
    defaults to `1`.

## new

    my $backend = Minion::Backend::MongoDB->new('mongodb://127.0.0.1:27017');

Construct a new [Minion::Backend::MongoDB](https://metacpan.org/pod/Minion%3A%3ABackend%3A%3AMongoDB) object. Required a
[connection string URI](https://metacpan.org/pod/MongoDB%3A%3AMongoClient#CONNECTION-STRING-URI). Optional
every other attributes will be pass to [MongoDB::MongoClient](https://metacpan.org/pod/MongoDB%3A%3AMongoClient) costructor.

## note

    my $bool = $backend->note($job_id, {mojo => 'rocks', minion => 'too'});

Change one or more metadata fields for a job. Setting a value to `undef` will
remove the field.

## purge

    $backend->purge();
    $backend->purge({states => ['inactive'], older => 3600});

Purge all jobs created older than...

These options are currently available:

- older

        older => 3600

    Value in seconds to purge jobs older than this value.

    Default: $minion->remove\_after

- older\_field

        older_field => 'created'

    What date field to use to check if job is older than.

    Default: 'finished'

- queues

        queues => ['important', 'unimportant']

    Purge only jobs in these queues.

- states

        states => ['inactive', 'failed']

    Purge only jobs in these states.

- tasks

        tasks => ['task1', 'task2']

    Purge only jobs for these tasks.

- queues

        queues => ['q1', 'q2']

    Purge only jobs for these queues.

## receive

    my $commands = $backend->receive($worker_id);

Receive remote control commands for worker.

## register\_worker

    my $worker_id = $backend->register_worker;
    my $worker_id = $backend->register_worker($worker_id);

Register worker or send heartbeat to show that this worker is still alive.

## remove\_job

    my $bool = $backend->remove_job($job_id);

Remove `failed`, `finished` or `inactive` job from queue.

## repair

    $backend->repair;

Repair worker registry and job queue if necessary.

## reset

    $backend->reset({all => 1});

Reset job queue.

These options are currently available:

- all

        all => 1

    Reset everything.

- locks

        locks => 1

    Reset only locks.

## retry\_job

    my $bool = $backend->retry_job($job_id);
    my $bool = $backend->retry_job($job_id, {delay => 10});

Transition from `failed` or `finished` state back to `inactive`.

These options are currently available:

- delay

        delay => 10

    Delay job for this many seconds (from now).

## stats

    my $stats = $backend->stats;

Get statistics for jobs and workers.

## unregister\_worker

    $backend->unregister_worker($worker_id);

Unregister worker.

## worker\_info

    my $info = $backend->worker_info($worker_id);

Get information about a worker or return `undef` if worker does not exist.

## \_oid

    my $mongo_oid = $backend->_oid($hex_24length);

EXPERIMENTAL: Convert an 24-byte hexadecimal value into a `BSON::OID` object.
Usually, it should be used only if you need to query the MongoDB directly

# NOTES ABOUT USER

User must have this roles

    "roles" : [
                  {
                          "role" : "dbAdmin",
                          "db" : "minion"
                  },
                  {
                          "role" : "clusterMonitor",
                          "db" : "admin"
                  },
                  {
                          "role" : "readWrite",
                          "db" : "minion"
                  }
          ]

# SEE ALSO

[Minion](https://metacpan.org/pod/Minion), [MongoDB](https://metacpan.org/pod/MongoDB), [http://mojolicio.us](http://mojolicio.us).

# AUTHOR

Emiliano Bruni <info@ebruni.it>, Andrey Khozov <avkhozov@gmail.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2020 by Emiliano Bruni, Andrey Khozov.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007
