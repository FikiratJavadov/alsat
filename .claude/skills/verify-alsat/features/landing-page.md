# Landing page

Opening an app's root URL shows the Turborepo logo, a two-step "Get started" list that names that app's own `page.tsx`, two CTA links, the `Open alert` button, and a footer with two links. The tab title is `Create Next App`.

## Sub-features

- `landing-render` shows the page with all landmarks.
- `landing-identity` makes the edit hint name `apps/web/app/page.tsx` or `apps/docs/app/page.tsx`.
- `landing-clean` produces no runtime errors in the browser or server log.

## How to get to it (user POV)

- Visit `/` on the running app.

## Driving it with agent-browser

Preconditions:

- Baseline from [README.md](./README.md).

- **Open.** Run `vb open "$URL"`. Prints `✓ Create Next App` and the URL.
- **Title.** Run `vb get title`. Prints `Create Next App`.
- **Identity.** Run `vb get text main`. Contains `Get started by editing apps/$APP/app/page.tsx`, `Save and see your changes instantly.`, `Deploy now`, `Read our docs`, and `Open alert`.
- **Landmarks.** Run `vb snapshot -i > $EVIDENCE/$APP.landing.aria.txt`. Lists links `Deploy now`, `Read our docs`, `Examples`, `Go to turborepo.dev →` and button `Open alert`.
- **Screenshot.** Run `vb screenshot --full $EVIDENCE/$APP.landing.png`. The logo and text are visible.
- **Clean.** Run `vb errors` and `grep -iE "error|warn" "$LOG"`. Both are empty apart from the Node engine warning.

## Gotchas

- `curl` alone proves only SSR. The browser steps are what show hydration and client errors.
- The two apps differ only in the edit hint and the alert text. Check `landing-identity` before trusting any other result.
- The round `N` badge in the bottom-left of screenshots is the Next.js dev indicator. It is not part of the app.
