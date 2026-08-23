-- W09 release hardening: restore the additive columns required by the
-- version-controlled Admin archive RPCs. The RPC definitions have referenced
-- these fields since W07, but the canonical migration chain never created
-- them, so a fresh database failed plpgsql_check and the operations failed at
-- runtime. Keep the repair forward-only and safe when a hosted database has
-- already received the columns through an earlier manual repair.

alter table public.programs
  add column if not exists archive_idempotency_key text;

alter table public.winner_posters
  add column if not exists mutation_idempotency_key text,
  add column if not exists deleted_at timestamptz;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.programs'::regclass
      and conname = 'programs_archive_idempotency_key_shape'
  ) then
    alter table public.programs
      add constraint programs_archive_idempotency_key_shape check (
        archive_idempotency_key is null
        or length(archive_idempotency_key) between 8 and 128
      );
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.winner_posters'::regclass
      and conname = 'winner_posters_mutation_idempotency_key_shape'
  ) then
    alter table public.winner_posters
      add constraint winner_posters_mutation_idempotency_key_shape check (
        mutation_idempotency_key is null
        or length(mutation_idempotency_key) between 8 and 128
      );
  end if;
end;
$$;

create unique index if not exists programs_archive_idempotency_idx
  on public.programs(archive_idempotency_key)
  where archive_idempotency_key is not null;

create unique index if not exists winner_posters_mutation_idempotency_idx
  on public.winner_posters(mutation_idempotency_key)
  where mutation_idempotency_key is not null;

-- The wrapper calls the previously versioned implementation that performs row
-- locking. It must not be marked STABLE.
alter function public.resolve_coach_qr_for_enrollment(text) volatile;
