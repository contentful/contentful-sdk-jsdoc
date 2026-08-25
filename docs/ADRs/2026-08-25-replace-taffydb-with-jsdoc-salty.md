# Replace TaffyDB with `@jsdoc/salty` behind the existing `taffy` call surface

- **Date:** 2024-11-20 (decision), 2026-08-25 (record written)
- **Status:** Accepted

> This record was written on 2026-08-25 from the commit history. It documents an
> existing decision rather than a new one; the rationale below is reconstructed
> from the code and commit messages cited, not from a contemporaneous design
> discussion.

## Context

`jsdoc-template/publish.js` is a fork of the JSDoc 3 default template. That
template queries doclets through a TaffyDB collection, and `publish.js` uses the
`taffy()` constructor in six places to build the class, module, namespace, mixin,
external, and interface collections (`jsdoc-template/publish.js:616-621`), plus
the `TAFFY`-typed `taffyData` parameter of the exported `publish()` function
(`jsdoc-template/publish.js:407-413`).

JSDoc itself stopped providing that database, so commit `72d69d9` ("fix: add
taffydb dependency [NONE]", 2023-01-16) added `taffydb: ^2.7.3` as a direct
runtime dependency of this package to keep the template working. TaffyDB is
unmaintained. The upstream JSDoc project extracted its own replacement,
`@jsdoc/salty`, which intentionally re-exports a `taffy`-compatible constructor
for exactly this situation.

## Decision

Swap the runtime dependency from `taffydb` to `@jsdoc/salty` and adapt the
template with a single-line import change, keeping every call site untouched:

```js
// https://github.com/jsdoc/jsdoc/tree/main/packages/jsdoc-salty#use-salty-in-a-jsdoc-template
var taffy = require('@jsdoc/salty').taffy;
```

Evidenced by commit
`60fd93da69e2d6c0b62df1b5925b243f526d0b7d` ("fix: replace unmaintained taffydb
with jsdoc/salty [EXT-5968]"), which touches only `package.json` (removing
`taffydb`, adding `@jsdoc/salty: ^0.2.8`) and three lines of
`jsdoc-template/publish.js`. The `taffydb` entry was removed from `dependencies`
and `@jsdoc/salty` became the package's only runtime dependency.

The alternative — rewriting `publish.js` to use Salty's own API, or rebasing the
fork onto a current upstream template — was not taken.

## Consequences

- The package no longer depends on an unmaintained database library, and
  `@jsdoc/salty` is maintained by the JSDoc project itself, so it tracks JSDoc's
  own expectations for template data.
- The diff was three lines instead of a rewrite of a 681-line file that has no
  test coverage (`npm test` is `"true"`). Given the absence of tests, minimising
  the change was the only way to keep the risk containable.
- The template's vocabulary now lies about its implementation: the variable is
  still named `taffy`, and the JSDoc comment on `publish()` still documents a
  `{TAFFY}` parameter pointing at `taffydb.com`. Anyone reading `publish.js`
  will see TaffyDB references that no longer correspond to an installed package.
  The inline URL comment added by the commit is the only marker of the swap.
- The compatibility shim is load-bearing. If `@jsdoc/salty` ever drops its
  `taffy` export, all six call sites break at once, with no test to catch it.
