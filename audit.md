# Audit log (decisions and changes)

2026-01-14
- Initial implementation: git-detective.sh created (Bash 3.2+), README, example config
- YAML parsing strategy: prefer yq if available; fallback to awk/sed minimal list parser
- Repo discovery: find .git entries; portable array build (no mapfile) for macOS Bash 3.2
- Logging behavior: directories use `git log --`, files use `--follow`
- UX: added early checks, helpful usage, and section dividers
- Improvement: skip printing git log if no commits since range; added repo-name match to show entire repo history when AOI equals repo dir name
- Output: Latest summary line with author — subject [date, sha]
- Release: OSS scaffolding added (LICENSE, CI, CONTRIBUTING, SECURITY, COC, CHANGELOG); version 0.1.0; README badges
