# scripts

Utility scripts for managing GitHub Actions secrets and project setup.

## push-secrets.sh

Reads a local `.secrets` file and pushes every key to a GitHub repo as either an Actions **secret** or a repo **variable**, using the [`gh` CLI](https://cli.github.com/).

### Convention

Lines annotated with `# var` are pushed as repo **variables** (`gh variable set`). Everything else is pushed as an encrypted **secret** (`gh secret set`).

```bash
# .secrets example

DIGITALOCEAN_ACCESS_TOKEN=dop_v1_abc123   # secret (default)
DOCR_REGISTRY=myregistry                  # var
```

Empty values are skipped, so you can leave placeholders in the file without accidentally overwriting existing secrets.

### Usage

```bash
# Push to current repo (detected from git remote)
./push-secrets.sh

# Push to a specific repo
./push-secrets.sh --repo owner/repo

# Use a different secrets file
./push-secrets.sh --secrets-file ~/secrets/myproject.secrets

# Combine
./push-secrets.sh --repo owner/new-project --secrets-file ~/secrets/myproject.secrets
```

### Setup for a project

1. Copy the project's `.secrets.example` to `.secrets` and fill in values.
2. Make sure `.secrets` is in your `.gitignore`.
3. Run the script.

```bash
cp .secrets.example .secrets
# edit .secrets
curl -fsSL https://raw.githubusercontent.com/cosmin-harangus/scripts/main/push-secrets.sh | bash -s -- --repo owner/myrepo --secrets-file .secrets
# or clone this repo and run directly:
./push-secrets.sh --repo owner/myrepo --secrets-file .secrets
```
