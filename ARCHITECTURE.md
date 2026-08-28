# Architecture

`contentful-sdk-jsdoc` is a support package for the Contentful JavaScript SDKs.
It is published to npm and consumed as a dev dependency; it is never imported as
a module.

## Repository layout

```
jsdoc-template/          JSDoc template (theme)
  publish.js             Template entry point: exports publish(taffyData, opts, tutorials)
  tmpl/*.tmpl            JSDoc <?js ?> templates (layout, container, method, params, …)
  static/styles/         jsdoc.css, hljs.css, arrow-down.svg
  static/scripts/hljs/   highlight.js bundle used for code samples
bin/publish-docs.sh      Publishes generated HTML to a consumer's gh-pages branch
.github/workflows/       CI (main.yaml) and release (release.yaml, codeql.yml)
.contentful/             Vault policy declarations for CI secret retrieval
catalog-info.yaml        Backstage component metadata (tier-4 library)
```

`package.json` restricts the published tarball to `files: ["jsdoc*", "bin"]`, so
only `jsdoc-template/` and `bin/` are shipped.

## Component 1 — the JSDoc template

`jsdoc-template/publish.js` is a fork of the JSDoc 3 default template. It exports
`publish(taffyData, opts, tutorials)`, which JSDoc calls when the template is
selected. The module resolves its dependencies from JSDoc's own runtime
(`jsdoc/util/doop`, `jsdoc/fs`, `jsdoc/util/templateHelper`, `jsdoc/util/logger`,
`jsdoc/path`, `jsdoc/template`) and pulls its database layer from
`@jsdoc/salty` — the only runtime dependency in `package.json`.

`tmpl/layout.tmpl` is the page shell. Its footer links back to this repository
and labels the output "the contentful-sdk-jsdoc theme", which is how generated
docs identify their source.

**Current status:** no repository in the `contentful` org selects this template.
`contentful.js` and `contentful-management.js` both generate their HTML with
TypeDoc (`typedoc --options typedoc.json` and `typedoc` respectively). An
org-wide code search for `jsdoc-template` matches only this repository. The last
functional change to `publish.js` was commit `60fd93d` (2024-11-20). Treat this
component as dormant.

## Component 2 — `bin/publish-docs.sh`

This is the part the SDKs still use. Both SDK repos declare
`contentful-sdk-jsdoc` as a dev dependency and call the script from their
`docs:publish` npm script:

- `contentful.js` — `./node_modules/contentful-sdk-jsdoc/bin/publish-docs.sh contentful.js contentful`
- `contentful-management.js` — `./node_modules/contentful-sdk-jsdoc/bin/publish-docs.sh contentful-management.js contentful-management`

Contract:

- **Arguments:** `$1` = repository name under the `contentful` org, `$2` =
  namespace directory inside `gh-pages`.
- **Working directory:** the consumer's repo root. The script reads
  `package.json` for the version with `jq`, so the version published is the
  *consumer's* version, not this package's.
- **Input:** generated HTML in `./out`. The script exits 1 if `./out` is missing.
- **Auth:** `GITHUB_TOKEN` (GitHub App token) is preferred; `GH_TOKEN` is
  supported as a legacy fallback.
- **Requirements on PATH:** `git`, `jq`.

Behaviour: clone the consumer's `gh-pages` branch into `./gh-pages`, copy `./out`
to `<namespace>/<version>/`, replace `<namespace>/latest/` with the same content,
write a root `index.html` that redirects to the versioned path, then commit with
`[skip ci]` and push.

## Release pipeline

`.github/workflows/main.yaml` runs on every push and pull request. It calls
`release.yaml` only for pushes to `master` or `dev`. `release.yaml` retrieves a
GitHub App token from Vault (`hashicorp/vault-action`, role
`<repo>-github-action`, policies declared in `.contentful/vault-secrets.yaml`),
sets up Node 24, runs `npm ci`, then `npm run semantic-release`.

The semantic-release config lives in the `release` key of `package.json`:
`master` publishes the `latest` dist-tag; `dev` publishes prereleases on the
`dev` channel. Plugins are commit-analyzer (with `build(deps)` → patch),
release-notes-generator, npm, changelog, and github. Because
`@semantic-release/git` is not in the plugin list, the version bump and
`CHANGELOG.md` are produced inside the CI job and never committed back — the
`version` field on `master` therefore lags the published version.

## Verification

There is no test suite: `npm test` is `"true"`. `.github/workflows/codeql.yml`
scans GitHub Actions workflow definitions only (`languages: actions`) and runs
solely on changes under `.github/workflows/**`. Nothing in CI exercises
`publish.js` or `publish-docs.sh`. Changes to either are validated by running the
docs pipeline in a consuming SDK repo.

## Dependency maintenance

Renovate is configured in `renovate.json`, extending
`local>contentful/renovate-config`, labelling PRs `dependencies`, and pinning
`husky` below 5.0.0. It replaced Dependabot in commit `ee7692c`.
