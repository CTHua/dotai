# dotai

[繁體中文](README-ZH.md)

Dotfiles for AI coding agents. Sync your config across devices with Git.

Zero dependencies beyond `git`, `bash`, and `python3`.

Supports **[OpenCode](https://opencode.ai)**, **[Claude Code](https://docs.anthropic.com/en/docs/claude-code)**, and **[Codex CLI](https://github.com/openai/codex)**.

## What Gets Synced

| Item | OpenCode | Claude Code | Codex CLI |
|------|----------|-------------|-----------|
| Agent instructions | `~/.config/opencode/AGENTS.md` | `~/.claude/CLAUDE.md` | `~/.codex/AGENTS.md` |
| Custom skills | `~/.config/opencode/skills/` | `~/.claude/skills/` | — |
| MCP servers | Merged into `opencode.json` | `~/.claude/.mcp.json` | Merged into `config.toml` |
| External skills | Cloned and symlinked into `skills/` | Same | — |

## Quick Start

1. **Use this template** to create your own repo, then clone it:

```bash
git clone https://github.com/YOUR_USERNAME/dotai.git ~/dotai
cd ~/dotai
./install.sh
```

2. Edit your config:

```bash
vim setting/AGENTS.md       # Agent instructions
vim setting/mcp.json         # MCP servers
vim external-skills.yml      # External skills
```

3. Push. Every device auto-updates on next terminal open.

## How It Works

```
setting/AGENTS.md  ──symlink──>  ~/.config/opencode/AGENTS.md
                   ──symlink──>  ~/.claude/CLAUDE.md
                   ──symlink──>  ~/.codex/AGENTS.md

setting/skills/    ──symlink──>  ~/.config/opencode/skills/
                   ──symlink──>  ~/.claude/skills/

setting/mcp.json   ──symlink──>  ~/.claude/.mcp.json
                   ──convert──>  ~/.config/opencode/opencode.json (mcp key)
                   ──convert──>  ~/.codex/config.toml (mcp_servers sections)
```

A shell hook in `~/.zshrc` runs on every terminal open. It checks for remote updates in the background, pulls if needed, and re-runs the install.

## MCP Server Sync

Edit `setting/mcp.json` using [Claude Code's format](https://docs.anthropic.com/en/docs/claude-code/mcp):

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

- **Claude Code**: Symlinked directly, changes take effect immediately.
- **OpenCode**: `sync-mcp.sh` converts the format automatically:
  - Adds `"type": "local"` for stdio servers
  - Converts env var syntax (`${VAR}` to `{env:VAR}`)
  - Merges into existing `opencode.json` without overwriting other settings
- **Codex CLI**: `sync-mcp.sh` converts JSON to TOML `[mcp_servers.*]` sections and merges into `config.toml` without overwriting other settings

## External Skills

Reference skills from other repos via `external-skills.yml`:

```yaml
skills:
  - name: my-skill
    repo: https://github.com/someone/opencode-skills.git
    path: skills/my-skill    # optional, defaults to repo root
```

The install script clones repos into `references/` and symlinks the skill directories into `setting/skills/`. External skill repos are auto-updated independently.

## Auto-Update

The shell hook (`auto-update.sh`) is sourced by `~/.zshrc` on every terminal open:

- Runs in the background (non-blocking)
- Cooldown period (default 1800s) to avoid excessive checks
- Skips when local uncommitted changes are detected
- Lock mechanism prevents concurrent updates
- External skill repos are synced even when the main repo has no updates

Adjust the cooldown:

```bash
export DOTAI_UPDATE_INTERVAL_SECONDS=900
```

## Project Structure

```
.
├── install.sh              # Main installer (symlinks + calls sync scripts)
├── auto-update.sh          # Zsh hook for background auto-update
├── sync-external.sh        # Clone/pull external skill repos
├── sync-mcp.sh             # Convert and merge MCP config to OpenCode and Codex
├── external-skills.yml     # External skill declarations
└── setting/
    ├── AGENTS.md            # Agent instructions (your rules)
    ├── mcp.json             # MCP server config (Claude Code format)
    └── skills/              # Custom skills (+ external skill symlinks)
```

## Adding a New Device

```bash
git clone https://github.com/YOUR_USERNAME/dotai.git ~/dotai
cd ~/dotai
./install.sh
```

That's it. Open a new terminal and auto-update is active.

## License

MIT
