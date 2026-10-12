# Junie Extensions

A marketplace of four independent extensions for Junie CLI.

## Install

From a project where you run Junie CLI, add this repository as a marketplace:

```text
/extensions marketplace add https://github.com/upfera/junie-extensions
```

The repository URL uses its default branch, `main`. Install an extension from the `/extensions` screen, or run:

```text
/extensions install codebase-memory
```

Replace `codebase-memory` with `wsl-notifications`, `azure`, or `azure-devops` to install a different extension. Junie owns installation and its cache; this repository contains no installer or uninstaller.

## Extensions

### `codebase-memory`

Provides Codebase Memory MCP profiles, agents, and a skill, including a local, fail-open `UserPromptSubmit` router for projects indexed by `codebase-memory-mcp`. The router matches complete prompt tokens against cached project names (case-insensitive; `_` and `-` are equivalent) and injects Junie context with the confirmed project names. The context tells Junie to use Codebase Memory MCP tools such as `search_graph`, `trace_path`, and `query_graph` to verify code relationships instead of inferring them from name co-occurrence. The hook makes no network calls and invokes the local CLI only to refresh the project-name cache. Missing dependencies, malformed input, timeouts, or cache failures do not block a prompt.

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

Sends selected Junie lifecycle events to Windows Toast when running under WSL, to `notify-send` when available, or to standard output as a fallback. Set `JUNIE_NOTIFY_COMMAND` to override delivery with a command that accepts title and message arguments. The message is taken from the event payload and limited to 240 characters. On WSL, Windows Toast notifications copy `resources/junie-logo.svg` to `%USERPROFILE%\.junie\junie-logo.svg` when the file is missing and use it as the notification icon.

Events supported by the hook are `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PermissionRequest`, `Stop`, `StopFailure`, and `SessionEnd`. The default enabled events are `PermissionRequest`, `Stop`, and `StopFailure`. After installing `wsl-notifications`, edit `.hooks-enabled` in the installed extension directory to choose events. It uses `key=value` entries: set an event to `true` to enable it, or comment out its line to disable it. The hook records diagnostics in `~/notifications.log`; `JUNIE_NOTIFICATIONS_LOG` changes that path and `JUNIE_HOOKS_FILE` selects a different event file.

### Other extensions

- **`azure`** provides the Azure MCP server configuration.
- **`azure-devops`** provides the Azure DevOps MCP server, agents, and workflow skills.

## Marketplace behavior

Hook commands use paths relative to the installed extension, so they continue to work after Junie copies an extension into its local cache. `${CLAUDE_PLUGIN_ROOT}` is not used; it is a Claude Code plugin variable, not a Junie CLI variable.

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
