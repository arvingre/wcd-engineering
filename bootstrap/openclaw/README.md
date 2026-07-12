# OpenClaw Bootstrap

## What is ~/.openclaw?

`~/.openclaw` is the OpenClaw **runtime directory**. It contains:

- Gateway configuration (`openclaw.json`)
- Device identity and pairing data
- Session state and memory databases (SQLite)
- Credentials for connected services (Telegram, etc.)
- Logs and temporary state

It is **not a project directory** and should not be treated like one.

## What NOT to do with ~/.openclaw

| Action | Why not |
|--------|---------|
| Put the whole directory in Git | Contains secrets, tokens, and device credentials |
| Create a symlink to the whole directory | Same reason — exposes all credentials |
| Commit `openclaw.json` with API keys | Secrets would be in Git history |
| Back up SQLite files directly | They may be locked or in inconsistent state while Gateway is running |

## What to do instead

**Long-term knowledge belongs in wcd-engineering**, not in `~/.openclaw`:

- Engineering standards → `wcd-engineering/standards/`
- Architecture decisions → `wcd-engineering/architecture/`
- Agent rules and prompts → `wcd-engineering/agents/` and `wcd-engineering/prompts/`
- Project memory → `wcd-engineering/memory/projects/`
- Bootstrap scripts → `wcd-engineering/bootstrap/`

The OpenClaw workspace (`~/.openclaw/workspace/`) can hold:
- `MEMORY.md` — index of durable memory entries
- `memory/*.md` — durable memory files (non-sensitive)
- `AGENTS.md`, `SOUL.md`, `TOOLS.md` — agent persona and routing rules

These workspace files are safe to version separately if needed.

## Recovering OpenClaw on a new machine

1. Install OpenClaw following the official docs
2. Run `openclaw gateway start`
3. Pair devices as needed (new device identity will be generated)
4. Restore workspace files from wcd-engineering or a separate backup:
   ```bash
   cp wcd-engineering/bootstrap/openclaw/workspace-files/* ~/.openclaw/workspace/
   ```
5. Re-enter API keys via `openclaw config` — do not restore from backup files

## Credentials

OpenClaw credentials (API keys, Telegram tokens, etc.) must be:
- Re-entered manually on a new machine
- Never committed to Git
- Never stored in wcd-engineering

Use a password manager (1Password, Bitwarden, etc.) to store credentials securely.
