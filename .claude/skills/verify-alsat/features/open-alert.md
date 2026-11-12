# Open alert

Each app's landing page has an `Open alert` button from `@repo/ui/button`. Clicking it shows a browser alert that names the app: `Hello from your web app!` on web, `Hello from your docs app!` on docs.

## Sub-features

- `open-alert-web` shows the web message.
- `open-alert-docs` shows the docs message.
- `open-alert-repeat` shows one alert per click.

## How to get to it (user POV)

- Open the app's home page and click `Open alert` under the CTA buttons.

## Driving it with agent-browser

Preconditions:

- Baseline from [README.md](./README.md), page hydrated.
- `vb eval 'JSON.stringify(window.__verifyAlerts)'` returns `"[]"`. A fresh page load resets it.

- **Before.** Run `vb snapshot -i > $EVIDENCE/$APP.open-alert.before.aria.txt` and `vb screenshot $EVIDENCE/$APP.open-alert.before.png`. The snapshot lists `button "Open alert"`.
- **Click.** Run `vb find role button click --name "Open alert"`. Prints `✓ Done` and does not hang.
- **Alert text.** Run `vb eval 'JSON.stringify(window.__verifyAlerts)' | tee $EVIDENCE/$APP.open-alert.alerts.json`. Output is `"[\"Hello from your web app!\"]"` (or `docs`).
- **Dismissed.** Run `vb dialog status`. Prints `No dialog is currently open`, and the page is still interactive.
- **Repeat.** Click again. The array now has two identical entries.
- **After.** Run `vb screenshot $EVIDENCE/$APP.open-alert.after.png` and `vb errors`. No page errors.

## Gotchas

- An empty `[]` after the click almost always means the page did not hydrate. Either you opened `127.0.0.1` or you clicked before the `wait --fn` check.
- Do not use `--no-auto-dialog`. The alert blocks the daemon and every later `vb` call hangs until `stop`.
- The alert is native, so screenshots never show it. The recorder array is the proof.
