---
name: verify-alsat
description: Drive the alsat monorepo's Next.js apps (`web` on apps/web, `docs` on apps/docs) in a real headless browser to prove UI changes work. Use when a change touches apps/web, apps/docs, or packages/ui and you need evidence from the running app, not just typecheck or lint.
---

# Verify alsat

alsat is a Turborepo with two Next.js 16 apps, `web` and `docs`. Each serves one landing page that uses components from `@repo/ui` (`packages/ui`). The only surface a user touches is the browser. This skill starts one app's dev server on a spare port, drives it with `agent-browser` in an isolated session, saves evidence, and tears everything down.

All commands go through `scripts/control.sh`. Set this up once per shell:

```bash
C="$(git rev-parse --show-toplevel)/.claude/skills/verify-alsat/scripts/control.sh"
vb() { "$C" browser "$R" "$@"; }   # agent-browser bound to this run's session
```

Use the `vb` function rather than `B="$C browser $R"`. zsh does not word-split `$B`.

## Launch

```bash
R=$("$C" launch web | sed -n 's/^RUN_DIR=//p')   # or: launch docs
source "$R/env"   # APP PORT URL SESSION EVIDENCE LOG RUN_ID
```

`launch` runs `pnpm --filter <app> exec next dev --port <free port 3100-3199>` and returns once the log prints `Ready in` and `GET /` answers. It does not wait for the browser. Ready-to-drive also means React has hydrated (see Drive). There is no database, no auth, and no seed data. The `Unsupported engine: wanted node >=24` warning is expected on Node 22 and harmless.

Isolation: each run gets its own port and its own `agent-browser` session. Two runs of the same app cannot run at once, because `next dev` holds a lock on `apps/<app>/.next`. `launch` warns when any `next dev` is already running. Never drive or stop a server this run did not start. That includes the user's own `pnpm dev` on 3000/3001.

## Doctor

```bash
"$C" doctor "$R"
```

This is read-only. It checks that the server pid is alive, that the port's listener belongs to this run's process tree, and that `$URL` serves the right app (the page text names `apps/<app>/app/page.tsx`). Run it first whenever anything looks off. A FAIL means stop and relaunch, not keep driving.

## Drive

`vb` is `agent-browser --init-script scripts/alert-recorder.js` bound to `$SESSION`. The recorder pushes every `window.alert` message onto `window.__verifyAlerts` and then calls the real alert, which agent-browser auto-accepts.

```bash
vb open "$URL"
vb wait --fn "Object.keys(document.querySelector('button') || {}).some(k => k.startsWith('__reactProps'))"   # hydrated
vb snapshot -i                         # accessible names: buttons and links
vb find role button click --name "Open alert"
vb eval 'JSON.stringify(window.__verifyAlerts)'
```

Stable handles: ARIA role and accessible name (`button "Open alert"`, `link "Read our docs"`), and the visible text in `main`. For attributes, take a ref from `vb snapshot -i` and then run `vb get attr @eN href`. CSS `:has-text()` selectors do not work with `get attr`.

Rules that cost real time to learn:

- Always use `http://localhost:<port>`, never `127.0.0.1`. Next 16 dev blocks cross-origin dev resources (`allowedDevOrigins`). The page still renders on 127.0.0.1 but never hydrates, so clicks do nothing.
- Never pass `--no-auto-dialog`. A native alert then blocks the agent-browser daemon, and every later command hangs. `stop` kills a stuck daemon by pid.
- `--init-script` takes effect only when the session's browser starts. If you `vb close`, the next `vb open` reapplies it. A session started without `vb` has no recorder.

Per-feature recipes are in [features/README.md](features/README.md). Read the index, then the feature file.

## Evidence

Write everything to `$EVIDENCE` (`/tmp/verify-alsat/evidence/<run-id>/`), named `<feature-id>.<step>.<ext>`:

- `vb snapshot -i > $EVIDENCE/<id>.aria.txt` and `vb screenshot $EVIDENCE/<id>.png` before and after the action.
- `vb eval 'JSON.stringify(window.__verifyAlerts)' > $EVIDENCE/<id>.alerts.json` for alert behavior.
- Server-side errors: copy the relevant part of `$LOG` into `$EVIDENCE/server.log` before `stop`, because `stop` deletes the run dir.

Proof standards: click the real button the way a user does, and never call component functions or `eval` a click. Capture the state before and after, not only the final screen. When a change touches `packages/ui`, prove it in both apps, because each passes its own props (`appName="web"` and `appName="docs"`). Check `vb errors` and `$LOG` for runtime errors. A page can look right while throwing.

## Cleanup

```bash
"$C" stop "$R"
```

`stop` closes this run's browser session, killing its daemon by pid if it does not answer. It then kills only the dev server's own process tree and deletes `/tmp/verify-alsat/runs/<run-id>`. Evidence under `/tmp/verify-alsat/evidence/` is never touched. Run `stop` after failed attempts too. Never `pkill next` or kill by name.

## Helpers

- `scripts/control.sh launch|doctor|browser|url|stop`: see the header comment. Run it with no args for usage.
- `scripts/alert-recorder.js`: verification scaffolding. `vb` loads it automatically. It does not change app code.
