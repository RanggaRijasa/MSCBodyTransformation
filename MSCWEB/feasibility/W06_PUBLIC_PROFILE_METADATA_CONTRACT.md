# W06 public Coach profile metadata contract

W06 owns the canonical public route `/c/:handle` and its allowlisted read model. W08 may add Cloudflare-rendered social metadata, but must not query private Coach draft tables or infer hidden contact fields.

## Canonical fields

- `handle`: stable public handle, unrelated to Auth ID and Coach QR.
- `display_name`: server-derived account name.
- `is_verified`: server-derived and always `true` for a published active Coach.
- `photo_kind`: `provider` or `storage`.
- `photo_reference`: provider HTTPS URL or object path in `coach-public-media`.
- optional `professional_headline`, `biography`, and `service_area`.
- optional contact fields only when their independent public toggle was enabled.
- `items`: approved, public testimonial/before–after items only.

## W08 metadata mapping

- canonical URL: `/c/:handle`.
- title: `<display_name> · Coach MSC Body Transformation`.
- description: `professional_headline`, then a safely truncated `biography`, then a generic Indonesian fallback.
- image: normalized public profile photo; never evidence media or a private signed URL.
- unknown, unpublished, expired, or revoked Coach: safe not-found metadata with no stale identity.

Dynamic Open Graph HTML is not implemented or claimed by W06. W08 must preserve the same active-entitlement check and the same allowlist used by `get_public_coach_profile`.
