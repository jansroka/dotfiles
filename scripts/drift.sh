#!/usr/bin/env bash
#
# Report drift between this Mac and the package lists in roles/brew and roles/mas.
# Read-only: it never installs or removes anything.
# Exit code: 0 = in sync, 1 = drift found.
#
# Usage: scripts/drift.sh

set -euo pipefail
export LC_ALL=C # comm needs byte-order sorting

cd "$(dirname "$0")/.."
BREW_VARS=roles/brew/defaults/main.yml
MAS_VARS=roles/mas/defaults/main.yml
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
drift=0

# Print a section only when it has lines; every printed section counts as drift.
section() {
  [[ -s $2 ]] || return 0
  drift=1
  printf '\n== %s\n' "$1"
  sed 's/^/  /' "$2"
}

# --- Gather -----------------------------------------------------------------
# Tap prefixes (heroku/brew/heroku) are stripped so names compare with `brew leaves`.
yq '.brew_packages[]' "$BREW_VARS" | sed 's#.*/##' | sort -u >"$tmp/want_formulae"
yq '.brew_cask_packages[], .brew_cask_ql_packages[]' "$BREW_VARS" | sort -u >"$tmp/want_casks"
brew leaves --installed-on-request | sed 's#.*/##' | sort -u >"$tmp/have_formulae"
brew list --formula -1 | sed 's#.*/##' | sort -u >"$tmp/all_formulae"
brew list --cask -1 | sort -u >"$tmp/have_casks"
brew info --json=v2 --installed >"$tmp/installed.json"

yq '.mas_installed_apps[].id' "$MAS_VARS" | sort -u >"$tmp/want_mas"
yq '.mas_uninstalled_apps[].id' "$MAS_VARS" | sort -u >"$tmp/unwanted_mas"
mas list >"$tmp/mas_list"
awk '{print $1}' "$tmp/mas_list" | sort -u >"$tmp/have_mas"

find /Applications -maxdepth 1 -name '*.app' -exec basename {} \; |
  sort -u >"$tmp/apps"

# --- Brew -------------------------------------------------------------------
comm -23 "$tmp/want_formulae" "$tmp/all_formulae" >"$tmp/out"
section "Formulae listed but not installed" "$tmp/out"

comm -13 "$tmp/want_formulae" "$tmp/have_formulae" >"$tmp/out"
section "Formulae installed on request but not listed" "$tmp/out"

comm -23 "$tmp/want_casks" "$tmp/have_casks" >"$tmp/out"
section "Casks listed but not installed" "$tmp/out"

comm -13 "$tmp/want_casks" "$tmp/have_casks" >"$tmp/out"
section "Casks installed but not listed" "$tmp/out"

# A listed name that appears as an old name of an installed package was renamed upstream.
jq -r '(.formulae[] | .name as $n | .oldnames[]? | "\(.) \($n)"),
       (.casks[] | .token as $n | .old_tokens[]? | "\(.) \($n)")' "$tmp/installed.json" |
  sort >"$tmp/renames"
cat "$tmp/want_formulae" "$tmp/want_casks" | sort -u |
  join - "$tmp/renames" | awk '{print $1 " -> " $2}' >"$tmp/out"
section "Listed under an old name (rename in $BREW_VARS)" "$tmp/out"

# Formulae only when installed on request: a deprecated dependency is not yours to act on.
jq -r '(.formulae[] | select(any(.installed[]; .installed_on_request)) | {n: .name, d: .deprecated, x: .disabled, r: (.disable_reason // .deprecation_reason)}),
       (.casks[] | {n: .token, d: .deprecated, x: .disabled, r: (.disable_reason // .deprecation_reason)})
       | select(.d or .x)
       | "\(.n) (\(if .x then "disabled" else "deprecated" end): \(.r // "no reason given"))"' \
  "$tmp/installed.json" | sort >"$tmp/out"
section "Installed but deprecated or disabled upstream" "$tmp/out"

# App names a cask installs: `app` artifacts (target name wins) plus /Applications paths
# in uninstall/zap stanzas, which is how pkg casks like microsoft-office declare theirs.
jq -r '.casks[] | [.token,
         ([.artifacts[] | .app? // empty | (map(objects.target)[0] // map(strings)[0]) | split("/")[-1]]
          + [.artifacts[] | (.uninstall? // .zap? // empty) | .. | strings
             | select(test("^/Applications/[^/]+\\.app$")) | split("/")[-1]]
         | unique | join("|"))] | @tsv' "$tmp/installed.json" >"$tmp/cask_apps"

: >"$tmp/out"
: >"$tmp/owned"
while IFS=$'\t' read -r token apps; do
  [[ -n $apps ]] || continue
  found=0
  IFS='|' read -ra list <<<"$apps"
  for app in "${list[@]}"; do
    echo "$app" >>"$tmp/owned"
    grep -qxF "$app" "$tmp/apps" && found=1
  done
  ((found)) || echo "$token (expects ${apps//|/, })" >>"$tmp/out"
done <"$tmp/cask_apps"
section "Casks whose app is gone (uninstall the cask)" "$tmp/out"

# --- Mac App Store ----------------------------------------------------------
comm -23 "$tmp/want_mas" "$tmp/have_mas" >"$tmp/out"
section "MAS apps listed but not installed (ids)" "$tmp/out"

comm -13 "$tmp/want_mas" "$tmp/have_mas" | grep -Fwf - "$tmp/mas_list" >"$tmp/out" || true
section "MAS apps installed but not listed" "$tmp/out"

comm -12 "$tmp/unwanted_mas" "$tmp/have_mas" | grep -Fwf - "$tmp/mas_list" >"$tmp/out" || true
section "MAS apps marked for removal but installed" "$tmp/out"

# --- Unmanaged apps ---------------------------------------------------------
# MAS names match app names closely enough; Safari ships with macOS.
sed -E 's/^ *[0-9]+ +//; s/ +\([^)]*\)$//; s/$/.app/' "$tmp/mas_list" >>"$tmp/owned"
echo "Safari.app" >>"$tmp/owned"
sort -u "$tmp/owned" -o "$tmp/owned"

: >"$tmp/out"
comm -23 "$tmp/apps" "$tmp/owned" | while read -r app; do
  # shortcut: guesses the cask from the app name only, misses casks named differently.
  guess=$(basename "$app" .app | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9.-')
  # pkg casks (google-drive, veracrypt) declare no app path, so an installed match counts as owned.
  if grep -qxF "$guess" "$tmp/have_casks"; then
    continue
  elif brew info --cask "$guess" >/dev/null 2>&1; then
    echo "${app%.app} (cask: $guess)"
  else
    echo "${app%.app}"
  fi
done >"$tmp/out"
section "Apps not installed by brew or mas" "$tmp/out"

if ((drift)); then
  exit 1
fi
echo "In sync."
