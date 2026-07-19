<!--
  RASCUNHO DO PR PARA O GOODJOB — revisar antes de abrir.

  O branch local já está pronto em ~/code/good_job (fix-adapter-class-pool-memoization).
  Quando você aprovar: fazemos push para o seu fork e abrimos o PR com este texto.
  Este comentário não faz parte do PR.
-->

Title: Resolve connection pool at call time in the `adapter_class` shim

Fixes #1797

## What this does

On Rails < 7.2, the `adapter_class` shim in `AdvisoryLockable` memoized a proxy whose quoting methods closed over the **connection pool object** that was current at the time of the first call. If that first call happened in a preloading server's master process (e.g. Puma with `preload_app!`), forked workers inherited a proxy pointing at the master's pool — which ActiveRecord's `ForkTracker` discards in the child — and every use raised `NoMethodError` inside `with_connection`, sending the Notifier into a crash-loop (details and reproduction in #1797).

This change keeps memoizing the proxy but captures the **class** instead of the pool, resolving `connection_pool` on each call so the proxy always uses the current process's pool. The class is safe to capture across a fork; the pool is not.

## Testing

- Added a spec asserting the proxy delegates quoting correctly, and a regression spec asserting `connection_pool` is resolved at call time (it fails against the previous implementation, where the pool was captured once; skipped on Rails >= 7.2 where the shim is not installed).
- Verified in production: this is the upstream version of the workaround we have been running since 2026-07-09 (clearing the memo in Puma's `on_worker_boot`), which eliminated the crash-loop described in the issue.
