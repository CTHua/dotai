# dotai

[English](README.md)

AI 編碼代理的 dotfiles。用 Git 跨裝置同步你的設定。

除了 `git`、`bash`、`python3` 之外零依賴。

支援 **[OpenCode](https://opencode.ai)**、**[Claude Code](https://docs.anthropic.com/en/docs/claude-code)** 和 **[Codex CLI](https://github.com/openai/codex)**。

## 同步項目

| 項目 | OpenCode | Claude Code | Codex CLI |
|------|----------|-------------|-----------|
| Agent 指令 | `~/.config/opencode/AGENTS.md` | `~/.claude/CLAUDE.md` | `~/.codex/AGENTS.md` |
| 自訂技能 | `~/.config/opencode/skills/` | `~/.claude/skills/` | — |
| MCP servers | Merge 到 `opencode.json` | `~/.claude/.mcp.json` | Merge 到 `config.toml` |
| 外部技能 | Clone 並 symlink 到 `skills/` | 同上 | — |

## 快速開始

1. 點 **Use this template** 建立你自己的 repo，然後 clone：

```bash
git clone https://github.com/YOUR_USERNAME/dotai.git ~/dotai
cd ~/dotai
./install.sh
```

2. 編輯你的設定：

```bash
vim setting/AGENTS.md       # Agent 指令
vim setting/mcp.json         # MCP servers
vim external-skills.yml      # 外部技能
```

3. Push。每台裝置下次開 terminal 時自動更新。

## 運作方式

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

`~/.zshrc` 中的 shell hook 會在每次開啟 terminal 時執行，背景檢查遠端更新，有更新就自動 pull 並重新安裝。

## MCP Server 同步

編輯 `setting/mcp.json`，使用 [Claude Code 的格式](https://docs.anthropic.com/en/docs/claude-code/mcp)：

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

- **Claude Code**：直接 symlink，改了立即生效。
- **OpenCode**：`sync-mcp.sh` 自動轉換格式：
  - 為 stdio server 加入 `"type": "local"`
  - 環境變數語法轉換（`${VAR}` 轉為 `{env:VAR}`）
  - Merge 到既有的 `opencode.json`，不會覆蓋其他設定
- **Codex CLI**：`sync-mcp.sh` 將 JSON 轉為 TOML `[mcp_servers.*]` sections，merge 到 `config.toml`，不會覆蓋其他設定

## 外部技能

透過 `external-skills.yml` 引用其他 repo 的技能：

```yaml
skills:
  - name: my-skill
    repo: https://github.com/someone/opencode-skills.git
    path: skills/my-skill    # 選填，預設為 repo 根目錄
```

安裝腳本會把 repo clone 到 `references/`，再 symlink 技能目錄到 `setting/skills/`。外部技能 repo 會獨立自動更新。

## 自動更新

Shell hook（`auto-update.sh`）在每次開啟 terminal 時由 `~/.zshrc` 載入：

- 背景執行，不阻塞 terminal
- 冷卻機制（預設 1800 秒）避免頻繁檢查
- 偵測到本地未提交變更時跳過
- Lock 機制防止多個 terminal 同時觸發
- 即使主 repo 沒更新，外部技能 repo 也會同步

調整冷卻時間：

```bash
export DOTAI_UPDATE_INTERVAL_SECONDS=900
```

## 專案結構

```
.
├── install.sh              # 主安裝腳本（symlink + 呼叫 sync 腳本）
├── auto-update.sh          # Zsh hook，背景自動更新
├── sync-external.sh        # Clone/pull 外部技能 repo
├── sync-mcp.sh             # 轉換 MCP 設定格式並 merge 到 OpenCode 和 Codex
├── external-skills.yml     # 外部技能宣告
└── setting/
    ├── AGENTS.md            # Agent 指令（你的規則）
    ├── mcp.json             # MCP server 設定（Claude Code 格式）
    └── skills/              # 自訂技能（+ 外部技能 symlink）
```

## 新增裝置

```bash
git clone https://github.com/YOUR_USERNAME/dotai.git ~/dotai
cd ~/dotai
./install.sh
```

就這樣。開一個新 terminal 就會自動更新。

## License

MIT
