begin;

create extension if not exists pgtap with schema extensions;

select extensions.plan(25);

select extensions.ok(
  has_function_privilege(
    'authenticated',
    'public.save_my_coach_application_draft(text,boolean,boolean,text,text)',
    'execute'
  ),
  'authenticated applicants can save their own draft through RPC'
);
select extensions.ok(
  not has_function_privilege(
    'anon',
    'public.decide_coach_application(uuid,text,text,text)',
    'execute'
  ),
  'anon cannot reach Coach decisions'
);
select extensions.ok(
  not has_table_privilege(
    'authenticated', 'public.coach_payment_records', 'insert'
  ),
  'clients cannot mark Coach payment verified'
);
select extensions.ok(
  not has_table_privilege(
    'authenticated', 'public.coach_access_entitlements', 'insert'
  ),
  'clients cannot issue Coach entitlements'
);
select extensions.ok(
  not has_table_privilege(
    'authenticated', 'public.coach_applications', 'update'
  ),
  'clients cannot directly alter Coach decisions'
);

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  ('e1000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated',
   'phase11-coach-admin@test.invalid', '', now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('e1000000-0000-0000-0000-000000000011', 'authenticated', 'authenticated',
   'phase11-coach-applicant@test.invalid', '', now(),
   '{"provider":"email","providers":["email"]}',
   '{"role":"admin"}', now(), now()),
  ('e1000000-0000-0000-0000-000000000012', 'authenticated', 'authenticated',
   'phase11-coach-rejected@test.invalid', '', now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now());

update public.profiles
set role = 'admin', display_name = 'Admin Coach Phase 11',
    onboarding_status = 'active', provisional_expires_at = null,
    finalized_at = now()
where user_id = 'e1000000-0000-0000-0000-000000000001';

update public.profiles
set display_name = case user_id
      when 'e1000000-0000-0000-0000-000000000011' then 'Calon Coach Lulus'
      else 'Calon Coach Ditolak' end,
    phone_number = '+6281234567890', member_level = 'sc',
    onboarding_status = 'active', provisional_expires_at = null,
    finalized_at = now()
where user_id in (
  'e1000000-0000-0000-0000-000000000011',
  'e1000000-0000-0000-0000-000000000012'
);

select extensions.is(
  (select role from public.profiles
   where user_id = 'e1000000-0000-0000-0000-000000000011'),
  'participant',
  'user metadata cannot self-promote an applicant'
);

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"e1000000-0000-0000-0000-000000000011","role":"authenticated"}';

select extensions.lives_ok(
  $$ select public.save_my_coach_application_draft(
    'sc', true, true, 'terms-2026-08', 'coach-draft-lulus-001'
  ) $$,
  'eligible applicant can create a draft'
);
select extensions.is(
  (select count(*)::bigint from public.coach_applications),
  1::bigint,
  'applicant sees exactly their own application'
);
select extensions.is(
  (select member_level_snapshot from public.coach_applications limit 1),
  'sc',
  'member-level eligibility is stored as a snapshot'
);
select extensions.lives_ok(
  $$ select public.submit_my_coach_application(
    (select id from public.coach_applications limit 1),
    'coach-submit-lulus-001'
  ) $$,
  'complete application can be submitted'
);
select extensions.is(
  (select status from public.coach_applications limit 1),
  'submitted',
  'submitted application waits for Admin review before payment'
);
select extensions.throws_like(
  $$ select public.decide_coach_application(
    (select id from public.coach_applications limit 1),
    'approved', null, 'coach-self-approve-001'
  ) $$,
  'permission_denied',
  'applicant cannot approve their own application'
);

reset role;

select extensions.is(
  (select count(*)::bigint from public.coach_payment_records),
  0::bigint,
  'submission and review do not charge the applicant'
);

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"e1000000-0000-0000-0000-000000000001","role":"authenticated"}';

select extensions.lives_ok(
  $$ select public.decide_coach_application(
    (select id from public.coach_applications
     where applicant_user_id = 'e1000000-0000-0000-0000-000000000011'),
    'approved', null, 'coach-admin-approve-001'
  ) $$,
  'Admin can accept an eligible submitted application before payment'
);
select extensions.is(
  (select status from public.coach_applications
   where applicant_user_id = 'e1000000-0000-0000-0000-000000000011'),
  'accepted_pending_payment',
  'accepted application waits for a verified purchase'
);
select extensions.is(
  (select role
   from public.profiles
   where user_id = 'e1000000-0000-0000-0000-000000000011'),
  'participant',
  'Admin acceptance alone cannot activate the Coach role'
);
select extensions.is(
  (select count(*)::bigint from public.audit_events
   where kind = 'coach_application_accepted'),
  1::bigint,
  'acceptance writes one audit event'
);
select extensions.lives_ok(
  $$ select public.decide_coach_application(
    (select id from public.coach_applications
     where applicant_user_id = 'e1000000-0000-0000-0000-000000000011'),
    'approved', null, 'coach-admin-approve-001'
  ) $$,
  'repeated approval with the same idempotency key is stable'
);
select extensions.is(
  (select count(*)::bigint from public.audit_events
   where kind = 'coach_application_accepted'),
  1::bigint,
  'idempotent acceptance does not duplicate audit'
);
select extensions.throws_like(
  $$ select public.decide_coach_application(
    (select id from public.coach_applications
     where applicant_user_id = 'e1000000-0000-0000-0000-000000000011'),
    'rejected', 'Berlawanan', 'coach-admin-reject-race'
  ) $$,
  'application_already_decided',
  'approve-versus-reject conflict has one terminal result'
);

set local "request.jwt.claims" =
  '{"sub":"e1000000-0000-0000-0000-000000000012","role":"authenticated"}';
select extensions.lives_ok(
  $$ select public.save_my_coach_application_draft(
    'sc', true, true, 'terms-2026-08', 'coach-draft-tolak-001'
  ) $$,
  'second applicant can create an independent application'
);
select extensions.lives_ok(
  $$ select public.submit_my_coach_application(
    (select id from public.coach_applications
     where applicant_user_id = 'e1000000-0000-0000-0000-000000000012'),
    'coach-submit-tolak-001'
  ) $$,
  'second application can be submitted'
);

set local "request.jwt.claims" =
  '{"sub":"e1000000-0000-0000-0000-000000000001","role":"authenticated"}';
select extensions.throws_like(
  $$ select public.decide_coach_application(
    (select id from public.coach_applications
     where applicant_user_id = 'e1000000-0000-0000-0000-000000000012'),
    'rejected', '', 'coach-admin-reject-empty'
  ) $$,
  'reason_required',
  'Coach application rejection requires a reason'
);
select extensions.lives_ok(
  $$ select public.decide_coach_application(
    (select id from public.coach_applications
     where applicant_user_id = 'e1000000-0000-0000-0000-000000000012'),
    'rejected', 'Dokumen belum sesuai.', 'coach-admin-reject-001'
  ) $$,
  'Admin rejection succeeds with a reason'
);
select extensions.is(
  (select role from public.profiles
   where user_id = 'e1000000-0000-0000-0000-000000000012'),
  'participant',
  'rejected applicant remains Participant'
);

reset role;
select * from extensions.finish();
rollback;
