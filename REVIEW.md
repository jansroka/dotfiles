# Dotfiles Repository Review Summary

**Date:** January 28, 2026
**macOS Target:** Sequoia (15)
**Last Updated:** January 28, 2026

---

## Remaining Issues

| Priority | Category | Issue | Action |
|----------|----------|-------|--------|
| 🔴 HIGH | Python | Conflicting interpreter settings (ansible.cfg vs hosts) | Standardize to `/usr/bin/python3` |
| 🔴 HIGH | Project | Disabled roles (pip, docker) commented out | Delete completely or document clearly |
| � LOW | Documentation | Outdated Homebrew install URL in README | Update with current install command |
| 🟡 LOW | Practices | `ignore_errors: true` misuse | Use proper `failed_when` error handling |

---

## Completed Improvements

| Category | Issue | Solution | Status |
|----------|-------|----------|--------|
| Deprecated Syntax | Ansible `with_items` deprecated | Migrated to modern `loop` syntax (gem, npm, sublimetext, osx, duti) | ✅ Complete |
| YAML Formatting | Inconsistent file extensions (.yaml vs .yml) | Standardized duti handlers to .yml | ✅ Complete |
| Shell | NVM eager loading defeats lazy initialization | Removed duplicate NVM init at EOF, kept lazy-load only | ✅ Complete |
| Shell | Missing pyenv lazy initialization | Added pyenv lazy init matching rbenv pattern | ✅ Complete |
| Shell | Non-existent .bash_aliases reference | Removed reference (correct .aliases already symlinked) | ✅ Complete |
| Shell | PATH deduplication in wrong location | Moved to run AFTER all PATH modifications | ✅ Complete |
| Linting | No pre-commit configuration | Created `.pre-commit-config.yaml` with yamllint & file fixers | ✅ Complete |
| Linting | No YAML linting rules | Created `.yamllint` with 140 char limit, proper indentation | ✅ Complete |
| Linting | No Ansible linting config | Created `.ansible-lint` (disabled, ready for future) | ✅ Complete |
| YAML | Dock indentation errors | Fixed inconsistent indentation (1→2 spaces) | ✅ Complete |
| YAML | File ending issues | Normalized EOF on Docker, iTerm, Sublime, Zsh, UV files | ✅ Complete |
| Docs | Missing pre-commit docs | Updated README with setup, usage, and validation details | ✅ Complete |
| Docs | Outdated Homebrew installation URL | Updated to `/bin/bash` install script from brew.sh | ✅ Complete |
| Docs | Outdated setup.sh URL (master branch) | Updated to main branch | ✅ Complete |
| Homebrew | Outdated taps (bundle, services, microsoft/git) | Removed obsolete taps | ✅ Complete |
| Homebrew | python@3.9 EOL + missing uv package | Removed python@3.9, added uv | ✅ Complete |
| Homebrew | git-credential-manager-core renamed | Updated to git-credential-manager | ✅ Complete |
| Homebrew | Dockutil custom tap dependency | Removed from packages | ✅ Complete |
| macOS | Deprecated Safari settings code | Removed 20 lines of dead code | ✅ Complete |
| macOS | Dockutil external dependency | Replaced with native defaults write API | ✅ Complete |
| Paths | Hardcoded `/Users/jan/` paths | Use `{{ ansible_env.HOME }}` in iTerm, Hazel, Symlinks | ✅ Complete |
| Paths | Hardcoded hostname "Zeitgeist" | Made configurable `{{ osx_hostname }}` variable | ✅ Complete |

---

## Modernization Roadmap

| # | Item | Status |
|---|------|--------|
| 1 | Pre-commit hooks with yamllint | ✅ Complete |
| 2 | YAML validation and linting | ✅ Complete |
| 3 | Deprecated Ansible syntax removal | ✅ Complete |
| 4 | Shell initialization cleanup | ✅ Complete |
| 5 | Homebrew installation URL update | ✅ Complete |
| 6 | Ansible-lint configuration | ⏳ Ready (pending ansible module) |
| 7 | Python interpreter standardization | 🔴 Pending |
| 8 | Delete disabled roles (pip, docker) | 🔴 Pending |
| 9 | Error handling refactor | 🟠 Pending |

---

**Progress:** 22 items completed, 4 items remaining
