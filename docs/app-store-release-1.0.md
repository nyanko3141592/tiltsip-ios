# TiltSip 1.0 App Store release

Submitted to App Review on 2026-08-07 (JST).

## App Store Connect

- App ID: `6798895099`
- Bundle ID: `com.naoki.tiltsip`
- Version ID: `05ebc249-f5d3-4976-bedf-7442859f2f2e`
- Build ID: `efb0b025-1a54-436a-88d4-e71cebdedfaa`
- Review submission ID: `aec37e5d-9dbc-49e0-9cb3-2ceaa87362df`
- Submitted state: `WAITING_FOR_REVIEW`
- Release: automatic after approval

## Distribution

- Up-front price: JPY 100, with Japan as the base storefront
- Availability: all 175 App Store countries and regions, including future territories
- iPhone only; Apple silicon Mac distribution disabled
- Primary category: Entertainment
- Secondary category: Food & Drink
- Age-rating disclosure: infrequent or mild alcohol, tobacco, or drug references
- App Privacy: published as no data collected
- Content rights: no third-party content

## Build

- Marketing version: `1.0`
- Build number: `2`
- Minimum iOS version: `18.0`
- Xcode: `26.2`
- Distribution profile: `TiltSip App Store 2026`
- Distribution profile UUID: `f9a24b1d-d462-4fd8-9160-e4d8b3bfc904`
- Signing identity: Apple Distribution, team `CW97U5J24N`
- Export compliance: `usesNonExemptEncryption = false`

The archive and exported IPA passed strict code-signing verification. The
embedded profile has `get-task-allow = false` and no `ProvisionedDevices`
entry. The exported app contains its asset catalog and privacy manifest.

## Store assets

- Japanese and English (U.S.) metadata validated and uploaded
- Three 6.7-inch iPhone screenshots uploaded for each locale
- Privacy policy and support pages published through GitHub Pages
- App Review contact information and review notes configured; no demo account
  is required

## Validation and submission

- `asc metadata validate`: 0 errors, 0 warnings
- Screenshot validation: 0 issues
- `asc validate --strict`: 0 errors, 0 warnings, 0 blockers
- `asc review doctor` before submission: 0 submission blockers
- Final App Store status: `WAITING_FOR_REVIEW`

The first API-created submission (`dc6c945b-da23-410f-9a22-1e040de55ca9`)
observed its review item before the version relationship had fully propagated.
It was immediately returned as an unresolved/invalid-binary submission even
though build 1 remained `VALID` and App Store Connect showed the binary as
verified. That submission was canceled. Build 2 was freshly archived, signed,
exported, uploaded, and validated, then submitted through the App Store Connect
UI only after the draft visibly showed `1.0 (2)` as ready. The replacement
submission is `WAITING_FOR_REVIEW` in both the App Review UI and submission API.
