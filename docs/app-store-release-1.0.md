# TiltSip 1.0 App Store release

Submitted to App Review on 2026-08-07 (JST).

## App Store Connect

- App ID: `6798895099`
- Bundle ID: `com.naoki.tiltsip`
- Version ID: `05ebc249-f5d3-4976-bedf-7442859f2f2e`
- Build ID: `d4bf58ed-7848-4669-9d20-8b3bffc93b09`
- Review submission ID: `1cf51855-c12c-47cb-8d42-497dd1d24063`
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
- Build number: `4`
- Minimum iOS version: `18.0`
- Build service: Xcode Cloud build `4` (`a2fc50eb-ada9-4b0f-8c90-f3e0c1ce9454`)
- Xcode: `26.6 (17F113)`
- macOS: `Tahoe 26.6 (25G72)`
- Signing: Xcode Cloud managed App Store distribution, team `CW97U5J24N`
- Export compliance: `usesNonExemptEncryption = false`

The final archive was built and signed in Apple's stable Xcode Cloud
environment. App Store Connect processed it as `VALID`, with no non-exempt
encryption. Earlier local exports also passed strict code-signing verification;
their embedded profile had `get-task-allow = false` and no
`ProvisionedDevices` entry.

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

Builds 1 through 3 remained `VALID` and appeared verified in App Store Connect,
but their App Store versions changed to `INVALID_BINARY` shortly after review
submission. Build 3 also passed the full Transporter/SPI upload path with no
warnings or errors. Those submissions were canceled.

The local archives were produced by stable Xcode 26.2 on a macOS 27 beta host,
which was the remaining environmental difference. Build 4 was therefore
rebuilt from commit `7d02b67` using Xcode Cloud on stable Xcode 26.6 and stable
macOS 26.6. It was processed as `VALID`, attached to version 1.0, and submitted
through the App Store Connect UI only after the draft visibly showed `1.0 (4)`.
After more than two minutes of post-submission monitoring, the submission,
review item, version, and build all remained in their expected review-ready
states. The final submission is `WAITING_FOR_REVIEW` in both the App Review UI
and submission API.
