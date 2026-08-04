# Shared mobile contract

`program-api-v1.openapi.yaml` is the platform-neutral source for iOS backend
adapters and the future Kotlin/Jetpack Compose implementation.

Contract rules:

- UUIDs are opaque and never derived by a client in production.
- Dates use the program timezone; timestamps use RFC 3339 UTC.
- Decimal values are transported as strings.
- Participant program payloads never include quiz answer keys.
- Coach/Admin review payloads may include answer keys after authorization.
- Every mutation uses an idempotency key.
- Quiz reopen and weigh-in correction require an Admin reason and audit.
- Winner posters always reference both program and immutable snapshot.
- Enrollment, payment verification, scoring, and winner locking are
  server-authoritative.
- A purchase on either store grants the same `(participant, program)`
  entitlement and never grants a duplicated cohort automatically.

The YAML is syntax-validated locally. Contract-to-client generation and live
endpoint conformance remain CI/staging gates.
