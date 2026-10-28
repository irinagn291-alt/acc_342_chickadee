<!-- gf-brief source=459f93cc85cafbea3f37aca5f5187a0d9b1e1989a002bbe6539fc387edbc7270 written=2026-10-28T22:39:28+03:00 -->
# Chickadee

## What it is

Chickadee is a private evening ritual for writing down the day and winding down before bed. It guides people through three chambers—Reflect, Breathe, and Ambient—and lets them keep a record of sealed nights on their device.

## Launch and onboarding

On a cold launch, a brief loading state appears, then the app opens to onboarding if it has not been completed before. Onboarding has three pages, with a page indicator and these exact messages:

1. “End the day on one scroll. Three chambers, in order.”
2. “Commit one release line, or skip the chamber.”
3. “Roll the night shut. It stays on this device.”

The buttons “Skip” and “Continue” appear on every page. “Continue” advances through the pages and finishes on the last one; “Skip” finishes onboarding immediately. After onboarding, the app opens “Tonight.” On later launches, it opens “Tonight” directly.

## Screens

### Tonight

The main screen is titled “Tonight.” It shows the date, current chamber and state (“Bare,” “Marked,” or “Rolled”), and a streak count. “Nights” and “Best” show progress totals. When there is a sealed night, a “Last seal” card shows its date and a saved line; tapping it opens “History.”

The top-right “History” button opens the saved-night list. “Settings” opens preferences. The ritual is presented as three chambers:

- **Reflect:** Enter a line in the “Release line” field, then tap “Commit line” to save it, or “Skip” to leave it blank and move on.
- **Breathe:** The prompt is “Write one release line for tonight.” Enter text in “Release line,” then tap “Commit line.” “Start breath” starts a timed breathing count; after the count, “Commit line” is available. “Skip this chamber” leaves the chamber blank and moves on.
- **Ambient:** Enter a line in “Release line” and tap “Commit line,” or tap “Skip” to leave the chamber blank.

After marking or skipping a chamber, tap “Advance” to move to the next one. Once all three are marked or skipped, “Seal night” saves the night and closes the ritual. The Breathe count shows cues such as “Settle,” “Draw,” “Release,” and “Rest,” with “Stay with the count.” while time remains and “Count finished.” when it ends. A swipe upward can also advance the ritual.

When the night is untouched, the screen shows “Tonight is open.” and “Write the first line.” A failed load shows “Load failed. Try again.” with “Retry.”

### History

The “History” screen lists sealed nights newest first. Each card shows its date and the “Reflect,” “Breathe,” and “Ambient” lines; skipped chambers are shown as “Skipped.” Tapping a night opens its read-only “Night” screen.

When there are no saved nights, the screen says “Build tonight's rite. Skip a block if you must.” and shows “Begin,” which returns to “Tonight.” A failed load shows “History failed,” “Load failed. Try again.” and “Retry.”

### Night

The “Night” screen shows a saved night’s date and its “Reflect,” “Breathe,” and “Ambient” lines. Empty chambers display “Skipped.” It is read-only.

### Reflect

The “Reflect” screen shows the Reflect line and its state, plus a “Next” panel naming the currently open chamber. It instructs, “Return to tonight and commit the open chamber.” It is read-only.

### Breathe

The “Breathe” screen shows a countdown, the current breathing cue, and either “Stay with the count.” or “Count finished.” “Skip this chamber” skips the chamber and returns to the ritual. This screen is a timed step in the ritual.

### Sealed

The “Sealed” screen shows the latest saved night, its date, and all three lines, with skipped chambers labeled “Skipped.” If no sealed night is available, it shows “No sealed night yet.” This screen is read-only.

### Settings

The “Settings” screen has “Reflect,” “Breathe,” and “Ambient” duration fields labeled “Seconds,” a “Haptics” toggle, and “Contact.” “Show rite” returns to the ritual. “Erase local data” opens a confirmation dialog: “Reset local data. Tonight's scroll and every sealed night on this device will be erased.” The dialog buttons are “Erase local data” and “Cancel.” Erasing returns the app to onboarding.

Before any ritual data exists, Settings instead shows “Pace is ready.” and “Defaults are 90, 120, and 90 seconds.” It offers “Begin” and “Contact.” A failed load shows “Load failed. Try again.”, the error message, “Retry,” and “Contact.”

## Features

- A nightly ritual with “Reflect,” “Breathe,” and “Ambient” chambers.
- A personal release line in each chamber, or the option to skip.
- A timed breathing count with “Settle,” “Draw,” “Release,” and “Rest” cues.
- “Advance” and “Seal night” controls to complete and save a ritual.
- A streak count, “Nights” total, and “Best” total.
- A newest-first “History” of sealed nights, with read-only night details.
- Adjustable chamber durations and a “Haptics” setting.
- A “Contact” link in Settings.
- An “Erase local data” control for clearing the ritual and saved nights.

## Behaviours that can look like bugs

- “Commit line” is disabled until a chamber is open and the app is not saving. Enter text in “Release line” to save a line; an empty line can be committed as a skip.
- “Start breath” is disabled while the breathing chamber is closed. “Skip this chamber” and “Skip” are disabled when the current chamber cannot be changed.
- “Advance” is disabled until the current chamber is marked or skipped. Move through the chambers in order.
- “Seal night” only appears once all three chambers are marked or skipped.
- A brand-new “Tonight” screen shows “Tonight is open.” and “Write the first line.” Start with the Reflect chamber.
- “History” is empty until a night has been sealed. Complete the ritual and tap “Seal night” for it to appear.
- Invalid duration input shows “Enter a number above zero.” Enter a positive number to set the duration.
- “Erase local data” requires confirmation. Choose “Erase local data” in the dialog to clear saved ritual data, or “Cancel” to keep it.
- Skipped chambers appear as “Skipped” in saved-night views.

## Starter content and resume

There is no sample content in the normal app experience. An unfinished ritual remains on the device and can be continued when the app is reopened.

## Permissions

None. The app does not request system permissions.

## Absent

- Login or accounts: absent.
- In-app purchase: absent.
- Ads: absent.
- Analytics: absent.
- User-generated content: present; users write their own ritual lines.
- Account deletion flow: absent; there are no accounts.
- App Tracking Transparency prompt: absent.

## Data and support

Ritual lines, settings, and sealed nights stay on this device. Settings includes the “Contact” link for support.

## Scanning and health

None. The app does not scan barcodes or QR codes and does not show health, medical, or product-health information.

## Platform

The app supports iPhone and iPad, requires iOS 17.0 or later, and runs in portrait and landscape orientations. It has no region-specific behavior identified in the native interface.

## Category

Health & Fitness.
