# TrackMeds – App Store Connect Setup Guide

This document consolidates setup guidance for submitting TrackMeds to the App Store.

---

## 1. Metadata (Product Page)

### Promotional Text (170 characters max)
*Shown above the description; can be updated without a new build.*

```
Track medications, symptoms, and exercise in one place. Treatment countdowns, daily logs, and export—your data stays on your device.
```
*(~115 chars)*

Alternative:
```
Stay on top of your treatment. Log meds, track side effects, and see exactly how many days remain. Free, private, and your data stays yours.
```
*(~128 chars)*

---

### Description (up to 4,000 characters)

```
TrackMeds helps you stay on top of your medications and health—without the clutter.

LOG MEDICATIONS
Add each medication with dosage, frequency, and schedule. Set start and end dates or use intervals for flexible treatment plans.

TREATMENT COUNTDOWN
See at a glance how many days remain in your treatment. Visual progress bars show where you are in each regimen.

DAILY RECORDS
Log doses, weight, exercise, and symptoms in seconds. Track side effects and how they relate to your medications.

HISTORY AT A GLANCE
Review your records by medications, exercise, or symptoms. Edit past entries anytime.

YOUR DATA, YOUR CONTROL
• All data stored locally on your device—nothing sent to the cloud
• Export to JSON or CSV—share with your doctor or keep a local backup
• Import from file—restore or migrate data easily
• No ads, no subscriptions—track what matters without distractions

Built for people managing long-term treatments who want a simple, private way to stay organized.
```

---

### Keywords (100 characters, comma-separated)
*Don't repeat words from the app name or subtitle.*

```
medication tracker,pill reminder,medicine log,health diary,symptom tracker,treatment countdown,medication log,dose tracker,prescription tracker,health records
```
*(~99 chars)*

---

### Support URL (required)
Use a real support page, e.g.:
- `https://github.com/YOUR_USERNAME/trackmeds/issues`
- `https://yourdomain.com/trackmeds/support`

---

### Marketing URL (optional)
Use if you have a landing page; otherwise leave blank.

---

### Version
`1.0`

---

### Copyright
`2026 Michael Leary` (or your legal entity)

---

## 2. Screenshots & Previews

### Required dimensions (iPhone 6.5" Display)

| Orientation | Dimensions |
|-------------|------------|
| Portrait    | **1242 × 2688** px |
| Portrait    | **1284 × 2778** px |
| Landscape   | **2688 × 1242** px |
| Landscape   | **2778 × 1284** px |

### Suggested screenshot order
1. Treatment Countdown – main screen with countdown cards
2. Add Record – form for logging a dose
3. History – list of records (medications/exercise/symptoms)
4. Medications – medication list with start/end dates
5. Export/Import – export options and data control

### Best practices
- Add short overlay text on each screenshot (e.g. "See days left at a glance")
- Use consistent styling
- Show realistic data (e.g. from test data)
- Use device frames or mockups for a polished look

### Resizing existing screenshots
If your image is 1170 × 2532 (6.1" size), resize to 1242 × 2688:

```bash
sips -z 2688 1242 /path/to/screenshot.png --out /path/to/screenshot_6.5.png
```

---

## 3. App Review Test Account

TrackMeds has no sign-in or cloud sync. No test account is required.

### For App Review
1. **App Review Information** → leave **Sign-in required** disabled
2. In **Notes**, add:

```
No sign-in required. Tap "Try with Test Data" on the welcome screen to load sample medications and records, or add your own data locally. All data stays on the device.
```

---

## 4. Pre-Submission Checklist

| Step | Action |
|------|--------|
| 1 | **App Information** → Age Rating → complete questionnaire |
| 2 | **App Information** → Primary Category → Health & Fitness or Medical |
| 3 | **App Information** → Content Rights → choose ownership |
| 4 | Upload build → select build in version |
| 5 | **App Privacy** → Admin completes privacy nutrition label |
| 6 | **App Privacy** → enter Privacy Policy URL |
| 7 | **Pricing and Availability** → set Free tier |

---

## 5. App Privacy & Data Collection

TrackMeds stores all data locally on the device. No data is sent to external servers.

### What to declare in App Privacy
| Data type | Why |
|-----------|-----|
| **Health** | Medication records, doses, symptoms, weight, exercise (stored locally only) |

### Data handling
- **Collection**: Health data is entered by the user and stored in Core Data on the device
- **Third-party sharing**: None—no analytics, no cloud sync, no sign-in
- **Export/Import**: User-initiated only; files stay on the device or are shared at the user's choice

---

## 6. Privacy Policy URL

You need a public URL to your privacy policy. For TrackMeds (device-only, no cloud), it should cover:
- What data the app stores (medication records, doses, symptoms, weight, exercise)
- Where it's stored (local device only, Core Data)
- That no data is sent to external servers
- Export/import (user-initiated; files stay on device or are shared at user's choice)
- User rights (access, export, delete via the app)
- Contact information

Host on GitHub Pages, a simple website, or a generator like [Termly](https://termly.io).

---

## 7. Release Strategy

- **Manually release** – control launch timing
- **Automatically release** – go live as soon as approved

---

## 8. Removing an App from App Store Connect

### Delete the app (never released)
1. **My Apps** → select app → **App Information**
2. Scroll to bottom → **Remove App**
3. Confirm

*Only works for apps that have never been released.*

### Remove from sale (already released)
1. **My Apps** → select app → **Pricing and Availability**
2. Turn off **Availability in All Territories**
3. Save

The app remains in App Store Connect but is no longer available for download.

### Transfer to another account
**App Information** → **Transfer App** (if available)
