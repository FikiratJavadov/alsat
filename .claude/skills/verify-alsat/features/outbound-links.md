# Outbound links

The landing page links out to Vercel and Turborepo. There are two CTA buttons in `main` (`Deploy now`, `Read our docs`) and two footer links (`Examples`, `Go to turborepo.dev →`). All of them open in a new tab with `rel="noopener noreferrer"`.

## Sub-features

- `links-cta` covers `Deploy now` to `vercel.com/new/clone` and `Read our docs` to `turborepo.dev/docs`.
- `links-footer` covers `Examples` to `vercel.com/templates` and `Go to turborepo.dev →` to `turborepo.dev/`.
- `links-newtab` makes every outbound link use `target="_blank"`.

## How to get to it (user POV)

- Click a CTA button in the main column, or a link in the footer.

## Driving it with agent-browser

Preconditions:

- Baseline from [README.md](./README.md).

- **Inventory.** Run `vb eval 'JSON.stringify([...document.querySelectorAll("a")].map(a=>[a.textContent.trim(),a.target,new URL(a.href).host+new URL(a.href).pathname]))' | tee $EVIDENCE/$APP.links.json`. Output is `Deploy now/_blank/vercel.com/new/clone`, `Read our docs/_blank/turborepo.dev/docs`, `Examples/_blank/vercel.com/templates`, `Go to turborepo.dev →/_blank/turborepo.dev/`.
- **One link via refs.** Run `vb snapshot -i`, find the ref for `link "Read our docs"`, then run `vb get attr @eN href` and `vb get attr @eN target`. Prints `https://turborepo.dev/docs?utm_source` and `_blank`.

## Gotchas

- Do not click these links. They leave localhost and open new tabs on third-party sites.
- `vb get attr` needs an `@eN` ref or a plain CSS selector. `a:has-text(...)` returns `Element not found`.
