# dotfiles

These are my dotfiles for OSX Tahoe. There are many like them, but these ones are mine.

Previous versions of this repo (archived) can be found here:

- [https://github.com/jansroka/dotfiles-osx-monterey (OSX 12)](https://github.com/jansroka/dotfiles-osx-monterey)
- [https://github.com/jansroka/dotfiles-osx-ventura (OSX 13)](https://github.com/jansroka/dotfiles-osx-ventura)
- [https://github.com/jansroka/dotfiles-osx-sonoma (OSX 14)](https://github.com/jansroka/dotfiles-osx-sonoma)
- [https://github.com/jansroka/dotfiles-osx-sequoia (OSX 15)](https://github.com/jansroka/dotfiles-osx-sequoia)

## Features

- super simple setup
- uses ansible and is idempotent
- keeps `~/` clean

## Available ansible roles

- brew
  - configures homebrew includings casks & Microsoft Office
- dock
  - configures your OSX dock
- duti
  - sets default app associations via `duti`
- gem
  - sets up and maintains my default gems
- hazel
  - ensures basic Hazel.app settings
- iterm
  - ensures our own preferences file is used
- maintenance
  - runs maintenance tasks including Spotlight database rebuild, disk verification, DNS cache flushing
- mas
  - takes care of apps installed via Mac App Store
- npm
  - installs the global npm packages that I use
- osx
  - sets lots of defaults for OSX and OSX apps
- sublime-text
  - installs sublime text via brew cask & symlinks preferences
- symlinks
  - softlinks a bunch of config files in to `~/`

## Getting started

You’ll need the following dependencies before getting started.

- Ansible
- Homebrew
- Xcode

At the time of writing it’s possible to get all three like so:

``` shell
xcode-select --install
/bin/bash -c "$(curl -fsSL https://brew.sh/install.sh)"
brew install ansible
```

## How to run this

### ...as a one-liner, e.g. for initial setup

Run this:

``` shell
curl -L https://raw.githubusercontent.com/jansroka/dotfiles/main/setup.sh | bash
```

This sets up a few things and then runs `ansible-playbook -i hosts dotfiles.yml -v`.

### ...as a regular command via CLI

Run this:

``` shell
time ansible-playbook dotfiles.yml -v --ask-become-pass
```

This will install things if they are not installed yet. It will also update things if they are already installed.

## How to run the maintenance playbook

Run this:

``` shell
time ansible-playbook maintenance.yml -v --ask-become-pass
```

This runs different tasks than the `dotfiles.yml` playbook. It does stuff like spotlight DB rebuild, repair permissions, verify volume, etc.

## How to make changes to this repo

### Pre-commit hooks

This repository uses `pre-commit` to automatically lint and validate code before commits.

#### Setup

Install pre-commit:
```shell
brew install pre-commit
```

Install git hooks:
```shell
pre-commit install
```

#### Running checks

Hooks run automatically on `git commit`. To manually run all checks:
```shell
pre-commit run --all-files
```

To update hook versions:
```shell
pre-commit autoupdate
```

#### What gets checked

- **YAML linting** (`yamllint`) - Validates YAML syntax, indentation, and line length
- **File formatting** - Ensures proper line endings, removes trailing whitespace, adds final newline
- **Ansible linting** (disabled) - Ready for future use when dependencies are properly configured

## Contributing

- Fork it ( <https://github.com/jansroka/dotfiles/fork>)
- Create your feature branch (`git checkout -b my-new-feature`)
- Commit your changes (`git commit -am 'Add some feature'`)
- Push to the branch (`git push origin my-new-feature`)
- Create a new Pull Request

## Inspiration

- <https://github.com/soehlert/osx-ansible>
- <https://github.com/geerlingguy/mac-dev-playbook/>
- <https://github.com/geerlingguy/ansible-collection-mac>
- <https://github.com/kinglouie/ansible-role-macos>
- <https://github.com/fgimian/macbuild-ansible>
- <https://github.com/elnappo/dotfiles/>
- <https://github.com/adamchainz/mac-ansible>
- <https://github.com/TalkingQuickly/ansible-osx-setup>
- <https://github.com/jcf/ansible-dotfiles>
- <https://github.com/frdmn/dotfiles>
