# Agent Development Instructions

This repository uses Conventional Commits, semantic PR titles, and semantic-release. Future agent work must preserve those standards so releases and container image tags are generated correctly.

## Commit Standards

Use Conventional Commit messages for every commit:

```text
type(scope): short imperative summary
```

The scope is optional. Accepted types are `feat`, `fix`, `docs`, `test`, `ci`, `build`, `refactor`, `perf`, `style`, `chore`, and `revert`.

- `feat` creates a minor release.
- `fix` creates a patch release.
- A `BREAKING CHANGE` footer creates a major release.
- Other types normally do not publish a release.

## PR Titles and Releases

PR titles must use the same semantic format. Releases are generated from commits merged into `master`. Published images receive `X.Y.Z`, `X.Y`, `X`, and `latest` tags.

Before committing or opening a PR, run the relevant checks and document any test that could not be run.
