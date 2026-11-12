# alsat verification map

This directory is the maintained source for verifying the user-facing behavior of the `web` and `docs` apps. Read this index before driving, then use the matching feature file as the recipe.

## Baseline preconditions

- Launch with `"$C" launch web` or `"$C" launch docs`, then `source "$R/env"`. See [../SKILL.md](../SKILL.md).
- `"$C" doctor "$R"` reports all `ok`.
- Open `$URL` (a `localhost` URL) with `vb open "$URL"` and wait for hydration with the `vb wait --fn` line from SKILL.md.
- No seed data, auth, or env vars are needed.
- Never drive an instance this run did not start.

## Driving conventions

- Prefer ARIA roles and accessible names (`vb find role button click --name "Open alert"`) over CSS selectors.
- Re-run `vb snapshot -i` before using an `@eN` ref, because refs go stale after page changes.
- Do not follow outbound links. They open external sites in new tabs. Assert `href` and `target` instead.
- Features shared through `packages/ui` must be proven in both apps, in two runs, one after the other.

## Proof and skip reporting

- Capture the user action and the resulting state: ARIA snapshot and screenshot before and after.
- Alert proof is `window.__verifyAlerts` after a real click.
- Record the app (`web` or `docs`) and the feature ID in every artifact name.
- Report an unreachable path with the command you tried and the unmet precondition. Do not report one app as verified through the other.

## Feature entry contract

Each feature file has an H1, one paragraph describing user-visible behavior, then exactly these H2s in order: `Sub-features`, `How to get to it (user POV)`, `Driving it with agent-browser`, `Gotchas`.

## Features

- [Landing page](./landing-page.md) covers page render, title, the app-specific edit hint, and the absence of runtime errors.
- [Open alert](./open-alert.md) covers the shared `@repo/ui` Button and its app-specific alert message.
- [Outbound links](./outbound-links.md) covers the CTA and footer links, their destinations, and new-tab behavior.
- [Theme logo](./theme-logo.md) covers swapping the light and dark Turborepo logo with the system color scheme.
