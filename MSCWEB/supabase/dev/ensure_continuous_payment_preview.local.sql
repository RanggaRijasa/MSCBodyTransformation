\set ON_ERROR_STOP on

-- Local-only rotating fixtures. This file is intentionally not a migration and
-- must never be applied to hosted production.
create or replace function public.ensure_repeatable_local_program_fixtures()
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor_id uuid := (select auth.uid());
  admin_user_id uuid;
  actor_role text;
  archived_count integer := 0;
  inserted_count integer := 0;
  affected_count integer := 0;
  local_today date := (statement_timestamp() at time zone 'Asia/Makassar')::date;
begin
  select profile.role
  into actor_role
  from public.profiles profile
  where profile.user_id = actor_id;

  if actor_id is null or actor_role not in ('participant', 'coach') then
    raise exception 'permission_denied';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('mscweb-repeatable-local-program-fixtures', 0)
  );

  select profile.user_id
  into admin_user_id
  from public.profiles profile
  where profile.role = 'admin'
  order by profile.created_at, profile.user_id
  limit 1;

  if admin_user_id is null then
    raise exception 'local_admin_required';
  end if;

  -- Retire all legacy W05 preview rows and any consumed rotating fixture. Their
  -- immutable order/audit history remains intact, but they disappear from the
  -- repeatable catalog contract.
  update public.programs program
  set status = 'archived',
      published_at = null,
      category = 'Pengujian lokal berulang'
  where program.status in ('scheduled', 'active')
    and (
      program.title like 'Program Uji Pembayaran Lokal #%'
      or program.title = 'Program Pembayaran Browser W05'
      or (
        program.category = 'Pengujian lokal berulang'
        and program.title in ('Program uji lokal gratis', 'Program uji lokal berbayar')
        and (
          exists (
            select 1
            from public.program_enrollments enrollment
            where enrollment.program_id = program.id
          )
          or exists (
            select 1
            from public.payment_orders payment_order
            where payment_order.program_id = program.id
          )
        )
      )
    );
  get diagnostics affected_count = row_count;
  archived_count := archived_count + affected_count;

  -- Concurrency or an interrupted previous run may leave more than one clean
  -- row. Keep one per price mode and retire the rest.
  with ranked_clean as (
    select
      program.id,
      row_number() over (
        partition by program.pricing_mode
        order by program.created_at, program.id
      ) as fixture_rank
    from public.programs program
    where program.category = 'Pengujian lokal berulang'
      and program.title in ('Program uji lokal gratis', 'Program uji lokal berbayar')
      and program.status in ('scheduled', 'active')
      and program.published_at is not null
      and not exists (
        select 1 from public.program_enrollments enrollment
        where enrollment.program_id = program.id
      )
      and not exists (
        select 1 from public.payment_orders payment_order
        where payment_order.program_id = program.id
      )
  )
  update public.programs program
  set status = 'archived', published_at = null
  where program.id in (
    select ranked_clean.id
    from ranked_clean
    where ranked_clean.fixture_rank > 1
  );
  get diagnostics affected_count = row_count;
  archived_count := archived_count + affected_count;

  if not exists (
    select 1
    from public.programs program
    where program.category = 'Pengujian lokal berulang'
      and program.title = 'Program uji lokal berbayar'
      and program.status in ('scheduled', 'active')
      and program.published_at is not null
      and not exists (
        select 1 from public.program_enrollments enrollment
        where enrollment.program_id = program.id
      )
      and not exists (
        select 1 from public.payment_orders payment_order
        where payment_order.program_id = program.id
      )
  ) then
    insert into public.programs (
      title, summary, category, status, pace, duration_mode, starts_on,
      ends_on, timezone, participant_limit, past_step_policy,
      future_step_policy, wellness_disclaimer, points_per_activity,
      points_per_weight_kg, quiz_passing_percentage, pricing_mode,
      desired_price, published_at, created_by
    ) values (
      'Program uji lokal berbayar',
      'Uji alur QR Coach, pembayaran manual, dan unggah bukti. Fixture ini otomatis diperbarui setelah digunakan.',
      'Pengujian lokal berulang', 'active', 'scheduled', 'specific_dates',
      local_today, local_today + 30, 'Asia/Makassar', 100, 'read_only',
      'locked', 'Fixture pengujian lokal. Jangan melakukan pembayaran nyata.',
      10, 100, 70, 'paid', 125000, statement_timestamp(), admin_user_id
    );
    inserted_count := inserted_count + 1;
  end if;

  if not exists (
    select 1
    from public.programs program
    where program.category = 'Pengujian lokal berulang'
      and program.title = 'Program uji lokal gratis'
      and program.status in ('scheduled', 'active')
      and program.published_at is not null
      and not exists (
        select 1 from public.program_enrollments enrollment
        where enrollment.program_id = program.id
      )
      and not exists (
        select 1 from public.payment_orders payment_order
        where payment_order.program_id = program.id
      )
  ) then
    insert into public.programs (
      title, summary, category, status, pace, duration_mode, starts_on,
      ends_on, timezone, participant_limit, past_step_policy,
      future_step_policy, wellness_disclaimer, points_per_activity,
      points_per_weight_kg, quiz_passing_percentage, pricing_mode,
      desired_price, published_at, created_by
    ) values (
      'Program uji lokal gratis',
      'Uji alur QR Coach untuk program gratis. Fixture ini otomatis diperbarui setelah digunakan.',
      'Pengujian lokal berulang', 'active', 'scheduled', 'specific_dates',
      local_today, local_today + 30, 'Asia/Makassar', 100, 'read_only',
      'locked', 'Fixture pengujian lokal untuk pengulangan alur tanpa transaksi nyata.',
      10, 100, 70, 'free', null, statement_timestamp(), admin_user_id
    );
    inserted_count := inserted_count + 1;
  end if;

  return archived_count > 0 or inserted_count > 0;
end;
$$;

revoke all on function public.ensure_repeatable_local_program_fixtures()
  from public, anon;
grant execute on function public.ensure_repeatable_local_program_fixtures()
  to authenticated;

-- Seed/repair the currently running local stack using an existing Participant
-- identity. The claim is scoped to this psql session only.
select set_config(
  'request.jwt.claim.sub',
  (
    select profile.user_id::text
    from public.profiles profile
    where profile.role = 'participant'
    order by profile.created_at, profile.user_id
    limit 1
  ),
  false
);
select public.ensure_repeatable_local_program_fixtures();
select set_config('request.jwt.claim.sub', '', false);
