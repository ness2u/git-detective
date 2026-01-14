AGENTS.md — Operating Guide for Agentic Coding in this Repository

Scope
- This repository hosts a portable Bash utility (git-detective.sh) with a small supporting set of docs and a YAML config. There is no Node/Poetry/Cargo toolchain and no test harness present by default. Treat this as a shell-first project.

Repository layout
- git-detective.sh — main script
- git-detective.yml — example configuration (areas_of_interest)
- README.md — usage and configuration
- todo.md — backlog of future work
- audit.md — log of past decisions and rationale
- .git/ — initialized local repository

1) Build / lint / test commands

There is no language-specific build system. Use the following commands to maintain quality and perform checks.

Shell linting (recommended):
- If shellcheck is installed:
  - shellcheck -S style git-detective.sh
  - Suggested CI target: shellcheck -S warning git-detective.sh
- If shfmt is installed (formatting):
  - shfmt -i 2 -ci -sr -w git-detective.sh

POSIX/Bash compatibility checks:
- macOS Bash 3.2 compatibility: run the script on macOS default Bash (no mapfile, etc.)
- GNU/Linux Bash 4+: standard run

Execution smoke tests:
- From repo root:
  - chmod +x ./git-detective.sh
  - ./git-detective.sh --root "$HOME/git" --since "2 weeks ago"
- From repo root targeting parent (first-run guidance):
  - ./git-detective.sh --root ../ --since "2 weeks ago"

Single-path targeted test (ad-hoc):
- Use a minimal config listing a single AOI path, then run:
  - ./git-detective.sh --root <some-root> --config ./git-detective.yml --since "3 days ago"
- Example YAML:
  areas_of_interest:
    - super-gource

Simulating a single “test case”
- There is no formal test framework here. To test one scenario, narrow AOI and limit since-range to a small window. If needed, create a tiny fixture repo with a few commits and run the script against it.

Exit codes and expectations
- Non-zero exits occur when:
  - --root not found
  - Config file not found or AOI empty
- Normal operation prints summaries and logs; repositories without commits since range print “No commits since …”.

2) Code style guidelines

General style
- Interpreter: #!/usr/bin/env bash
- Options: set -euo pipefail
- Target environments: Bash 3.2 (macOS) and Bash 4+ (Linux)
- Avoid non-portable builtins (e.g., mapfile) to maintain macOS compatibility
- Prefer small, readable functions with single purpose

Imports / external tools
- Required: git
- Optional: yq (preferred if present), otherwise rely on awk/sed fallback
- Avoid introducing new tool dependencies casually; prefer standard POSIX tools

Formatting
- Indentation: 2 spaces, no tabs
- Keep lines reasonably short; wrap heredocs and long commands
- Group related flags in multi-line invocations when readability benefits

Quoting and whitespace
- Always double-quote variable expansions: "$var"
- Use IFS-safe reads (while IFS= read -r line)
- Trim input via sed/awk only when necessary and document intent briefly

Arrays and loops
- Use portable patterns compatible with Bash 3.2 (avoid mapfile)
- Build arrays via while-read loops or explicit appends
- Iterate with for x in "${arr[@]}"; do ...; done

Types and naming
- Variables: UPPER_CASE for constants/options, lower_snake for locals
- Functions: lower_snake, keep short and verb-noun where possible (e.g., read_aoi_with_awk)
- Avoid one-letter names except for very local loop counters or decomposed tuple parts (e.g., h, an, s for parsed fields)

Error handling
- Fail fast (set -e) but guard non-critical commands with || true when output is non-fatal
- Print actionable error messages to stderr (echo "..." >&2)
- Prefer early returns over deep nesting inside functions

Input parsing
- Use a case/esac loop for CLI options; on unknown args, print usage and exit 1
- Provide defaults for optional flags
- Validate directories and files immediately after parsing

YAML parsing
- Prefer yq if available:
  - yq eval -r '.areas_of_interest[]' <config>
- Fallback: awk to detect the list under areas_of_interest, stripping the dash and trimming whitespace; then sed to strip optional surrounding quotes
- Keep fallback simple—complex YAML is out of scope; document expectations in README

Git usage
- Use git -C <repo> to operate from a discovered repository root
- For files, use --follow when showing logs to capture rename history
- To avoid fatal messages for empty repos or no recent commits:
  - Probe via rev-list or log -n 1; print a friendly message instead of raw errors

Logging and output
- Show a header per (repo, path): Repository, Path, Since
- Print a Latest: <author> — <message> [<date>, <sha>] summary if available, then oneline log entries since the range
- If no commits, print: No commits since <range> for <path>
- Separate sections with a visible divider line

Performance
- Use find -name .git -print0 with a null-delimited read loop (portable) rather than mapfile
- Avoid scanning unnecessary large paths by narrowing AOI; consider future flags for include/exclude patterns

Security and safety
- Do not execute untrusted data; this tool reads and prints git history
- Avoid eval; avoid parsing with unsafe regexes; quote all expansions

Repository conventions
- Keep script changes minimal and focused—bug fixes should not refactor unrelated sections
- Document non-obvious regex or portability decisions directly in audit.md or brief inline comments
- Update README Current state, todo.md backlog, and audit.md when behavior changes

Cursor / Copilot rules
- No .cursor/rules or .cursorrules present
- No .github/copilot-instructions.md present
- If these are added in the future, update this AGENTS.md with a summary and link to the authoritative rules

Contribution workflow (agents)
- Before edits: skim README, todo.md, audit.md to understand current state
- When making non-trivial changes:
  - Propose or plan with a short checklist (todo items)
  - Keep portability (Bash 3.2) constraints in mind
  - Prefer small diffs; match existing style and patterns
- After changes:
  - Smoke test on a realistic root (e.g., ../) with a tight --since window
  - If adding dependencies, justify in audit.md and update README/todo
- Documentation:
  - Update README “Current state” and add decisions to audit.md
  - Update todo.md for new backlog items; mark completed work

Single-test guidance (shell context)
- Since there’s no test framework, simulate a single test by:
  1) Creating a temporary mini-repo with a known history affecting one AOI path
  2) Point --root to that repo and set --since to include only one commit
  3) Validate that the output shows the expected Latest summary and the expected oneline log

Future testing direction
- If a test harness is introduced, prefer Bats (https://github.com/bats-core/bats-core):
  - bats test/<name>.bats
  - bats --filter <pattern> test
- Shell lint in CI: shellcheck + shfmt

Contacts and scope of authority (for agents)
- Agents may create or update small shell utilities and docs without prior approval
- Never commit secrets or modify user git config
- For major changes (new language, dependencies, or architecture), propose in todo.md and audit.md first, then proceed after approval
