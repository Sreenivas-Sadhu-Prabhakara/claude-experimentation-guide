# Shared build brief — "Filter Coffee Brew Companion"

> **Run status (read this first).** As of 2026-07-15 both named arms have produced real,
> `jarsigner`-verified signed `.aab` artifacts locally against this brief. The GPT 5.6 Sol
> arm has a captured Codex wrapper token count (285,373). The GPT wrapper was interrupted
> after a repeated verbose transcript loop, so the final GPT artifact evidence is based on
> an independent rebuild and verification of the project it created. No benchmark is
> fabricated.

> This is the **byte-identical prompt** each contender receives. It is a real product
> brief, not a leading spec: it states outcomes and constraints, and leaves the
> architecture, data model, and UI to the model. Hand this verbatim to any agent
> (Claude Code / Opus 4.8, GPT 5.6 Sol, etc.) to reproduce the lab.

> **Scoping.** This lab fixes the framework (Flutter) and the deliverable (a signed Android
> `.aab`). It therefore measures **an agent's ability to drive that specific toolchain
> end-to-end to a deployable artifact** — not general framework choice, and not which
> model is "best" at everything. Both contenders face the identical constraint.

## The task

Build a polished, **offline-first Android app** for South Indian filter-coffee lovers,
and deliver it **end-to-end to a signed release `.aab` that is ready to upload to Google
Play**. One session. No human hand-holding on the toolchain.

## Hard constraints

1. **Framework:** Flutter (stable channel).
2. **Offline-first:** no backend, no network calls, no account. All data lives on the
   device. No analytics or tracking SDKs.
3. **Deliverable:** a **signed release Android App Bundle** (`flutter build appbundle
   --release`) that passes `jarsigner -verify` and bundles the standard ABIs. Provide the
   signing setup (upload keystore + externalised `key.properties`, secrets git-ignored).
4. **Quality gate:** `flutter analyze` must report **zero** issues; at least a smoke test
   and one logic test must pass.
5. **House style:** do not ship a templated / "AI-generic" look. No serif display fonts.

## Required features

- **Ratio calculator** — pick a brew method, solve water-from-dose or dose-from-water,
  a strength control, and a quick-cups helper. Correct ratio math.
- **Guided brew timer** — per-method staged recipe (label + hint + duration), a countdown
  with progress, next-stage preview, start/pause/skip/reset, haptics on stage change.
- **Brew log** — persistent history of brews with method, bean, roast, grind, dose, yield
  (auto ratio), a 0–5 rating, flavour tags, and free notes. Add / edit / delete. Empty
  state. Summary stats.
- **Settings** — default method, default strength, cup size, theme (system/light/dark),
  clear-all-data, and an honest "stored on this device" statement.

## What "done" means

The reviewer can: unzip the `.aab` and see a valid bundle; run `jarsigner -verify` and get
`jar verified`; run `flutter analyze` and see no issues; run `flutter test` and see green;
and open the source to find each required feature actually implemented (not stubbed).

## Deliberately left open (the model decides)

State management, persistence mechanism, number of files, theming specifics, the exact
brew-method presets and their timer choreography, and any extra polish.
