# Objective grading rubric — 100 points

> **Run status.** A **preliminary artifact audit** exists for both locally-built app
> artifacts. Each arm produced a real, `jarsigner`-verified `.aab`; the GPT arm also has a
> captured Codex wrapper token count (285,373). These are objective artifact checks, not a
> subjective product-preference verdict.

> Every criterion is **checkable against the delivered repo and artifact**. Sections 1–5
> and 7 are fully objective (a passing command, a file, a verified signature). Section 6
> (polish) is scored via **objective proxies** rather than taste — see its checks below.
> A criterion scores full marks only with concrete evidence.

## 1 · Ships a deployable artifact — 25 pts
| Check | Pts | How it's verified |
|---|---|---|
| A signed release `.aab` exists | 8 | file present under `build/.../bundle/release` |
| `jarsigner -verify` → `jar verified` | 7 | run the command |
| Valid bundle (BundleConfig.pb + base/ + dex + libs) | 5 | `unzip -l` |
| Standard ABIs bundled (arm64-v8a, armeabi-v7a, x86_64) | 5 | `unzip -l \| grep base/lib` |

## 2 · Spec coverage — 20 pts
| Feature actually implemented (not stubbed) | Pts |
|---|---|
| Ratio calculator (solve both directions + strength + cups) | 6 |
| Guided brew timer (staged, countdown, controls, haptics) | 6 |
| Persistent brew log with tasting notes (add/edit/delete) | 6 |
| Settings (defaults, theme, clear data) | 2 |

## 3 · Correctness — 15 pts
| Check | Pts |
|---|---|
| Ratio math correct (e.g. 18 g × 1:15 = 270 ml) | 4 |
| Persistence survives an app restart (verified by test) | 4 |
| Timer stage-advance / done logic correct | 4 |
| Tests present and passing | 3 |

## 4 · Code quality — 15 pts
| Check | Pts |
|---|---|
| `flutter analyze` → zero issues | 6 |
| Sensible separation (models / services / screens / widgets) | 5 |
| No dead code, idiomatic Flutter, dependency discipline | 4 |

## 5 · Offline-first & privacy — 10 pts
| Check | Pts |
|---|---|
| No network calls / no analytics SDKs | 5 |
| Data on-device only; minimal Android permissions | 3 |
| Honest in-app privacy statement | 2 |

## 6 · UX & polish — 10 pts (scored by objective proxies, not taste)
| Check (operationalised) | Pts |
|---|---|
| Intentional theme, not template default: a **custom `ColorScheme`/tokens** defined (not the stock seed) **and no serif display font** | 4 |
| Empty-state widget present **and** input validation (formatters / divide-by-zero guards) | 3 |
| Accessibility basics: tap targets ≥ 40 px, tabular figures on numerics, labelled nav | 3 |

## 7 · Production readiness — 5 pts
| Check | Pts |
|---|---|
| Version + launcher label set | 2 |
| Signing config externalised; secrets git-ignored | 2 |
| Build/run instructions present | 1 |

---
**Scoring notes.**

- **Cap rule (run-and-failed only).** A contender that **was run** but never reached a
  verifiable signed `.aab` caps at the points it can evidence in sections 2–7. This cap
  **never** applies to a contender that was **not run** — an un-run column has *no* score
  at all (not a zero, not a capped number). "Not run" (no data) and "run and scored low"
  (measured) must never be conflated.
- **Weighting caveat.** Section 1's four sub-checks are correlated (an `.aab` that exists,
  verifies, unzips, and carries ABIs are facets of one success), so the 25-pt deployability
  spine is intentionally heavy. The `x86_64` ABI check is lenient by design — it is
  emulator-oriented and a legitimate release `.aab` may omit it; both contenders face the
  identical bar.
