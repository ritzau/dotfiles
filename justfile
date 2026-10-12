# Core tools: ./install.sh. Optional profiles: ~/.config/dotfiles/packages.toml.
set shell := ["bash", "-euo", "pipefail", "-c"]

default:
    @just --list

# Preview changes to optional tools.
status:
    @python3 packages.py status

# Install/repair selected optional tools (never removes anything).
install:
    @python3 packages.py install

# Show planned removals and request confirmation (pass --yes for automation).
purge *args:
    @python3 packages.py purge {{args}}

# Check editor tool availability.
doctor:
    @./check-nvim-tools.sh
