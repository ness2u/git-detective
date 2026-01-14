#!/usr/bin/env bash
set -euo pipefail

# git-detective.sh
# Scan a workspace for repositories containing configured areas of interest
# and print recent git history for those paths.
#
# Requirements: bash 3.2+, git. Optional: yq (if present, used for YAML parsing)

VERSION="0.1.0"

usage() {
  cat <<'USAGE'
Usage: git-detective.sh [--root DIR] [--config FILE] [--since RANGE] [--version]

Options:
  --root DIR      Root workspace directory to scan (default: current directory)
  --config FILE   YAML config file (default: ./git-detective.yml or .yaml)
  --since RANGE   Git since range (default: "2 weeks ago"). Examples:
                  "2025-12-01", "3 days ago", "1 month ago"
  --version       Print version and exit
  -h, --help      Show this help

Config format (YAML):
  areas_of_interest:
    - services/api
    - apps/web/src

Notes:
- Each area_of_interest is treated as a path RELATIVE to each repo root found
  under --root. If that path exists in a repo, history for that path is shown.
- Repositories are detected by locating .git directories or .git files (submodules/worktrees).
- If yq is installed, it will be used to read the YAML. Otherwise a minimal
  awk-based parser is used for the simple list under areas_of_interest.
USAGE
}

ROOT_DIR=$(pwd)
CONFIG=""
SINCE="2 weeks ago"
INIT_ROOT=false

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      ROOT_DIR=${2:-}
      shift 2
      ;;
    --config)
      CONFIG=${2:-}
      shift 2
      ;;
    --since)
      SINCE=${2:-}
      shift 2
      ;;
    --version)
      echo "git-detective $VERSION"
      exit 0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ ! -d "$ROOT_DIR" ]]; then
  echo "Error: --root directory not found: $ROOT_DIR" >&2
  exit 1
fi

# Resolve config path
if [[ -z "$CONFIG" ]]; then
  if [[ -f "$ROOT_DIR/git-detective.yml" ]]; then
    CONFIG="$ROOT_DIR/git-detective.yml"
  elif [[ -f "$ROOT_DIR/git-detective.yaml" ]]; then
    CONFIG="$ROOT_DIR/git-detective.yaml"
  elif [[ -f "$(pwd)/git-detective.yml" ]]; then
    CONFIG="$(pwd)/git-detective.yml"
  elif [[ -f "$(pwd)/git-detective.yaml" ]]; then
    CONFIG="$(pwd)/git-detective.yaml"
  else
    echo "Error: config file not found. Looked for git-detective.yml/.yaml under $ROOT_DIR and current directory." >&2
    exit 1
  fi
fi

if [[ ! -f "$CONFIG" ]]; then
  echo "Error: config not found: $CONFIG" >&2
  exit 1
fi

# Read areas_of_interest from YAML into bash array AOI[]
AOI=()
read_aoi_with_yq() {
  local cfg="$1"
  if command -v yq >/dev/null 2>&1; then
    # Prefer raw output (-r) if available (yq v4), otherwise strip quotes
    if yq eval -r '.areas_of_interest[]' "$cfg" >/dev/null 2>&1; then
      while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        AOI+=("$line")
      done < <(yq eval -r '.areas_of_interest[]' "$cfg" 2>/dev/null)
    else
      while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        AOI+=("$line")
      done < <(yq eval -o=json '.areas_of_interest[]' "$cfg" 2>/dev/null | sed -e 's/^"//' -e 's/"$//')
    fi
    return 0
  fi
  return 1
}

read_aoi_with_awk() {
  local cfg="$1"
  # Minimal YAML list parser for: areas_of_interest: [list]
  # Handles indentation and leading '-'. Quote stripping is handled outside.
  awk '
    BEGIN { in_list=0 }
    /^[[:space:]]*areas_of_interest:[[:space:]]*$/ { in_list=1; next }
    in_list == 1 && /^[[:space:]]*-/ {
      line=$0
      sub(/^[[:space:]]*-[[:space:]]*/, "", line)
      # trim surrounding spaces only
      gsub(/^[ \t]+|[ \t]+$/, "", line)
      if (length(line) > 0) print line
      next
    }
    # end list on next top-level key (word at col 1 followed by colon)
    /^[^[:space:]][^:]*:[[:space:]]*$/ { in_list=0 }
  ' "$cfg"
}

