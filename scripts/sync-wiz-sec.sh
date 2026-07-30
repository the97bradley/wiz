#!/usr/bin/env bash
# Sync all public repositories from https://github.com/wiz-sec into wiz-sec/
# as git submodules. Safe to re-run: adds new repos and fast-forwards existing ones.
set -euo pipefail

ORG="${WIZ_SEC_ORG:-wiz-sec}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST_DIR="${ROOT_DIR}/wiz-sec"

cd "${ROOT_DIR}"

if ! command -v gh >/dev/null 2>&1; then
  echo "error: gh (GitHub CLI) is required" >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "error: git is required" >&2
  exit 1
fi

mkdir -p "${DEST_DIR}"

echo "==> Listing public repos in ${ORG}..."
# name, clone_url, default_branch, archived, fork
mapfile -t ALL_REPOS < <(
  gh api "orgs/${ORG}/repos" --paginate \
    --jq 'sort_by(.name)[] | "\(.name)\t\(.clone_url)\t\(.default_branch)\t\(.archived)\t\(.fork)"'
)

if [[ ${#ALL_REPOS[@]} -eq 0 ]]; then
  echo "error: no repositories found for org ${ORG}" >&2
  exit 1
fi

echo "==> Syncing ${#ALL_REPOS[@]} repositories into ${DEST_DIR}/"
added=0
updated=0

for entry in "${ALL_REPOS[@]}"; do
  IFS=$'\t' read -r name clone_url default_branch archived fork <<<"${entry}"
  path="wiz-sec/${name}"

  if [[ -d "${ROOT_DIR}/${path}/.git" ]] || git config -f .gitmodules --get-regexp "path" 2>/dev/null | grep -q " ${path}$"; then
    echo "--> Updating ${path} (${default_branch})..."
    if ! git submodule update --init --remote -- "${path}"; then
      if [[ ! -d "${ROOT_DIR}/${path}/.git" && ! -f "${ROOT_DIR}/${path}/.git" ]]; then
        rm -rf "${ROOT_DIR}/${path}"
        git submodule add -f -b "${default_branch}" "${clone_url}" "${path}"
        added=$((added + 1))
        continue
      fi
      echo "warn: failed to update ${path}" >&2
      continue
    fi
    git -C "${ROOT_DIR}/${path}" fetch origin "${default_branch}" --quiet
    git -C "${ROOT_DIR}/${path}" checkout -q "origin/${default_branch}"
    updated=$((updated + 1))
  else
    echo "--> Adding ${path}..."
    git submodule add -f -b "${default_branch}" "${clone_url}" "${path}"
    added=$((added + 1))
  fi
done

# Notice submodules that no longer exist upstream (do not auto-delete)
if [[ -f .gitmodules ]]; then
  while IFS= read -r existing_path; do
    existing_name="${existing_path#wiz-sec/}"
    found=0
    for entry in "${ALL_REPOS[@]}"; do
      IFS=$'\t' read -r name _ _ _ _ <<<"${entry}"
      if [[ "${name}" == "${existing_name}" ]]; then
        found=1
        break
      fi
    done
    if [[ "${found}" -eq 0 ]]; then
      echo "warn: ${existing_path} is no longer in ${ORG} (left in place; remove manually if desired)"
    fi
  done < <(git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | awk '{print $2}')
fi

# Refresh status snapshot for humans / agents
{
  echo "# wiz-sec sync status"
  echo
  echo "Last synced: $(date -u +%Y-%m-%d)"
  echo
  echo "| Repo | Default branch | Commit | Notes |"
  echo "|------|----------------|--------|-------|"
  for entry in "${ALL_REPOS[@]}"; do
    IFS=$'\t' read -r name clone_url default_branch archived fork <<<"${entry}"
    path="wiz-sec/${name}"
    sha="?"
    notes=""
    if [[ -e "${ROOT_DIR}/${path}/.git" || -d "${ROOT_DIR}/${path}" ]]; then
      sha="$(git -C "${ROOT_DIR}/${path}" rev-parse --short HEAD 2>/dev/null || echo '?')"
    fi
    [[ "${archived}" == "true" ]] && notes+="archived "
    [[ "${fork}" == "true" ]] && notes+="fork"
    notes="$(echo "${notes}" | xargs)"
    echo "| ${name} | ${default_branch} | \`${sha}\` | ${notes} |"
  done
  echo
  echo "Source org: https://github.com/${ORG}"
} > "${DEST_DIR}/SYNC_STATUS.md"

echo "==> Done. added=${added} updated=${updated}"
echo "    Stage submodule pointer changes with: git add wiz-sec .gitmodules"
