import { createServerClient } from "@supabase/ssr";
import type { SupabaseClient, User } from "@supabase/supabase-js";
import { expect, type BrowserContext, type Page } from "@playwright/test";

export function createBrowserFixtureIds() {
  return {
    application: crypto.randomUUID(),
    applicantApplication: crypto.randomUUID(),
    destination: crypto.randomUUID(),
    entitlement: crypto.randomUUID(),
    payment: crypto.randomUUID(),
    program: crypto.randomUUID(),
  };
}

export async function must<T extends { error: { message: string } | null }>(
  operation: PromiseLike<T>,
  label: string,
) {
  const result = await operation;
  if (result.error) throw new Error(`${label}: ${result.error.message}`);
  return result;
}

export async function createIdentity(
  adminClient: SupabaseClient,
  createdUsers: User[],
  password: string,
  label: string,
) {
  const email = `phase06-browser-${label}-${crypto.randomUUID()}@local.invalid`;
  const result = await adminClient.auth.admin.createUser({
    email,
    email_confirm: true,
    password,
  });
  if (result.error || !result.data.user) throw result.error ?? new Error("Identity gagal.");
  createdUsers.push(result.data.user);
  return result.data.user;
}

export async function addSupabaseSession(
  context: BrowserContext,
  input: Readonly<{
    baseUrl: string;
    email: string;
    password: string;
    publishableKey: string;
    supabaseUrl: string;
  }>,
) {
  const jar = new Map<string, string>();
  const auth = createServerClient(input.supabaseUrl, input.publishableKey, {
    cookies: {
      getAll: () => [...jar].map(([name, value]) => ({ name, value })),
      setAll: (values) => values.forEach(({ name, value }) => jar.set(name, value)),
    },
  });
  const signIn = await auth.auth.signInWithPassword({
    email: input.email,
    password: input.password,
  });
  if (signIn.error) throw signIn.error;
  await context.addCookies([...jar].map(([name, value]) => ({ name, value, url: input.baseUrl })));
}

export function paymentCleanupSql(
  ids: Readonly<{ applicantApplication: string; destination: string; program: string }>,
) {
  const orderScope = `program_id = '${ids.program}' or coach_application_id = '${ids.applicantApplication}'`;
  return `begin;
    alter table public.payment_events disable trigger payment_events_no_update_or_delete;
    alter table public.payment_ledger disable trigger payment_ledger_no_update_or_delete;
    delete from public.payment_events where order_id in (select id from public.payment_orders where ${orderScope});
    delete from public.payment_ledger where order_id in (select id from public.payment_orders where ${orderScope});
    delete from public.payment_evidence_attempts where order_id in (select id from public.payment_orders where ${orderScope});
    delete from public.payment_orders where ${orderScope};
    delete from public.program_scores where enrollment_id in (select id from public.program_enrollments where program_id = '${ids.program}');
    delete from public.program_enrollments where program_id = '${ids.program}';
    delete from public.programs where id = '${ids.program}';
    delete from public.payment_destinations where id = '${ids.destination}';
    alter table public.payment_events enable trigger payment_events_no_update_or_delete;
    alter table public.payment_ledger enable trigger payment_ledger_no_update_or_delete;
    commit;`;
}

function currentJakartaCalendarDate() {
  const parts = new Intl.DateTimeFormat("en-US", {
    day: "2-digit",
    month: "2-digit",
    timeZone: "Asia/Jakarta",
    year: "numeric",
  })
    .formatToParts(new Date())
    .reduce<Record<string, string>>((result, part) => {
      result[part.type] = part.value;
      return result;
    }, {});
  return `${parts.year}-${parts.month}-${parts.day}`;
}

export async function assertCoachQueueFilters(page: Page) {
  const calendarDate = currentJakartaCalendarDate();
  await page.goto(
    `/admin/pembayaran?jenis=coach_access&status=under_review&dari=${calendarDate}&sampai=${calendarDate}`,
  );
  await expect(page.getByLabel("Jenis pembayaran")).toHaveValue("coach_access");
  await expect(page.getByLabel("Status")).toHaveValue("under_review");
  await expect(page.getByLabel("Dari tanggal")).toHaveValue(calendarDate);
  await expect(page.getByLabel("Sampai tanggal")).toHaveValue(calendarDate);
  await expect(
    page.getByLabel("Antrean pembayaran").getByRole("heading", {
      name: "Calon Coach Payment Browser",
    }),
  ).toBeVisible();
}
