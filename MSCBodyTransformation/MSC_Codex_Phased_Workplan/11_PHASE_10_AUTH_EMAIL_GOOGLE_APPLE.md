# Phase 10: Authentication and Session

> Status: menunggu project Supabase dan credential provider. Auth harus
> mempertahankan program yang dipilih serta QR Coach opaque selama login,
> bukan invite token atau kode program. Registrasi selalu menjadi Peserta.

## Tujuan

Mengganti fake session dengan Supabase Auth untuk real environments sambil mempertahankan local demo mode.

## Prasyarat

- Phase 09 selesai.
- Supabase Auth project tersedia.
- Google OAuth configuration tersedia.
- Apple developer capability tersedia untuk Sign in with Apple.
- Callback URL, bundle identifier, dan environment configuration sudah diputuskan.

## Auth methods

- Email registration.
- Email verification.
- Email and password login.
- Forgot password.
- Reset password callback.
- Google OAuth.
- Sign in with Apple.
- Logout.
- Session restoration.
- Account deletion request.

## Architecture

- [ ] `AuthRepository` protocol tetap domain-facing.
- [ ] Supabase auth adapter isolated.
- [ ] `SessionStore` observes auth changes.
- [ ] Root routing derives from session and onboarding state.
- [ ] Pending invite survives auth flow.
- [ ] Roles loaded from protected backend data.
- [ ] New registration defaults to participant.
- [ ] User cannot select coach/admin role.

## Email/password

- [ ] Register form.
- [ ] Password requirements.
- [ ] Email verification notice.
- [ ] Resend verification with rate-aware UI.
- [ ] Login.
- [ ] Forgot password.
- [ ] Deep-link reset callback.
- [ ] Error mapping.
- [ ] Session restoration.

## Google OAuth

- [ ] Configure provider in Supabase.
- [ ] Configure approved redirect URL.
- [ ] Use `ASWebAuthenticationSession` and PKCE through supported Supabase flow.
- [ ] Handle cancellation.
- [ ] Handle callback.
- [ ] Handle provider email collision.
- [ ] Do not authorize from Google profile data.
- [ ] Do not store Google client secret in app.
- [ ] Verify on physical device.

## Sign in with Apple

- [ ] Enable capability.
- [ ] Generate nonce correctly.
- [ ] Exchange identity token with Supabase.
- [ ] Store first-login name only where permitted.
- [ ] Handle hidden relay email.
- [ ] Handle revoked credential.
- [ ] Support account deletion workflow.
- [ ] Verify physical device flow.

## Account and identity linking

- [ ] Document expected automatic linking behavior.
- [ ] Handle same verified email safely.
- [ ] Avoid duplicate profile creation.
- [ ] Make profile creation idempotent.
- [ ] Test Google then email.
- [ ] Test email then Google.
- [ ] Test Apple relay email as separate identity unless explicitly linked.

## Tests

- [ ] Auth state machine unit tests with fake adapter.
- [ ] Email validation.
- [ ] Callback routing.
- [ ] Pending invite persistence.
- [ ] Session expired.
- [ ] Role load failure.
- [ ] UI tests with controlled auth test environment.
- [ ] Physical device Google and Apple validation.

## Exit criteria

- [ ] All supported login methods create a Supabase session.
- [ ] Session restores after relaunch.
- [ ] New user is participant.
- [ ] Role self-promotion impossible.
- [ ] Pending invite survives login.
- [ ] Local demo mode remains available.
- [ ] Account deletion flow is accessible.

## Progress log

### Log
