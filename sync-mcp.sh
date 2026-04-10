#!/bin/bash
#
# Sync MCP server config from setting/mcp.json to OpenCode.
# Claude Code is handled via symlink in install.sh.
#
# Canonical format (setting/mcp.json) uses Claude Code's format:
#   { "mcpServers": { "name": { "command": "...", "args": [...], "env": {...} } } }
#
# OpenCode format (opencode.json) differs:
#   - Key: "mcp" instead of "mcpServers"
#   - Each server needs "type": "local" for stdio servers
#   - Env var syntax: {env:VAR} instead of ${VAR}
#

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
MCP_FILE="$DOTFILES_DIR/setting/mcp.json"
OPENCODE_CONFIG="$HOME/.config/opencode/opencode.json"

[[ -f "$MCP_FILE" ]] || exit 0

# ── helpers ──────────────────────────────────────────────────

has_cmd() { command -v "$1" >/dev/null 2>&1; }

# ── OpenCode sync ────────────────────────────────────────────

sync_opencode_mcp() {
  [[ -d "$(dirname "$OPENCODE_CONFIG")" ]] || return 0

  python3 << 'PYTHON_SCRIPT'
import json, sys, os, re

mcp_file = os.environ.get("MCP_FILE", "")
opencode_config = os.environ.get("OPENCODE_CONFIG", "")

# Read canonical MCP config
try:
    with open(mcp_file) as f:
        mcp_data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError) as e:
    print(f"   Skipping MCP sync: {e}", file=sys.stderr)
    sys.exit(0)

servers = mcp_data.get("mcpServers", {})
if not servers:
    sys.exit(0)

# Convert to OpenCode format
opencode_mcp = {}
for name, config in servers.items():
    entry = dict(config)

    # Add "type": "local" for stdio servers (has command, no url)
    if "command" in entry and "type" not in entry:
        entry["type"] = "local"

    # Convert env var syntax: ${VAR} -> {env:VAR}
    if "env" in entry:
        new_env = {}
        for k, v in entry["env"].items():
            v = re.sub(r'\$\{([^}]+)\}', r'{env:\1}', str(v))
            new_env[k] = v
        entry["env"] = new_env

    opencode_mcp[name] = entry

# Read existing opencode.json or create new
try:
    with open(opencode_config) as f:
        config = json.load(f)
except FileNotFoundError:
    config = {}
except json.JSONDecodeError:
    print(f"   Warning: {opencode_config} is not valid JSON, skipping", file=sys.stderr)
    sys.exit(1)

# Merge MCP servers (replace entire mcp section)
config["mcp"] = opencode_mcp

# Write back atomically (write to tmp then rename)
tmp_path = opencode_config + ".tmp"
with open(tmp_path, "w") as f:
    json.dump(config, f, indent=2, ensure_ascii=False)
    f.write("\n")
    f.flush()
    os.fsync(f.fileno())
os.replace(tmp_path, opencode_config)

print(f"   Synced {len(opencode_mcp)} MCP server(s) to opencode.json")
PYTHON_SCRIPT
}

# ── main ─────────────────────────────────────────────────────

export MCP_FILE OPENCODE_CONFIG

if has_cmd python3; then
  sync_opencode_mcp
else
  echo "⚠️  python3 not found, skipping OpenCode MCP sync"
fi
