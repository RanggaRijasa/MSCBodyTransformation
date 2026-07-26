# Phase 05: Admin CMS UI

## Tujuan

Membangun CMS native di dalam aplikasi menggunakan local draft repository. Admin dapat membuat, mengedit, mem-preview, dan mensimulasikan publish program tanpa backend.

## External dependency status

**Lokal sepenuhnya.**

Media menggunakan local references. Publish hanya mengubah status mock.

## Admin tabs

1. Overview
2. Programs
3. People
4. Content
5. Settings

## Overview

- [ ] Program counts by status.
- [ ] Active participant count.
- [ ] Pending coach approvals.
- [ ] Pending reviews.
- [ ] Scoring status.
- [ ] Recent local audit events.
- [ ] Quick actions.

## Program list

- [ ] Draft, scheduled, active, completed, archived sections.
- [ ] Search.
- [ ] Status filter.
- [ ] Duplicate draft action.
- [ ] Archive local action.
- [ ] Empty states.
- [ ] Error and loading simulations.

## Staged program editor

Gunakan staged flow:

1. Basics
2. Dates and timezone
3. Scoring and visibility
4. Days
5. Steps and media
6. Participant preview
7. Publish validation

### Basics

- [ ] Name.
- [ ] Description.
- [ ] Cover image local reference.
- [ ] Verification mode.
- [ ] Wellness disclaimer reference.

### Dates and timezone

- [ ] Start date.
- [ ] End date.
- [ ] IANA timezone selection.
- [ ] Initial weigh-in window.
- [ ] Final weigh-in window.
- [ ] Date validation.
- [ ] Duration derived safely.

### Scoring and visibility

- [ ] Weight points per kg.
- [ ] Past step policy.
- [ ] Future step policy.
- [ ] Automatic or coach review.
- [ ] Human-readable scoring preview.
- [ ] Warning that server becomes authoritative later.

### Days

- [ ] Generate days from date range.
- [ ] Day list.
- [ ] Add, remove, and reorder when allowed.
- [ ] Day title and description.
- [ ] Scheduled date.
- [ ] Duplicate day.
- [ ] Validation for unique day number and date.

### Steps

- [ ] Ordered steps.
- [ ] Add step.
- [ ] Edit step.
- [ ] Delete draft step.
- [ ] Reorder.
- [ ] Title.
- [ ] Description.
- [ ] Points.
- [ ] Requires photo.
- [ ] Requires text answer.
- [ ] Required or optional.
- [ ] Image/video local media.
- [ ] Participant-facing preview.
- [ ] Validation for non-negative points.

### Preview

- [ ] Preview participant Today.
- [ ] Preview timeline.
- [ ] Preview step detail.
- [ ] Preview locked states.
- [ ] Preview leaderboard scoring description.
- [ ] Preview on small and large device sizes.

### Local publish simulation

- [ ] Validate at least one day.
- [ ] Validate every day has an active step.
- [ ] Validate dates.
- [ ] Validate scoring.
- [ ] Validate step ordering.
- [ ] Validate required media reference when configured.
- [ ] Show validation summary.
- [ ] Publish changes mock status only.
- [ ] Append local audit event.

## People

- [ ] User list.
- [ ] Role badges.
- [ ] Pending coach approval.
- [ ] Approve coach local action.
- [ ] Public coach profile toggle.
- [ ] Participant detail summary.
- [ ] Manual enrollment UI.
- [ ] Manual enrollment reason required.
- [ ] Local audit record.
- [ ] Score adjustment UI with required reason.
- [ ] No self-service role promotion outside admin demo.

## Content

- [ ] Managed content list.
- [ ] Winner banner editor.
- [ ] Title and body.
- [ ] Local media selection.
- [ ] Program association.
- [ ] Visibility dates.
- [ ] Sort order.
- [ ] Active toggle.
- [ ] Participant preview.
- [ ] Archive local content.

## Winner management

- [ ] Leaderboard preview.
- [ ] Lock top five local simulation.
- [ ] Confirmation.
- [ ] Winner records display.
- [ ] Locked state prevents silent reorder.
- [ ] New score adjustment after lock shows warning.
- [ ] Upload local winner banner.

## Draft persistence

Gunakan salah satu pendekatan native lokal:

- JSON file in application support untuk Debug demo, atau
- In-memory repository dengan fixture reset.

Jangan menambahkan SwiftData hanya untuk sementara bila persistence tidak dibutuhkan. Bila dipilih, dokumentasikan alasan dan migration implications.

## Tests

### Swift Testing

- [ ] Program editor validation.
- [ ] Day generation.
- [ ] Date range validation.
- [ ] Step order validation.
- [ ] Publish validation.
- [ ] Manual enrollment reason.
- [ ] Score adjustment reason.
- [ ] Winner lock determinism.
- [ ] Managed content visibility.

### UI tests

- [ ] Launch as admin.
- [ ] Create draft.
- [ ] Add day and step.
- [ ] Preview participant screen.
- [ ] Simulate publish.
- [ ] Approve coach.
- [ ] Manual enroll participant.
- [ ] Create winner banner.

## Larangan scope

Jangan:

- Membuat SQL.
- Menyimpan live data.
- Menganggap client CMS validation cukup untuk production publish.
- Membolehkan scoring change silent setelah publish.
- Mengunggah media ke server.
- Membuat web admin panel.

## Exit criteria

- [ ] Admin dapat membuat valid sample program tanpa perubahan kode.
- [ ] Invalid draft tidak dapat dipublish dalam local simulation.
- [ ] Participant preview mencerminkan draft.
- [ ] People dan Content screens dapat didemokan.
- [ ] Semua privileged local action membuat local audit entry.
- [ ] Test lulus dan clean build.

## Progress log

### Log
