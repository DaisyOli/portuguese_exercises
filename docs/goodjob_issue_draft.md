
Title: Memoized `adapter_class` proxy captures the pre-fork connection pool, crashing the Notifier in forked Puma workers (Rails < 7.2 + `preload_app!`)

## Summary

On Rails < 7.2, the `adapter_class` shim in `AdvisoryLockable` memoizes a proxy whose methods close over the **connection pool object** that was current at the time of the first call:

https://github.com/bensheldon/good_job/blob/main/app/models/concerns/good_job/advisory_lockable.rb#L225-L234

```ruby
unless respond_to?(:adapter_class)
  define_singleton_method(:adapter_class) do
    @_adapter_class ||= begin
      pool = connection_pool
      proxy = Object.new
      proxy.define_singleton_method(:quote_table_name) { |name| pool.with_connection { |c| c.quote_table_name(name) } }
      proxy.define_singleton_method(:quote_column_name) { |name| pool.with_connection { |c| c.quote_column_name(name) } }
      proxy
    end
  end
end
```

When Puma runs with `preload_app!` and the first call to `adapter_class` happens in the **master process before forking** (e.g. the Notifier touches it during boot), the forked workers inherit `@_adapter_class` pointing at the master's pool. ActiveRecord's `ForkTracker` discards that pool's cached connections in the child, so every subsequent `pool.with_connection` call inside the proxy raises:

```
NoMethodError: undefined method '[]' for nil
  activerecord-7.1.5.1/lib/active_record/connection_adapters/abstract/connection_pool.rb:223:in `with_connection'
```

Because `Notifier#listen_observer` reschedules immediately for errors that are not connection errors, this becomes a crash-loop (~20 errors/second in our production logs) and jobs never execute.

## Environment

- good_job 4.19.1
- Rails 7.1.5.1
- Ruby 3.3.5
- Puma 6.5.0 with `preload_app!` and `workers 2`
- PostgreSQL (Heroku Postgres), GoodJob in `:async` execution mode

Rails >= 7.2 is unaffected: `AbstractAdapter` defines `adapter_class` there, so the shim is never installed.

## Reproduction

The trigger is simply "first call happens in the master before fork". Whether that happens during a normal boot depends on timing (the Notifier heartbeat racing the fork), which is why the bug appears intermittent. It can be made deterministic in `config/puma.rb`:

```ruby
before_fork do
  # Force the memo to be populated in the master, simulating the racy
  # first call that normally comes from the Notifier during boot:
  [GoodJob::Job, GoodJob::Process, GoodJob::BatchRecord].each(&:adapter_class)
  GoodJob.shutdown
end

on_worker_boot do
  GoodJob.restart
end
```

With this configuration, every worker enters the crash-loop above and no jobs run.

A/B confirmation: clearing the memo in `on_worker_boot` makes everything work —

```ruby
on_worker_boot do
  [GoodJob::Job, GoodJob::Process, GoodJob::BatchRecord].each do |klass|
    klass.remove_instance_variable(:@_adapter_class) if klass.instance_variable_defined?(:@_adapter_class)
  end
  GoodJob.restart
end
```

This is the workaround we are running in production now.

## Suggested fix

Memoize the proxy but not the pool — resolve `connection_pool` at call time so the proxy always uses the current process's pool:

```ruby
define_singleton_method(:adapter_class) do
  @_adapter_class ||= begin
    klass = self
    proxy = Object.new
    proxy.define_singleton_method(:quote_table_name) { |name| klass.connection_pool.with_connection { |c| c.quote_table_name(name) } }
    proxy.define_singleton_method(:quote_column_name) { |name| klass.connection_pool.with_connection { |c| c.quote_column_name(name) } }
    proxy
  end
end
```

(Alternatively the memo could be invalidated after fork, but resolving the pool lazily seems simpler and matches how the rest of the codebase acquires connections.)

Happy to open a PR with this change if that helps. Thank you for GoodJob — it is a great fit for small apps that can't afford extra infrastructure!
