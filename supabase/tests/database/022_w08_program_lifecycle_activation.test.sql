begin;

create extension if not exists pgtap with schema extensions;
select extensions.plan(6);

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values (
  'fa000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated',
  'w08-program-lifecycle@test.invalid', '', now(),
  '{"provider":"email","providers":["email"]}', '{}', now(), now()
);

-- Isolate the lifecycle result from scheduled programs loaded by seed.sql.
-- The transaction rolls this change back after the assertions finish.
update public.programs
set status = 'draft',
    published_at = null
where status = 'scheduled';

insert into public.programs(
  id, title, summary, status, pace, duration_mode, starts_on, ends_on,
  timezone, past_step_policy, future_step_policy, wellness_disclaimer,
  points_per_activity, points_per_weight_kg, quiz_passing_percentage,
  pricing_mode, desired_price, published_at, created_by
) values
  (
    'fa000000-0000-0000-0000-000000000010', 'Program jatuh tempo W08',
    'Fixture lifecycle yang selalu di-rollback.', 'scheduled',
    'scheduled', 'specific_dates',
    timezone('Asia/Jakarta', statement_timestamp())::date - 1,
    timezone('Asia/Jakarta', statement_timestamp())::date + 1,
    'Asia/Jakarta', 'available', 'locked', 'Program wellness non-diagnostik.',
    10, 0, 70, 'free', null, now(),
    'fa000000-0000-0000-0000-000000000001'
  ),
  (
    'fa000000-0000-0000-0000-000000000011', 'Program mendatang W08',
    'Fixture lifecycle yang selalu di-rollback.', 'scheduled',
    'scheduled', 'specific_dates',
    timezone('Asia/Jakarta', statement_timestamp())::date + 1,
    timezone('Asia/Jakarta', statement_timestamp())::date + 2,
    'Asia/Jakarta', 'available', 'locked', 'Program wellness non-diagnostik.',
    10, 0, 70, 'free', null, now(),
    'fa000000-0000-0000-0000-000000000001'
  );

select extensions.is(
  private.activate_due_programs(),
  1,
  'activates exactly one published scheduled program whose local start date arrived'
);
select extensions.is(
  (select status from public.programs where id = 'fa000000-0000-0000-0000-000000000010'),
  'active',
  'due program becomes active'
);
select extensions.is(
  (select status from public.programs where id = 'fa000000-0000-0000-0000-000000000011'),
  'scheduled',
  'future program stays scheduled'
);
select extensions.is(
  (select count(*)::integer from public.audit_events
   where subject_id = 'fa000000-0000-0000-0000-000000000010'
     and kind = 'program_activated'),
  1,
  'activation writes one audit event'
);
select extensions.is(
  private.activate_due_programs(),
  0,
  'repeated activation is idempotent'
);
select extensions.is(
  (select count(*)::integer from public.audit_events
   where subject_id = 'fa000000-0000-0000-0000-000000000010'
     and kind = 'program_activated'),
  1,
  'idempotent rerun does not duplicate audit events'
);

select * from extensions.finish();
rollback;
