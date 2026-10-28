# Rotulus

A bedtime scroll. Reflect, Breathe, and Ambient stay in that order. You commit one release line on the chamber in front of you, furl to the next, and roll the night shut. The sealed night stays on this device.

## Why a fold

Tonight is one scroll, not a list of sessions. The scroll is a fold over three panels with three phases: Bare, Marked, and Rolled. `Scroll.apply` is the only transition.

- Set writes a line on the focused panel and folds Bare to Marked.
- Waft marks the panel with no text, for a chamber you skip.
- Furl advances only when that panel is already marked. A bare panel refuses it.
- Roll writes the night mark and folds Marked to Rolled once all three panels are marked. Rolling early, or rolling again, is refused.

That is the product. Home is the unfurled scroll, and the seal is the thing you came to do. A night you never touch is recorded as blank: it does not count as a finished rite and it does not break the streak. Streak and counts come only from sealed nights.

The screen layer reads a session that holds the record. It does not write storage itself. The record is saved under one key, debounced after each committed verb, and flushed when the app leaves the foreground.

Home is that fold: the chamber in front of you, one release line, then advance, then seal. History and Settings open as sheets over the same rite. There is no tab bar.

## Art

High-contrast black and white photography turned into a typographic, dithered surface: ordered-dot and error-diffusion grain, deep blacks, soft paper-white highlights, quiet evening stillness. Subjects are a hanging scroll, washi paper fibres, a brush resting on a stone, and slow smoke. The mood is nostalgic and calm, with large negative space for type, no people's faces, no text inside the image and no glossy 3D.

- `rtl_Onboarding1`: the same prompt, a person or object that is this product in one glance.
- `rtl_Onboarding2`: the same prompt, the primary action of this product, mid-gesture.
- `rtl_Onboarding3`: the same prompt, a later moment when the product has accumulated meaning.
- `rtl_EmptyHome`: the same prompt, a solid closed bowl, crate or folded cloth waiting to be used.
- `rtl_TwistHero`: the same prompt, an emblem of the fold from a bare chamber to a sealed night.
- `rtl_RolledScrollCutout`: Single rolled makimono scroll tied with a cord, photographed in high-contrast black and white and rendered as a coarse dithered dot pattern, centered solid subject, real transparent background with clean alpha edges, no plate, no frame.
- `rtl_EmptyRiteArt`: An unfurled blank hanging scroll with a brush laid beside it, high-contrast black and white photograph translated into soft ordered dithering, centered solid subject on a transparent background, calm evening mood, generous negative space.

## Build

```
xcodegen generate
xcodebuild -scheme Rotulus -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```
