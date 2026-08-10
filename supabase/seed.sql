-- Auth identities and private media must be created by deterministic
-- integration-test setup, never copied from production. These StoreKit
-- products are local-only fixtures: `supabase db push` never runs seed.sql.
insert into public.coach_store_products(
  price_band, platform, environment, product_id, product_type,
  provisioning_status, actual_price, currency_code
)
values
  ('entry', 'app_store', 'xcode',
   'local.msc.coach.access.entry.3months',
   'non_renewing_subscription', 'ready', 100000, 'IDR'),
  ('growth', 'app_store', 'xcode',
   'local.msc.coach.access.growth.3months',
   'non_renewing_subscription', 'ready', 150000, 'IDR'),
  ('leadership', 'app_store', 'xcode',
   'local.msc.coach.access.leadership.3months',
   'non_renewing_subscription', 'ready', 200000, 'IDR')
on conflict (platform, environment, product_id) do update set
  product_type = excluded.product_type,
  provisioning_status = excluded.provisioning_status,
  actual_price = excluded.actual_price,
  currency_code = excluded.currency_code,
  updated_at = statement_timestamp();
