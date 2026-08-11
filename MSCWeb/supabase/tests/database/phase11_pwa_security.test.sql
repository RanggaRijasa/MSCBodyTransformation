begin;

create extension if not exists pgtap with schema extensions;
select extensions.plan(13);

insert into auth.users(
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('fb000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', 'p11-one@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('fb000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', 'p11-two@test.invalid', '', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now());

update public.profiles
set onboarding_status = 'active', finalized_at = now(), provisional_expires_at = null
where user_id in (
  'fb000000-0000-4000-8000-000000000001',
  'fb000000-0000-4000-8000-000000000002'
);

set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"fb000000-0000-4000-8000-000000000001","role":"authenticated"}';

select extensions.throws_like(
  $$ insert into public.web_push_subscriptions(user_id, endpoint, p256dh, auth_secret, user_agent_family)
     values ('fb000000-0000-4000-8000-000000000001', 'https://push.test/direct', repeat('a', 32), repeat('b', 8), 'other') $$,
  'permission denied%', 'direct subscription insert is denied'
);

select extensions.ok(
  public.register_my_web_push_subscription(
    'https://push.test/subscription-one', repeat('a', 32), repeat('b', 8), 'desktop_chromium'
  ) is not null,
  'owner registers a valid push subscription through the protected operation'
);
select extensions.is(
  (select count(*)::bigint from public.web_push_subscriptions),
  1::bigint,
  'owner can read only the registered row'
);
select extensions.is(
  public.register_my_web_push_subscription(
    'https://push.test/subscription-one', repeat('c', 32), repeat('d', 8), 'desktop_safari'
  ),
  (select id from public.web_push_subscriptions limit 1),
  'subscription registration is idempotent by endpoint'
);
select extensions.is(
  (select user_agent_family from public.web_push_subscriptions limit 1),
  'desktop_safari',
  're-registration refreshes non-secret client metadata'
);
select extensions.is(
  public.revoke_my_web_push_subscription('https://push.test/missing'),
  false,
  'revoke of an unknown endpoint is safely idempotent'
);

set local "request.jwt.claims" =
  '{"sub":"fb000000-0000-4000-8000-000000000002","role":"authenticated"}';
select extensions.is(
  (select count(*)::bigint from public.web_push_subscriptions),
  0::bigint,
  'another user cannot read the first owner subscription'
);
select extensions.is(
  public.revoke_my_web_push_subscription('https://push.test/subscription-one'),
  false,
  'another user cannot revoke the first owner subscription'
);
select extensions.throws_like(
  $$ select * from public.web_push_outbox $$,
  'permission denied%', 'authenticated users cannot read the delivery outbox'
);
select extensions.throws_like(
  $$ select public.consume_web_rate_limit('invalid_operation', 'opaque') $$,
  'rate_limit_operation_invalid', 'unknown rate-limit operations fail closed'
);
select extensions.is(
  public.consume_web_rate_limit('qr_validation', 'subject-a'),
  11,
  'first QR validation consumes one request from the minute bucket'
);
select extensions.lives_ok(
  $$ select public.consume_web_rate_limit('qr_validation', 'subject-b') from generate_series(1, 12) $$,
  'QR validation allows the configured request count'
);
select extensions.throws_like(
  $$ select public.consume_web_rate_limit('qr_validation', 'subject-b') $$,
  'rate_limit_exceeded', 'QR validation rejects requests above the configured limit'
);

select * from extensions.finish();
rollback;
