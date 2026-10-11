#!/usr/bin/env bash
#
# Bootstrap a fresh Mac and run the dotfiles playbook.
# Safe to re-run: every step checks its own state before acting.
#
# Usage: curl -L https://raw.githubusercontent.com/jansroka/dotfiles/main/setup.sh | bash

set -euo pipefail

DOTFILES_DIR="$HOME/Code/Private/dotfiles"
DOTFILES_REPO="https://github.com/jansroka/dotfiles.git"
BREW_BIN="/opt/homebrew/bin/brew"
BREW_SHELLENV="eval \"\$($BREW_BIN shellenv)\""

# Everything runs inside main(), which is only called on the last line.
# When piped via `curl | bash`, bash reads the script from stdin as it goes;
# without this wrapper, any child that reads stdin would swallow the rest
# of the script, and a truncated download would execute half a script.
main() {
  echo "[i] Ask for sudo password"
  sudo -v

  # /usr/bin/gcc is a stub that exists even without the tools installed,
  # so ask xcode-select whether the tools are actually there.
  if ! xcode-select -p >/dev/null 2>&1; then
    echo "[i] Install macOS Command Line Tools"
    xcode-select --install
    echo "[i] Waiting for the Command Line Tools installer to finish"
    until xcode-select -p >/dev/null 2>&1; do
      sleep 5
    done
  fi

  if [[ ! -x "$BREW_BIN" ]]; then
    echo "[i] Install Homebrew"
    # get this from https://brew.sh/
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # Add Homebrew to $PATH for future login shells, once.
  if ! grep -qsF "$BREW_SHELLENV" "$HOME/.zprofile"; then
    echo "[i] Add Homebrew to ~/.zprofile"
    printf '\n%s\n' "$BREW_SHELLENV" >>"$HOME/.zprofile"
  fi
  eval "$("$BREW_BIN" shellenv)"

  if ! command -v ansible-playbook >/dev/null 2>&1; then
    echo "[i] Install Ansible"
    brew install ansible
  fi

  if [[ -d "$DOTFILES_DIR/.git" ]]; then
    echo "[i] Pull dotfiles repo from GitHub"
    git -C "$DOTFILES_DIR" pull --ff-only origin main
  elif [[ -e "$DOTFILES_DIR" && -n "$(ls -A "$DOTFILES_DIR")" ]]; then
    echo "[!] $DOTFILES_DIR exists and is not a git repo; refusing to overwrite it" >&2
    exit 1
  else
    echo "[i] Clone dotfiles repo"
    mkdir -p "$(dirname "$DOTFILES_DIR")"
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi

  cd "$DOTFILES_DIR"

  echo "[i] Install Ansible collections"
  ansible-galaxy collection install -r requirements.yml

  echo "[i] Run playbook"
  time ansible-playbook -i hosts dotfiles.yml -v --ask-become-pass

  echo "[i] Done."
}

main "$@"
