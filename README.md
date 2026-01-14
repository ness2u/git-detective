# git-detective

A tiny Bash tool to scan a workspace for Git repositories and show recent history for configured areas of interest (paths within those repos).

[![CI](https://github.com/ness2u/git-detective/actions/workflows/ci.yml/badge.svg)](https://github.com/ness2u/git-detective/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Install

- Requires: Bash 3.2+, git
- Optional: `yq` for YAML parsing (falls back to an awk/sed parser)

Clone or copy the two files into your workspace root:
- `git-detective.sh`
- `git-detective.yml`

Make the script executable:

```bash
chmod +x ./git-detective.sh
```

## Configure

Create `git-detective.yml` in the directory you run the script from (or pass `--config`):

```yaml
areas_of_interest:
  - services/api
  - apps/web/src
```

Each list item is a path relative to each repository root found under `--root`.
If that path exists in a repo, the script prints recent history for it.

## Usage

```bash
./git-detective.sh [--root DIR] [--config FILE] [--since RANGE] [--version]
```

Options:
- `--root DIR`    Root workspace directory to scan. Default: current directory
- `--config FILE` Path to YAML config. Default search: `./git-detective.yml` or `.yaml` in `--root` or CWD
- `--since RANGE` Git since range. Default: `2 weeks ago`. Examples: `2025-12-01`, `3 days ago`, `1 month ago`
- `--version`     Print version and exit

Examples:

```bash
# Scan your ~/git workspace using default config name in that folder
./git-detective.sh --root "$HOME/git"

# Use a specific config and show last 30 days
./git-detective.sh --root "$HOME/git" --config ./git-detective.yml --since "30 days ago"

# Show since a specific date
./git-detective.sh --root "$HOME/git" --since "2025-12-01"

# First run: scan repositories in the parent directory and include a common AOI
./git-detective.sh --root ../ --since "2 weeks ago"
```

## How it works

- Recursively finds all Git repositories under `--root` by locating `.git` directories.
- Reads `areas_of_interest` from YAML and treats each as a path relative to each repo root.
- If the path exists in a repo, prints `git log` since the provided range and a one-line summary of the latest change (author — message [date, sha]):
  - Directories: `git log -- <dir>`
  - Files: `git log --follow -- <file>` to include renames

If `yq` is installed, it will be used for YAML parsing. Otherwise, a small awk-based parser handles simple list values.

## Current state

- Version: 0.1.0
- Implemented: core scan, YAML parsing (yq or awk/sed), since-range filtering, latest summary per path, repo discovery, CI
- Example config: git-detective.yml
- Backlog: see todo.md
- Audit of decisions: see audit.md

## Contributing

Please see CONTRIBUTING.md and CODE_OF_CONDUCT.md.

## Security

See SECURITY.md. Do not open public issues with sensitive details.

## License

MIT (see LICENSE)
