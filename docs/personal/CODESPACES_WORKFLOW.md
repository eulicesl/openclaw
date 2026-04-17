# Personal Codespaces Workflow

This file is fork-only guidance for Eulices's `eulicesl/openclaw` fork.
It is **not** intended for upstream contribution.

## Branch roles

- `main`
  - Clean mirror of `openclaw/openclaw:main`
  - Do not keep personal environment changes here

- `personal/codespaces-base`
  - Personal cloud-dev base branch
  - Contains the fork-only Codespaces/devcontainer setup
  - Safe to use as the starting point for working in GitHub Codespaces

## Recommended workflow

### Open a cloud dev environment

Use GitHub Codespaces on:

- `personal/codespaces-base`

### Start personal cloud work

```bash
git checkout personal/codespaces-base
git pull --ff-only origin personal/codespaces-base
git checkout -b <feature-branch>
```

### When preparing an upstream PR

Do **not** send the personal Codespaces commit upstream.
Before opening an upstream PR, rebase or cherry-pick your actual feature work onto clean `main`.

Example:

```bash
git checkout main
git pull --ff-only origin main
git checkout -b feature/<name>
# cherry-pick or re-implement only the real feature commits
```

## Quick reminder

- Codespaces convenience lives on `personal/codespaces-base`
- Upstream parity lives on `main`
- Upstream contributions should be based on clean `main`, not the personal Codespaces branch