if ! read_aoi_with_yq "$CONFIG"; then
  while IFS= read -r item; do
    [[ -z "$item" ]] && continue
    # strip optional surrounding single/double quotes from the item (portable sed)
    item=$(printf '%s' "$item" | sed -E "s/^[[:space:]]*'([^']*)'[[:space:]]*$/\1/; s/^[[:space:]]*\"([^\"]*)\"[[:space:]]*$/\1/")
    AOI+=("$item")
  done < <(read_aoi_with_awk "$CONFIG")
fi

if [[ ${#AOI[@]} -eq 0 ]]; then
  echo "No areas_of_interest found in $CONFIG" >&2
  exit 1
fi

# Identify all repo roots under ROOT_DIR (portable without mapfile)
GIT_ENTRIES=()
while IFS= read -r -d '' entry; do
  GIT_ENTRIES+=("$entry")
done < <(find "$ROOT_DIR" -name .git -print0 2>/dev/null || true)

if [[ ${#GIT_ENTRIES[@]} -eq 0 ]]; then
  echo "No git repositories found under $ROOT_DIR" >&2
  exit 0
fi

print_divider() { printf '\n%s\n' "================================================================"; }

for git_entry in "${GIT_ENTRIES[@]}"; do
  repo_root=$(dirname "$git_entry")
  # Guard: .git may be nested inside worktree directories; try git to confirm
  if git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    :
  else
    continue
  fi

  for path in "${AOI[@]}"; do
    candidate="$repo_root/$path"
    if [[ -e "$candidate" ]]; then
      print_divider
      echo "Repository: $repo_root"
      echo "Path:       $path"
      echo "Since:      $SINCE"
      # Latest author/message summary
      if [[ -d "$candidate" ]]; then
        summary=$(git -C "$repo_root" log -n 1 --since="$SINCE" --date=short --format='%h|%ad|%an|%s' -- "$path" 2>/dev/null || true)
      else
        summary=$(git -C "$repo_root" log -n 1 --since="$SINCE" --date=short --format='%h|%ad|%an|%s' --follow -- "$path" 2>/dev/null || true)
      fi
      if [[ -n "${summary:-}" ]]; then
        h=${summary%%|*}; rest=${summary#*|}; ad=${rest%%|*}; rest=${rest#*|}; an=${rest%%|*}; s=${rest#*|}
        echo "Latest:    $an — $s [$ad, $h]"
        print_divider
        if [[ -d "$candidate" ]]; then
          git -C "$repo_root" log --date=short --decorate --oneline --since="$SINCE" -- "$path" || true
        else
          git -C "$repo_root" log --date=short --decorate --oneline --since="$SINCE" --follow -- "$path" || true
        fi
      else
        print_divider
        echo "No commits since $SINCE for $path"
      fi
    else
      # Fallback: if AOI equals the repository directory name, show entire repo history
      repo_name=$(basename "$repo_root")
      if [[ "$path" == "$repo_name" ]]; then
        print_divider
        echo "Repository: $repo_root"
        echo "Path:       (entire repo: $repo_name)"
        echo "Since:      $SINCE"
        summary=$(git -C "$repo_root" log -n 1 --since="$SINCE" --date=short --format='%h|%ad|%an|%s' -- . 2>/dev/null || true)
        if [[ -n "${summary:-}" ]]; then
          h=${summary%%|*}; rest=${summary#*|}; ad=${rest%%|*}; rest=${rest#*|}; an=${rest%%|*}; s=${rest#*|}
          echo "Latest:    $an — $s [$ad, $h]"
          print_divider
          git -C "$repo_root" log --date=short --decorate --oneline --since="$SINCE" -- . || true
        else
          print_divider
          echo "No commits since $SINCE in this repo"
        fi
      fi
    fi
  done

done
