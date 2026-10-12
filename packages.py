#!/usr/bin/env python3
"""Reconcile optional dotfiles tools. Never uninstall tools not owned by this script."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tomllib

ROOT = Path(__file__).resolve().parent
MANIFEST = Path.home() / ".config/dotfiles/packages.toml"
RECEIPT = Path.home() / ".local/state/dotfiles/packages.json"
MISE_CONFIG = Path.home() / ".config/mise/config.toml"

# Names are stable profile identifiers; only the selected profiles are installed.
PROFILES = {
    "cli": ["bottom@latest", "btop@latest", "cloc@latest", "dust@latest",
            "dua@latest", "eza@latest", "fastfetch@latest", "tealdeer@latest", "yq@latest"],
    "editor": ["tree-sitter@latest"],
    "go": ["go@latest"],
    "rust": [],  # Rust remains owned by rustup, not this reconciler.
    "python": [],
    "cpp": [],  # C/C++ compiler and clangd are system-provided.
    "lua": ["ubi:LuaLS/lua-language-server@latest"],
    "web": ["node@latest", "npm:@biomejs/biome@latest",
            "npm:yaml-language-server@latest", "npm:vscode-langservers-extracted@latest"],
    "shell": ["ubi:mvdan/sh@latest"],
    "bazel": ["buildifier@latest", "ubi:google/yamlfmt@latest"],
}
UV_TOOLS = {"python": ["ruff", "basedpyright"]}
# The optional profiles use the existing mise backend where possible.

def run(*args):
    print("+", " ".join(map(str, args)), flush=True)
    subprocess.run(args, check=True, env={**os.environ, "MISE_YES": "1"})

def load_manifest():
    if not MANIFEST.exists():
        raise SystemExit(f"Missing {MANIFEST}; copy packages.example.toml there first")
    with MANIFEST.open("rb") as f:
        data = tomllib.load(f)
    profiles = data.get("profiles", {}).get("enabled", [])
    if not isinstance(profiles, list) or any(not isinstance(p, str) or p not in PROFILES for p in profiles):
        raise SystemExit(f"Invalid profiles.enabled; choose from: {', '.join(PROFILES)}")
    if len(profiles) != len(set(profiles)):
        raise SystemExit("Duplicate profile in profiles.enabled")
    packages = data.get("packages", {})
    if not isinstance(packages, dict):
        raise SystemExit("[packages] must be a table")
    for backend in ("mise", "uv"):
        values = packages.get(backend, [])
        if not isinstance(values, list) or any(not isinstance(v, str) or not v for v in values):
            raise SystemExit(f"packages.{backend} must be a list of non-empty strings")
    return profiles, {k: packages.get(k, []) for k in ("mise", "uv")}

def receipt():
    if not RECEIPT.exists():
        return {"mise": [], "uv": []}
    data = json.loads(RECEIPT.read_text())
    return {k: data.get(k, []) for k in ("mise", "uv")}

def save(data):
    RECEIPT.parent.mkdir(parents=True, exist_ok=True)
    tmp = RECEIPT.with_suffix(".tmp")
    tmp.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
    os.replace(tmp, RECEIPT)

def name(spec):
    return spec.rsplit("@", 1)[0]

def desired(profiles, packages):
    mise = list(dict.fromkeys(spec for p in profiles for spec in PROFILES[p]))
    uv = list(dict.fromkeys(tool for p in profiles for tool in UV_TOOLS.get(p, [])))
    return {"mise": list(dict.fromkeys(mise + packages["mise"])),
            "uv": list(dict.fromkeys(uv + packages["uv"]))}

def prepare_mise():
    if not shutil.which("mise"):
        raise SystemExit("mise missing; run ./install.sh first")
    MISE_CONFIG.parent.mkdir(parents=True, exist_ok=True)
    if MISE_CONFIG.is_symlink():
        content = MISE_CONFIG.read_bytes()
        MISE_CONFIG.unlink()
        MISE_CONFIG.write_bytes(content)
    elif not MISE_CONFIG.exists():
        MISE_CONFIG.write_bytes((ROOT / "mise/config.toml").read_bytes())

def selected_in_mise(spec):
    if not MISE_CONFIG.exists():
        return False
    with MISE_CONFIG.open("rb") as f:
        tools = tomllib.load(f).get("tools", {})
    key = name(spec)
    return key in tools

def installed_in_uv(tool):
    result = subprocess.run(["uv", "tool", "list"], capture_output=True, text=True, check=True)
    return any(line.split(" ", 1)[0].lower() == tool.lower()
               for line in result.stdout.splitlines() if line and not line[0].isspace())

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["status", "install", "purge"])
    parser.add_argument("--yes", action="store_true", help="Confirm purge without prompting")
    args = parser.parse_args()
    if args.yes and args.action != "purge":
        parser.error("--yes is only valid with purge")
    profiles, packages = load_manifest()
    wanted = desired(profiles, packages)
    owned = receipt()
    additions = {k: [v for v in wanted[k] if v not in owned[k]] for k in owned}
    removals = {k: [v for v in owned[k] if v not in wanted[k]] for k in owned}
    print("Profiles:", ", ".join(profiles) or "(none)")
    for backend in ("mise", "uv"):
        print(f"{backend}: add={additions[backend]} remove={removals[backend]}")
    if args.action == "status":
        return
    if args.action == "install":
        prepare_mise()
        # Re-run desired installations to repair partially installed tools.
        for spec in wanted["mise"]:
            if spec not in owned["mise"] and selected_in_mise(spec):
                print(f"Keeping pre-existing mise selection: {spec}")
                continue
            run("mise", "use", "--global", spec)
            if spec not in owned["mise"]:
                owned["mise"].append(spec)
                save(owned)
        for tool in wanted["uv"]:
            if tool not in owned["uv"] and installed_in_uv(tool):
                print(f"Keeping pre-existing uv tool: {tool}")
                continue
            run("uv", "tool", "install", "--upgrade", tool)
            if tool not in owned["uv"]:
                owned["uv"].append(tool)
                save(owned)
        if any(removals.values()):
            print("Obsolete managed tools detected; run 'just purge' to review.")
        return
    if not any(removals.values()):
        print("Nothing to purge.")
        return
    if not args.yes:
        if not sys.stdin.isatty():
            raise SystemExit("Purge requires an interactive terminal or --yes")
        answer = input("Remove the managed selections listed above? [y/N] ")
        if answer.strip().lower() not in ("y", "yes"):
            print("Cancelled.")
            return
    prepare_mise()
    # Only undo selections recorded in our receipt. Do not uninstall shared
    # mise versions from disk: other projects may still depend on them.
    for spec in removals["mise"]:
        run("mise", "unuse", "--global", name(spec))
        owned["mise"].remove(spec)
        save(owned)
    for tool in removals["uv"]:
        run("uv", "tool", "uninstall", tool)
        owned["uv"].remove(tool)
        save(owned)

if __name__ == "__main__":
    main()
