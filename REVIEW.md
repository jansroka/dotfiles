# Dotfiles Repository Comprehensive Review

**Date:** January 28, 2026  
**macOS Target:** Sequoia (15)  
**Review Focus:** Inconsistencies, outdated practices, and areas for improvement

---

## Critical Issues

### 1. **Python Interpreter Conflict in ansible.cfg**
**Severity:** HIGH  
**Location:** [ansible.cfg](ansible.cfg#L14)

```properties
ansible_python_interpreter=/Users/jan/.pyenv/shims/python
```

**Issue:** This hardcodes a user-specific path that won't work for other users (if repo is shared) and may fail if pyenv is not initialized. However, the [hosts](hosts) file uses:
```plaintext
ansible_python_interpreter=/usr/bin/python3
```

**Problems:**
- Conflicting Python interpreter settings (ansible.cfg vs hosts)
- Hard-coded user path reduces portability
- pyenv shims might not be initialized on fresh installs

**Recommendation:** Use `/usr/bin/python3` (system Python) or ensure consistent configuration. If using pyenv is important, add initialization checks.

---

### 2. **Disabled Roles with No Migration Path**
**Severity:** HIGH  
**Location:** [dotfiles.yml](dotfiles.yml)

```yaml
# update: 2024-09-28: role commented out because I use pyenv now
# - role: pip
#   tags: pip

# update: 2024-01-04: role commented out because of issues with my python setup
# - role: docker
#  tags: docker
```

**Problems:**
- Commented code with old comments (2024) but no clear status
- No `pip` management despite using `pipx` in brew packages
- No clear indication whether these should be deleted or will be re-enabled
- Docker role permanently disabled but still exists in `roles/docker/`

**Recommendation:** 
- Either delete unused roles completely or document their deprecated status clearly
- Document why `pip` role is disabled and what manages Python packages now (pyenv + pipx?)
- Update comments with current reasoning (not 2024 dates)

---

## Ansible & YAML Issues

### 3. **Deprecated Ansible Module Usage**
**Severity:** MEDIUM  
**Location:** Multiple files

The codebase uses older `with_items` syntax which is deprecated:

```yaml
with_items:
  - {key: "tilesize", type: "float", value: "70"}
```

**Better Modern Syntax:**
```yaml
loop:
  - key: tilesize
    type: float
    value: 70
```

**Affected Files:**
- [roles/dock/tasks/main.yml](roles/dock/tasks/main.yml) - `with_items`
- [roles/osx/tasks/defaults.yml](roles/osx/tasks/defaults.yml) - `with_items` (8+ instances)
- [roles/iterm/tasks/main.yml](roles/iterm/tasks/main.yml) - `with_items`
- Multiple other roles

**Recommendation:** Migrate all `with_items` to `loop` for consistency with Ansible best practices.

---

### 4. **Inconsistent YAML Formatting**
**Severity:** LOW  
**Location:** Multiple files

**Issues Found:**
- Inconsistent quotes in defaults: `"tilesize"` vs `tilesize` in nested dicts
- Mixed approaches: Some use `community.general.osx_defaults`, others use full module paths
- [roles/duti/handlers/main.yaml](roles/duti/handlers/main.yaml) uses `.yaml` extension while others use `.yml`

---

### 5. **Outdated Homebrew Taps**
**Severity:** MEDIUM  
**Location:** [roles/brew/defaults/main.yml](roles/brew/defaults/main.yml)

```yaml
brew_taps:
  - heroku/brew
  - homebrew/bundle
  - homebrew/services
  - microsoft/git
```

**Issues:**
- `homebrew/bundle` and `homebrew/services` are now part of core Homebrew (no longer needed as taps)
- `microsoft/git` is outdated; Git comes via standard Homebrew now
- `heroku/brew` still valid but should verify if it's still maintained

---

### 6. **Missing or Outdated Homebrew Packages**
**Severity:** MEDIUM  
**Location:** [roles/brew/defaults/main.yml](roles/brew/defaults/main.yml)

**Issues:**
- **`python@3.9`** - This is very outdated (EOL since October 2022). Should remove or upgrade to `python@3.11` or `python@3.12`
- **`lotyp/formulae/dockutil`** - This custom tap may not be needed; check if `dockutil` is available in core Homebrew now
- **`git-credential-manager-core`** - Renamed to `git-credential-manager` in newer versions
- **`nvm`** - Installing via Homebrew is discouraged; direct installation is preferred
- **`nodejs`** - Missing from list but npm role exists. Node management unclear (nvm vs system)
- **`rbenv`** + **`ruby-build`** - Good, but ensure Ruby setup is documented

**Missing Modern Tools:**
- No mention of **`uv`** (modern Python package manager, better than pip/pipx)
- No **`mise`** or **`asdf`** (modern alternative to nvm/rbenv/pyenv)
- No **`direnv`** (load env vars per-directory)

---

### 7. **Hardcoded User Path Issues**
**Severity:** MEDIUM  
**Location:** Multiple files

```bash
# roles/iterm/tasks/main.yml
defaults write com.googlecode.iterm2 'PrefsCustomFolder' -string '/Users/jan/...'

# roles/hazel/tasks/main.yml
value: "~/Code/Private/dotfiles/roles/hazel/files"

# roles/symlinks/defaults/main.yml
symlinks_files_src_dir: "~/Code/Private/dotfiles/roles/symlinks/files"

# roles/osx/tasks/base.yml
value: "Zeitgeist"  # hardcoded hostname
```

**Problems:**
- `/Users/jan/` hardcoded in iTerm config (not portable)
- Hostname hardcoded as "Zeitgeist" - only works for this user's specific setup
- Not all use tilde expansion consistently

**Recommendation:** Use Ansible variables (`{{ ansible_env.HOME }}`, `{{ ansible_user_id }}`) instead of hardcoded paths.

---

## macOS-Specific Issues

### 8. **Deprecated macOS Features & Removed Preferences**
**Severity:** MEDIUM  
**Location:** [roles/osx/tasks/defaults.yml](roles/osx/tasks/defaults.yml)

```yaml
# Commented out because "this currently does not work on OSX Sonoma"
# - name: Set Safari settings
#   community.general.osx_defaults: domain=com.apple.Safari
```

**Issues:**
- Safari defaults commented with note about Sonoma (2023), but we're now on Sequoia (2024)
- Need to verify if these work now, or document why they're permanently broken
- Some `osx_defaults` may not work on Sequoia:
  - Dashboard settings might be outdated (Dashboard removed in some versions)
  - Mission Control animations may have changed

**Recommendation:** Test Safari settings on Sequoia and uncomment if working, or document permanent incompatibilities.

---

### 9. **Deprecated macOS Tools**
**Severity:** LOW  
**Location:** Various

- **`bsdtar` / **`tar`** - Modern alternatives exist
- **`Transmission` settings** - Transmission may not work properly on Sequoia (check if abandoned)
- **`dockutil`** - Functionality may be partially deprecated; Apple's native APIs are preferred

---

### 10. **Shell Initialization Issues**
**Severity:** MEDIUM  
**Location:** [roles/symlinks/files/zsh/zshrc](roles/symlinks/files/zsh/zshrc)

**Issues Found:**

1. **Mixed NVM initialization** - NVM is loaded lazily AND eagerly:
```bash
_init_nvm() { ... }  # Lazy init
nvm() { _init_nvm; ... }  # First-use init

# ... later ...

# Initialize NVM eagerly for node availability
if [ -d "$_BREW_PREFIX/opt/nvm" ]; then
  [ -s "$_BREW_PREFIX/opt/nvm/nvm.sh" ] && \. ...  # Eager init again!
fi
```

This defeats the purpose of lazy loading and will slow down shell startup.

2. **Non-existent sourcing:**
```bash
# Source bash aliases for compatibility
[ -f ~/.bash_aliases ] && source ~/.bash_aliases
```
File `~/.bash_aliases` doesn't exist (but `~/.aliases` does from symlinks).

3. **Custom commands without versioning:**
```bash
# Basic Memory - Use Python 3.13 to avoid Pydantic warnings
bm() { uvx --python python3.13 basic-memory "$@"; }
```
Requires `uvx` (uv package manager) but not in brew packages list.

4. **Pyenv not initialized** - Similar to rbenv, but only rbenv has lazy loading.

5. **Deduplication at end** - Good practice, but happens AFTER all the manual PATH manipulation above.

---

### 11. **Inconsistent Shell Setup**
**Severity:** MEDIUM  
**Location:** Multiple shell files

**Issues:**
- `bash_profile`, `bashrc`, `exports`, `prompt` all symlinked but zsh setup is incomplete
- No `zshenv` or `zshrc.local` for user customizations
- `.aliases` referenced but bash uses `.bash_aliases` inconsistently
- Comment in zshrc mentions "bash aliases" but this is a zsh file

---

## Missing or Incomplete Features

### 12. **No Git Signing Key Management**
**Severity:** LOW  
**Location:** [roles/symlinks/files/git/gitconfig](roles/symlinks/files/git/gitconfig)

```properties
[commit]
	gpgsign = true
[user]
	signingkey = 08ECE799  # Incomplete key (should be full fingerprint)
```

**Issues:**
- Signing key is incomplete (8 hex digits vs 40 for full fingerprint)
- No GPG key import/creation in Ansible (assumes key exists)
- No documentation on how to set up GPG signing

---

### 13. **No Configuration Validation or Linting Setup**
**Severity:** MEDIUM  
**Location:** Project root

**Missing Files:**
- `.ansible-lint` - No ansible-lint configuration
- `.yamllint` - No yaml-lint configuration  
- `.pre-commit-config.yaml` - README mentions pre-commit but no config file exists!
- No GitHub Actions or CI/CD for validation

**Note:** README explicitly mentions:
> "I am using `pre-commit` in this repo to lint before commits."

But `.pre-commit-config.yaml` doesn't exist!

---

### 14. **No Test/Validation Strategy**
**Severity:** MEDIUM  

**Issues:**
- No way to validate playbooks before running them
- No `ansible-playbook --syntax-check` mentioned
- No dry-run instructions documented
- No rollback/recovery documented

---

### 15. **macOS Application Bundle Changes Not Handled**
**Severity:** LOW  
**Location:** [roles/dock/defaults/main.yml](roles/dock/defaults/main.yml)

```yaml
- name: "Visual Studio Code"
  path: "/Applications/Visual\ Studio\ Code.app/"
```

**Issues:**
- Hardcoded application paths (not portable if apps installed elsewhere)
- No verification that apps exist before adding to dock
- Path quoting inconsistent: some use backslash, Visual Studio Code uses backslash but could use quotes

---

## Documentation Issues

### 16. **Outdated Setup Instructions**
**Severity:** MEDIUM  
**Location:** [README.md](README.md)

**Issues:**
1. Homebrew installation URL is outdated:
   ```bash
   ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
   ```
   Should be: `/bin/bash -c "$(curl -fsSL https://brew.sh/install.sh)"`

2. Setup script mentions outdated GitHub URLs (`master` branch reference)

3. No mention of Apple Silicon vs Intel support (M1/M2/M3 differences)

4. No documentation on:
   - Prerequisites (Xcode Command Line Tools, git, curl)
   - Supported macOS versions (Sequoia only? Or also Sonoma?)
   - Ansible version requirements
   - Expected run time

---

### 17. **Poor Comments & Documentation**
**Severity:** LOW  
**Location:** Multiple files

```yaml
# from https://github.com/geerlingguy/ansible-collection-mac
# from https://github.com/elnappo/dotfiles/blob/master/ansible/tasks/macos_defaults.yml
# This is not a work of art, but out of necessity. I know this can be made much nicer
```

**Issues:**
- Self-critical comments that should be refactored instead
- External references to other repos that may have changed
- Outdated comments (2024 dates on currently maintained code)

---

## Best Practices Missing

### 18. **No Error Handling Strategy**
**Severity:** LOW  
**Location:** Multiple roles

Uses `ignore_errors: true` multiple times without justification:
```yaml
- name: Install Homebrew casks (skip if already installed)
  ignore_errors: true
  when: item not in brew_cask_output.stdout
```

**Issues:**
- Ignores all errors indiscriminately
- Better approach: check if cask exists first, or use `failed_when` for specific errors

---

### 19. **Inefficient Package Checking**
**Severity:** MEDIUM  
**Location:** [roles/brew/tasks/main.yml](roles/brew/tasks/main.yml)

```yaml
- name: Get list of already installed Homebrew formulae
  ansible.builtin.command: brew leaves
  register: brew_output

- name: Install Homebrew formulae (skip if already installed)
  loop: "{{ brew_packages }}"
  when: item not in brew_output.stdout  # String searching is fragile!
```

**Issues:**
- Runs `brew leaves` only once, but results used in loop
- String searching (`item not in stdout`) is fragile and error-prone
  - Example: If "git" is installed and you search for "gits", it will match!
- Better: Use Ansible's built-in package module which handles this

**Recommendation:**
```yaml
- name: Install Homebrew packages
  community.general.homebrew:
    name: "{{ brew_packages }}"
    state: present
```
This is idempotent and doesn't require manual checking.

---

### 20. **Incomplete Idempotency**
**Severity:** MEDIUM  
**Location:** Multiple roles

Some tasks are not idempotent:
```yaml
- name: Remove all dock items
  ansible.builtin.shell: "dockutil --remove all --no-restart"

- name: Add our dock items  
  ansible.builtin.shell: "dockutil --add '{{ item.path }}' ..."
```

**Issues:**
- Removing all dock items every run is destructive
- Better: Check current state and only modify if different

---

## Security Concerns

### 21. **Git Credential Storage Method**
**Severity:** LOW  
**Location:** [roles/symlinks/files/git/gitconfig](roles/symlinks/files/git/gitconfig)

```properties
[credential]
	helper = osxkeychain
	helper = /usr/local/share/gcm-core/git-credential-manager
```

**Issues:**
- No validation that git-credential-manager is installed
- Mixed credential helpers (osxkeychain + GCM) - unnecessary
- No SSH key setup documented

---

### 22. **No Sensitive Data Protection**
**Severity:** LOW

**Issues:**
- dotfiles repo stored in version control with user-specific paths
- No `.gitignore` entries for sensitive files
- No secrets management strategy

---

## Summary of Required Actions

| Priority | Category | Issue | Action |
|----------|----------|-------|--------|
| 🔴 HIGH | Python | Conflicting interpreter settings | Standardize to `/usr/bin/python3` |
| 🔴 HIGH | Project | Disabled roles with no status | Delete or document clearly |
| 🟠 MEDIUM | Ansible | `with_items` deprecated syntax | Migrate all to `loop` |
| 🟠 MEDIUM | Homebrew | Outdated package versions | Update python@3.9 → 3.12 |
| 🟠 MEDIUM | Homebrew | Unnecessary taps | Remove bundle/services/microsoft-git |
| 🟠 MEDIUM | macOS | Shell initialization conflicts | Fix NVM double-loading |
| 🟠 MEDIUM | Setup | Missing pre-commit config | Create `.pre-commit-config.yaml` |
| 🟠 MEDIUM | Paths | Hardcoded user paths | Use Ansible variables |
| 🟡 LOW | Documentation | Outdated brew install URL | Update README |
| 🟡 LOW | Practices | `ignore_errors` misuse | Use proper error handling |
| 🟡 LOW | Efficiency | String-based package checking | Use Ansible's native modules |
| 🟡 LOW | macOS | Broken Safari settings | Test and uncomment or remove |

---

## Recommendations for Modernization

1. **Switch to UV** instead of pip/pipx for Python package management
2. **Use mise or asdf** instead of nvm/rbenv/pyenv for language version management
3. **Implement pre-commit hooks** with actual config file
4. **Add ansible-lint and yamllint** configuration
5. **Create a test/validation workflow** (GitHub Actions or local script)
6. **Document macOS version support** (Sequoia only? Or backwards compatible?)
7. **Clean up shell initialization** - remove redundant NVM loading
8. **Replace hardcoded paths** with Ansible variables
9. **Delete unused roles** (docker, pip) entirely
10. **Add error handling** instead of `ignore_errors: true`

---

**Generated:** January 28, 2026
