# ⚠️ ARCHIVED — Do Not Edit iOS Code Here

**The live iOS app does not live in this folder.**

This `ios/` directory was originally intended as a distributable reference
copy of the Pixelated Fitness iOS app for the `openclaw-fitness` plugin
bundle. It has since diverged from — and fallen significantly behind — the
real iOS codebase. **Any edits made here will NOT reach the live iOS app**
on Birch's phone.

## Canonical iOS repo

```
~/iOS/pixelatedfitness
git remote: https://github.com/pixelated-fitness/iOS.git
branch:     main
```

That's the repo the live app builds from. All iOS work — code changes, xcodeproj
edits, asset updates, version bumps, tests — goes there.

## Why this exists, what to ignore

- **This folder's Swift source files, xcodeproj, and `Design/` subfolder are
  frozen/stale** as of the last commit to `openclaw-fitness`. They reflect an
  older, divergent state. Reading them is fine for historical reference; do
  not port them forward in either direction without cross-checking the
  canonical repo first.
- **`PHASE1-PHASE4-CHANGES.md` and `TOAST-PLAN.md` in this folder are still
  valid** as design-intent documents (they were written deliberately here as
  part of the openclaw-fitness plugin planning). Their matching *code* lives
  in the canonical repo.
- **The rest of `openclaw-fitness/` (bridge, hooks, skills, training) is not
  affected by this archival notice** — those remain the in-play plugin
  distribution. Only this `ios/` subfolder is stale.

## History of this mistake

- **2026-04-20:** Full toast system + exercise-removal debounce-undo was
  landed in this folder (commit `682e3b7`) under the incorrect belief it
  was the live iOS repo. Those changes never reached Birch's app.
- **2026-04-21:** Toast system was properly re-ported to
  `~/iOS/pixelatedfitness` (commit `a8a56f5`) and this `ARCHIVED.md`
  notice was placed here to prevent the same mistake from recurring.

## What to do if you find yourself editing files in this folder

1. **Stop.** Close the file without saving.
2. **Open the canonical repo instead:** `open ~/iOS/pixelatedfitness`
3. **Check what you intended to change** — it may already exist in the
   canonical repo, may need to be ported from here, or may need to be
   built fresh there. The two repos are not 1:1.

— Added 2026-04-21
