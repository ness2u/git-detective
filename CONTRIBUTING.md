# Contributing to git-detective

Thanks for your interest in contributing! This is a small, portable Bash utility. Please keep portability (macOS Bash 3.2, Linux Bash 4+) in mind.

## Getting started
- Fork the repo and create a feature branch from `main`.
- Keep diffs small and focused.
- Follow the code style in AGENTS.md.
- Run linters before pushing:
  - shellcheck -S style git-detective.sh
  - shfmt -i 2 -ci -sr -w git-detective.sh

## Development tips
- Avoid non-portable Bash features (e.g., `mapfile`).
- Prefer standard POSIX tools; `yq` is optional.
- Document non-obvious regex/awk/sed choices in `audit.md`.

## Commit messages
- Use conventional-ish prefixes when it helps: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`.
- Reference issues where appropriate.

## Pull requests
- Describe the problem and the approach clearly.
- Include before/after examples when touching output.
- Update README, todo.md, and audit.md as needed.

## Reporting bugs
- Include OS, Bash version, and steps to reproduce.
- Share a minimal config (git-detective.yml) and the command you ran.

## Security
- Do not include sensitive information in issues.
- See SECURITY.md for reporting vulnerabilities.
