# TiltSip 1.0 App Store release

Submitted to App Review on 2026-08-07 (JST).

## App Store Connect

- App ID: `6798895099`
- Bundle ID: `com.naoki.tiltsip`
- Version ID: `05ebc249-f5d3-4976-bedf-7442859f2f2e`
- Build ID: `af730b30-94ea-4e45-b19d-a4db27633466`
- Review submission ID: `dc6c945b-da23-410f-9a22-1e040de55ca9`
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
- Build number: `1`
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

The high-level submission command initially observed the newly-created review
item before its version relationship had propagated. After verifying that the
submission contained version 1.0 and its item was `READY_FOR_REVIEW`, the same
submission was finalized through the lower-level submission endpoint.
