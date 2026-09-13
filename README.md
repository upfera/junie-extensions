# Junie Extensions

Marketplace containing two independent Junie CLI extensions.

## Extensions

- **codebase-memory** detects indexed Codebase Memory project names in `UserPromptSubmit` prompts and injects MCP verification context.
- **notifications** sends selected Junie lifecycle notifications through Windows Toast from WSL, `notify-send`, or `JUNIE_NOTIFY_COMMAND`.

## Use

Add this repository as a local marketplace in Junie CLI, then install `codebase-memory`, `notifications`, or both with `/extensions`. Junie owns installation and its cache; this repository contains no installer or uninstaller.

Hook commands use paths relative to the installed extension, so they continue to work after Junie copies an extension into its local cache. `${CLAUDE_PLUGIN_ROOT}` is not used; it is a Claude Code plugin variable, not a Junie CLI variable.

After installing `notifications`, edit `extensions/notifications/.hooks-enabled` in the installed extension directory to choose events. It uses `key=value` entries; set an event to `true` to enable it and prefix the line with `#` to disable it. The default enabled events are `PermissionRequest`, `Stop`, and `StopFailure`.

On WSL, Windows Toast notifications copy `resources/junie-logo.svg` to `%USERPROFILE%\.junie\junie-logo.svg` when the file is missing and use it as the notification icon.

## Validation

```bash
./extensions/codebase-memory/tests/test-router.sh
./extensions/notifications/tests/test.sh
```