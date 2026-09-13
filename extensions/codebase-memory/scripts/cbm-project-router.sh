#!/usr/bin/env bash
# cbm-project-router.sh — Junie UserPromptSubmit hook for Codebase Memory project detection
# Fail-open router: detects mentions of indexed CBM projects and injects verification context.
# Never exits non-zero; never emits unformatted stdout.

# Fail-open: jq is required to parse JSON input and format JSON output.
if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

# Locate and source cbm-common.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
if [ -f "$SCRIPT_DIR/cbm-common.sh" ]; then
    # shellcheck source=scripts/cbm-common.sh
    source "$SCRIPT_DIR/cbm-common.sh"
elif [ -f "$HOME/.junie/hooks/cbm-common.sh" ]; then
    # shellcheck source=/dev/null
    source "$HOME/.junie/hooks/cbm-common.sh"
else
    exit 0
fi

# Declare associative map for project lookup
declare -A CBM_PROJECT_MAP

main() {
    cbm_debug "Router invoked (pid: $$)"

    # Read entire payload from stdin
    local input
    input=$(cat 2>/dev/null)
    if [ -z "$input" ]; then
        cbm_debug "No input received; exiting"
        exit 0
    fi
    cbm_debug "Received input payload (${#input} bytes)"

    # Extract user prompt
    local prompt
    prompt=$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null)
    if [ -z "$prompt" ]; then
        cbm_debug "Input contains no non-empty prompt; exiting"
        exit 0
    fi
    cbm_debug "Prompt extracted (${#prompt} chars)"

    # Ensure project cache is ready (using stale cache as fallback if needed)
    if ! cbm_ensure_cache; then
        cbm_debug "Unable to ensure project cache; exiting fail-open"
        exit 0
    fi

    # Load project map into memory
    if ! cbm_load_project_map; then
        cbm_debug "Unable to load project map; exiting fail-open"
        exit 0
    fi
    cbm_debug "Loaded project map (${#CBM_PROJECT_MAP[@]} normalized names)"

    # Match tokens from prompt against known projects
    local matched
    matched=$(cbm_match_prompt "$prompt")
    if [ -z "$matched" ]; then
        cbm_debug "No project names matched prompt; exiting"
        exit 0
    fi
    cbm_debug "Matched projects: $matched"

    # Build and emit single-line JSON with additionalContext
    cbm_build_additional_context_json "$matched"
    cbm_debug "Emitted additionalContext JSON"
    exit 0
}

# Trap any unexpected errors and exit 0 cleanly
trap 'exit 0' ERR
main || exit 0
