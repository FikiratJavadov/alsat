# Theme logo

The page follows the system color scheme. In light mode it shows the dark Turborepo wordmark (`img.imgLight`, `turborepo-dark.svg`) on a light background. In dark mode it swaps to `img.imgDark` (`turborepo-light.svg`) on `#0a0a0a`.

## Sub-features

- `theme-light` shows only `imgLight`.
- `theme-dark` shows only `imgDark` and uses the dark background.

## How to get to it (user POV)

- Switch the OS or browser between light and dark appearance, then look at the logo above the "Get started" list.

## Driving it with agent-browser

Preconditions:

- Baseline from [README.md](./README.md).

- **Dark.** Run `vb set media dark`, then `vb is visible 'img.imgDark'` (prints `true`) and `vb is visible 'img.imgLight'` (prints `false`). Run `vb screenshot $EVIDENCE/$APP.theme-dark.png`.
- **Light.** Run `vb set media light`, then `vb is visible 'img.imgDark'` (prints `false`) and `vb is visible 'img.imgLight'` (prints `true`). Run `vb screenshot $EVIDENCE/$APP.theme-light.png`.

## Gotchas

- Both images are always in the DOM, so the ARIA snapshot lists both. Visibility is the proof, not presence.
- `set media` persists for the session. Reset it to `light` before running another feature.
- agent-browser's headless Chrome starts in dark mode on this machine. Set `vb set media light` or `vb set media dark` explicitly instead of relying on the default.
