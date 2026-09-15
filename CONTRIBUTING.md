# Contributing

Thanks for helping maintain `contentful-sdk-jsdoc`. This package supplies the
JSDoc template and the `gh-pages` publishing script used by the Contentful
JavaScript SDKs. Read [ARCHITECTURE.md](./ARCHITECTURE.md) first — the two things
in this repo have very different blast radii.

## Setup

```sh
nvm use          # .nvmrc pins Node v22
npm ci
```

`.npmrc` sets `ignore-scripts=true`, so dependency lifecycle scripts are skipped
during install.

## What you can and cannot verify locally

There is no test suite. `npm test` is defined as `"true"` and always passes; it
asserts nothing. There is no lint, format, or build script either.

- **`bin/publish-docs.sh`** is exercised by the `docs:publish` script in
  `contentful.js` and `contentful-management.js`. To verify a change, install
  your branch into one of those repos and run its docs pipeline. Do not run
  `docs:publish` against a real repo casually — it commits and pushes to that
  repo's `gh-pages` branch.
- **`jsdoc-template/`** has no known consumer. Both SDKs generate HTML with
  TypeDoc, so there is currently no pipeline that renders this template. If you
  change it, generate output with a local JSDoc run against a sample source tree
  and state in the PR what you were able to check.

Be explicit in your PR description about what you verified and what you could
not.

## Commits

Commit messages must follow
[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).
`commitizen` is configured with `cz-conventional-changelog`, so
`npx cz` will prompt you through a valid message.

The type controls whether merging your PR publishes to npm:

| Type | Effect on release |
| --- | --- |
| `feat:` | minor release |
| `fix:` | patch release |
| `build(deps):` | patch release (configured in `releaseRules`) |
| `BREAKING CHANGE:` footer | major release |
| `docs:`, `chore:`, `test:`, `style:`, `refactor:` | no release |

Never bump `version` in `package.json` yourself — semantic-release owns it, and
the value on `master` is intentionally stale (see ARCHITECTURE.md).

## Pull requests

1. Branch off `master`. `master` is the release branch; `dev` publishes
   prereleases on the `dev` npm channel.
2. Fill in `.github/PULL_REQUEST_TEMPLATE.md`.
3. `.github/CODEOWNERS` requests review from
   `@contentful/group-applied-ai-solutions` automatically.
4. CI on a PR is limited: the release job is skipped for non-`master`/`dev`
   pushes, and the CodeQL job only runs when files under `.github/workflows/`
   change. A green PR therefore does not mean your change was tested.

Merging to `master` triggers the release workflow, which publishes to npm
immediately. There is no manual release step.

## Reporting issues

Use the templates under `.github/ISSUE_TEMPLATE/`. Report security
vulnerabilities privately through
[GitHub security advisories](https://github.com/contentful/contentful-sdk-jsdoc/security/advisories/new)
rather than in a public issue.
