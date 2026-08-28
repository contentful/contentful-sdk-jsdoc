# AGENTS.md

Guidance for coding agents working in `contentful-sdk-jsdoc`.

## What this repo is

An npm package (`contentful-sdk-jsdoc`, MIT) that ships two independent
artifacts to the Contentful JavaScript SDKs:

1. `jsdoc-template/` — a vendored fork of the JSDoc 3 default template
   (`publish.js` plus `<?js ?>` templates in `tmpl/` and assets in `static/`).
2. `bin/publish-docs.sh` — a Bash script that pushes generated HTML into a
   consuming repo's `gh-pages` branch.

There is **no application, no library entry point, and no test suite**. Note
that `package.json` declares `"main": "index.js"` but no `index.js` exists in
the repo; consumers reference files by path, not via `require()`. Do not
"fix" this by creating an `index.js` — nothing imports the package.

The published `files` allowlist is `["jsdoc*", "bin"]`, so only
`jsdoc-template/` and `bin/` reach npm.

## Before you change anything

- `jsdoc-template/` has **no known consumer** in the `contentful` org. Both
  `contentful.js` and `contentful-management.js` generate their HTML with
  TypeDoc and use this package only for `bin/publish-docs.sh`. An org-wide code
  search for `jsdoc-template` returns hits in this repo only. Treat template
  changes as unverifiable and say so rather than claiming they were tested.
- `bin/publish-docs.sh` is live. It is invoked from the `docs:publish` script in
  both SDKs and writes to their `gh-pages` branches. Changes there can break two
  release pipelines. See [ARCHITECTURE.md](./ARCHITECTURE.md) for the contract.

## Commands

- `npm test` is literally `"true"` — it always passes and asserts nothing.
- There is no lint, format, typecheck, or build script.
- `npm run semantic-release` is for CI only. Never run it locally.
- `npm ci` installs dev dependencies. `.npmrc` sets `ignore-scripts=true`, so
  dependency lifecycle scripts do not run.
- Node version: `.nvmrc` pins `v22`; the release workflow runs Node `24`.

## Conventions

- Commit messages must follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/);
  `commitizen` with `cz-conventional-changelog` is configured in `package.json`.
- The commit type decides whether npm publishes. Use `docs:` or `chore:` for
  changes that must not release; `fix:`/`feat:` trigger a release from `master`.
  `build(deps)` is also configured to release a patch.
- Do **not** hand-edit the `version` field in `package.json`. semantic-release
  owns versioning. The in-repo value is stale by design (see below).
- Do not add generated docs output (`out/`, `gh-pages/`) — both are covered by
  `.gitignore` or created at runtime.

## Things that look like bugs but are not

- `package.json` says `"version": "2.2.0"` while npm serves `3.1.6`. The release
  config has `@semantic-release/changelog` but no `@semantic-release/git`, so the
  version bump and `CHANGELOG.md` are generated during the CI release and never
  committed back to `master`. That is also why this repo has no `CHANGELOG.md`.
- `publish.js` still calls a variable `taffy` and references TaffyDB in a JSDoc
  comment, but the import is `@jsdoc/salty`. This is deliberate — see
  [docs/ADRs/2026-08-25-replace-taffydb-with-jsdoc-salty.md](./docs/ADRs/2026-08-25-replace-taffydb-with-jsdoc-salty.md).

## Ownership

`.github/CODEOWNERS` and `catalog-info.yaml` both assign this repo to
`team-developer-experience`. `catalog-info.yaml` records it as a tier-4 library.
