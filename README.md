# Junie Extensions

A marketplace of four independent extensions for Junie CLI. Add this repository as a local marketplace in Junie, then install the extensions you need with `/extensions`.

## Extensions

### `codebase-memory`

A local, fail-open `UserPromptSubmit` router for projects indexed by `codebase-memory-mcp`. It matches complete prompt tokens against cached project names (case-insensitive; `_` and `-` are equivalent) and injects Junie context with the confirmed project names. The context tells Junie to use Codebase Memory MCP tools such as `search_graph`, `trace_path`, and `query_graph` to verify code relationships instead of inferring them from name co-occurrence. The hook makes no network calls and invokes the local CLI only to refresh the project-name cache. Missing dependencies, malformed input, timeouts, or cache failures do not block a prompt.

Requirements: `bash`, `jq`, and `codebase-memory-mcp` in `PATH` (the hook fails open if the CLI is unavailable).

| Variable | Default | Purpose |
|---|---|---|
| `JUNIE_CBM_CACHE_DIR` | `${XDG_CACHE_HOME:-~/.cache}/junie-cbm` | Cache and debug-log directory |
| `JUNIE_CBM_CACHE_FILE` | `$JUNIE_CBM_CACHE_DIR/projects.json` | Cached project list |
| `JUNIE_CBM_CACHE_TTL_SEC` | `600` | Cache lifetime in seconds |
| `JUNIE_CBM_CLI_TIMEOUT_SEC` | `2` | Timeout per CLI request |
| `JUNIE_CBM_CLI_MAX_TIME_SEC` | `3` | Total project-list refresh budget |
| `JUNIE_CBM_HOOK_DEBUG` | `0` | Set to `1` to log diagnostics to stderr and `hook-debug.log` |
| `CBM_BIN` | `codebase-memory-mcp` | CLI executable to use |

### `wsl-notifications`

Sends selected Junie lifecycle events to Windows Toast when running under WSL, to `notify-send` when available, or to standard output as a fallback. Set `JUNIE_NOTIFY_COMMAND` to override delivery with a command that accepts title and message arguments. The message is taken from the event payload and limited to 240 characters. Windows Toast delivery uses the included `resources/junie-logo.svg` when Windows interop is available.

Events supported by the hook are `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PermissionRequest`, `Stop`, `StopFailure`, and `SessionEnd`. The default enabled events are `PermissionRequest`, `Stop`, and `StopFailure`. After installing the extension, edit its `.hooks-enabled` file: set an event to `true` to enable it, or comment out its line to disable it. The hook records diagnostics in `~/notifications.log`; `JUNIE_NOTIFICATIONS_LOG` changes that path and `JUNIE_HOOKS_FILE` selects a different event file.

### Other extensions

- **`azure`** provides the Azure MCP server configuration.
- **`azure-devops`** provides the Azure DevOps MCP server, agents, and workflow skills.

## Marketplace behavior

Junie manages extension installation and its cache; this repository has no installer or uninstaller. Hook commands resolve scripts relative to the installed extension, so they continue to work after Junie copies an extension into its local cache. These are Junie extensions, not Claude Code plugins; `${CLAUDE_PLUGIN_ROOT}` is not used.

The standalone repositories [`junie-codebase-memory-mcp-hook`](https://github.com/Tomasz-Marciniak/junie-codebase-memory-mcp-hook) and [`junie-wsl-notifications`](https://github.com/Tomasz-Marciniak/junie-wsl-notifications) are retired. Do not install or run a standalone hook alongside its marketplace extension: both can register the same Junie events and cause duplicate behavior.

### Migrate from the standalone installers

1. Run the matching legacy uninstaller before installing the marketplace extension. From a clone, run `./uninstall.sh`; the notifications repository also accepts `./install.sh uninstall`. The original uninstall scripts are retained in the retired repositories.
2. Check `~/.junie/hooks/` and remove only stale legacy files if an uninstaller did not remove them: `cbm-common.sh`, `cbm-project-router.sh`, and/or `notify-send.sh`. Do not delete unrelated Junie hooks.
3. Inspect `~/.junie/config.json` and remove only hook entries that invoke `~/.junie/hooks/cbm-project-router.sh` or `~/.junie/hooks/notify-send.sh` if any remain. Preserve other hooks and settings. Back up the file before manual edits.
4. Install `codebase-memory` and/or `wsl-notifications` from this marketplace with `/extensions`.

## Validation

```bash
./extensions/codebase-memory/tests/test-router.sh
./extensions/wsl-notifications/tests/test.sh
```
