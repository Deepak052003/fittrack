# FitTrack

A Flutter fitness tracker that ships as an installable, offline-capable
web app (PWA) hosted on Cloudflare.

**Live app:** https://app.fittrack-app.workers.dev

- **Training**: week streak, "Today's workout", Gym/Home and Beginner/Intermediate/Advanced, workouts by body part (chest, back, shoulders, arms, legs, core, cardio) and a custom mix.
- **Workout player**: 10-second get-ready countdown, looping form video, target reps or timer, Done, rest (1 min by default, set in Me, "+15 s" button) with a preview of the next exercise, beep and keep-screen-on. Finished workouts are saved automatically.
- **Look**: dark obsidian-navy by default (Light available in Me), frosted glass cards, coral accent, Inter font (Latin subset, `assets/fonts/`).
- **Report**: totals, this week, history (with manual logging for runs, rides and sports), weight trend and BMI.
- **Me**: name, height and weight, BMI, goals, rest time, theme, install app, export, licenses, reset. No account or email needed.

All data stays on the device (`shared_preferences` → `localStorage` on web). The app asks the browser to keep it permanently (`navigator.storage.persist()`), so it is not cleared when storage runs low.
Calories are estimated with MET × weight × duration.

New to Dart/Flutter? Read [docs/BEGINNER_GUIDE.md](docs/BEGINNER_GUIDE.md) first.

## Develop (VS Code)

1. Install the **Flutter** extension. `.vscode/settings.json` in the workspace points it at `C:\flutter`.
2. Pick **Chrome** as the device and press **F5**, or run `flutter run -d chrome`.
3. Run `flutter analyze` and `flutter test` before deploying.

The service worker only exists in release builds, so offline mode can't be tested under `flutter run`.

## Add or change exercises

Edit `lib/data/exercise_catalog.dart`. Copy an existing `Exercise(...)` entry.

**Clips:** put a short `<exercise-id>.mp4` (5–15 s, H.264, muted is fine) in `web/videos/`, e.g. `push-up.mp4`. It plays inline as a loop. Then run `npm run compress-videos` to shrink it to HD and make its thumbnail. Exercises without a clip show an icon. All file names and which ones are done: [docs/VIDEO_CHECKLIST.md](docs/VIDEO_CHECKLIST.md). The clips themselves are licensed media and are not included in this repository.

## Build and deploy to Cloudflare

```sh
npm install              # once: installs wrangler
npx wrangler login       # once: opens the browser to sign in to Cloudflare
npm run deploy           # flutter build web + sw.js + wrangler deploy
```

Your app is deployed to `https://app.<your-subdomain>.workers.dev` (currently `https://app.fittrack-app.workers.dev`). To use your own
domain, add a custom domain to the `app` Worker in the Cloudflare dashboard.

- `npm run build` builds into `build/web` without deploying.
- `npm run preview` builds, then serves locally with the Cloudflare runtime (`wrangler dev`).

## How the PWA parts work

| File | Purpose |
| --- | --- |
| `web/manifest.json` | App name, icons, standalone display, "Log workout" shortcut |
| `web/index.html` | Splash screen, install-prompt bridge (`window.fitPwa`), service worker registration |
| `web/flutter_bootstrap.js` | Starts Flutter and hides the splash screen |
| `pwa/sw.template.js` | Offline-first service worker (template) |
| `tool/build_web.mjs` | Release build, then generates `build/web/sw.js` with a content hash so each deploy triggers an update |
| `web/_headers` | Cloudflare response headers |
| `wrangler.jsonc` | Cloudflare Workers static-assets config |
| `worker.js` | Serves videos in byte ranges (needed by iPhone Safari) |
| `tool/generate_icons.ps1` | Regenerates the icons in `web/` |
| `lib/pwa/` | Dart side of the install / update / theme-color / beep / wake-lock bridge |

Install support:
- **Android / Chrome / Edge**: an Install button appears in the app (Me tab).
- **iPhone / iPad**: Safari → Share → *Add to Home Screen*. Profile shows these steps.
- **Updates**: when a new deploy is detected, a "new version is ready · Reload" message appears.
