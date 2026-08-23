begin;

create extension if not exists pgtap with schema extensions;
select extensions.plan(5);

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values (
  'f8000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated',
  'w08-paid-publish-admin@test.invalid', '', now(),
  '{"provider":"email","providers":["email"]}', '{}', now(), now()
);
update public.profiles
set role = 'admin', display_name = 'Admin Publish W08', onboarding_status = 'active',
  provisional_expires_at = null, finalized_at = now()
where user_id = 'f8000000-0000-0000-0000-000000000001';

insert into public.programs(
  id, title, summary, status, pace, duration_mode, starts_on, ends_on,
  timezone, past_step_policy, future_step_policy, wellness_disclaimer,
  points_per_activity, points_per_weight_kg, quiz_passing_percentage,
  pricing_mode, desired_price, created_by
) values (
  'f8000000-0000-0000-0000-000000000010', 'Program Berbayar W08',
  'Fixture publish manual payment yang selalu di-rollback.', 'draft',
  'scheduled', 'specific_dates', current_date + 1, current_date + 1,
  'Asia/Makassar', 'available', 'locked', 'Program wellness non-diagnostik.',
  10, 0, 70, 'paid', 100000, 'f8000000-0000-0000-0000-000000000001'
);
insert into public.program_days(id, program_id, day_number, title, scheduled_on)
values (
  'f8000000-0000-0000-0000-000000000011',
  'f8000000-0000-0000-0000-000000000010', 1, 'Hari pertama', current_date + 1
);
insert into public.program_steps(
  id, program_day_id, step_order, title, content_kind,
  completion_policy, verification_mode
) values (
  'f8000000-0000-0000-0000-000000000012',
  'f8000000-0000-0000-0000-000000000011', 1, 'Baca panduan',
  'article', 'mark_complete', 'automatic'
);

update public.payment_destinations set status = 'retired';

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"f8000000-0000-0000-0000-000000000001","role":"authenticated"}';
select extensions.throws_like(
  $$ select public.publish_program(
    'f8000000-0000-0000-0000-000000000010', 'w08-paid-publish-blocked'
  ) $$,
  'program_paid_not_ready',
  'paid program stays draft without a current payment destination'
);
select extensions.is(
  (select status from public.programs
   where id = 'f8000000-0000-0000-0000-000000000010'),
  'draft',
  'failed paid publication leaves the program draft'
);

reset role;
insert into public.payment_destinations(
  id, version, bank_code, bank_name, account_name, account_reference,
  effective_from, status, created_by, instructions
) values (
  'f8000000-0000-0000-0000-000000000020', 800, 'TST', 'Bank Uji',
  'FIXTURE W08', '0000000000', statement_timestamp() - interval '1 minute',
  'active', 'f8000000-0000-0000-0000-000000000001',
  'Jangan melakukan pembayaran nyata.'
);

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"f8000000-0000-0000-0000-000000000001","role":"authenticated"}';
select extensions.lives_ok(
  $$ select public.publish_program(
    'f8000000-0000-0000-0000-000000000010', 'w08-paid-publish-ready'
  ) $$,
  'paid program publishes after its payment destination is ready'
);
select extensions.is(
  (select status from public.programs
   where id = 'f8000000-0000-0000-0000-000000000010'),
  'scheduled',
  'future paid program becomes scheduled'
);
select extensions.is(
  (select count(*)::bigint from public.audit_events
   where subject_id = 'f8000000-0000-0000-0000-000000000010'
     and kind = 'program_published'),
  1::bigint,
  'paid publication writes one audit event'
);

select * from extensions.finish();
rollback;
