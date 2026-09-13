#!/usr/bin/env bash
# test-router.sh — Test suite for Junie CBM project mention detector hook
# Covers all 9 scenarios defined in Step 6 of task.md

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
ROUTER="${PROJECT_ROOT}/scripts/cbm-project-router.sh"

PASSED=0
FAILED=0

run_test() {
    local test_num="$1"
    local test_name="$2"
    local input_json="$3"
    local env_prefix="${4:-}"
    local expected_type="$5" # "match", "empty", "failopen"
    local expected_content="${6:-}"

    echo "======================================================================"
    echo "Test ${test_num}: ${test_name}"
    echo "Command: echo '<input>' | ${env_prefix}${ROUTER}"
    echo "Piped JSON input:"
    echo "${input_json}"
    echo "----------------------------------------------------------------------"

    local actual_stdout actual_exit
    if [ -n "$env_prefix" ]; then
        actual_stdout=$(eval "${env_prefix}\"${ROUTER}\"" <<< "${input_json}")
        actual_exit=$?
    else
        actual_stdout=$("${ROUTER}" <<< "${input_json}")
        actual_exit=$?
    fi

    echo "Exit code: ${actual_exit}"
    echo "Stdout: ${actual_stdout:-<empty>}"

    # Evaluation
    local ok=true
    if [ "$actual_exit" -ne 0 ]; then
        echo "RESULT: FAIL (expected exit code 0, got ${actual_exit})"
        ok=false
    elif [ "$expected_type" = "empty" ]; then
        if [ -n "$actual_stdout" ]; then
            echo "RESULT: FAIL (expected empty stdout, got non-empty)"
            ok=false
        fi
    elif [ "$expected_type" = "match" ]; then
        if [ -z "$actual_stdout" ]; then
            echo "RESULT: FAIL (expected match output, got empty stdout)"
            ok=false
        else
            # Verify valid JSON
            if ! printf '%s' "$actual_stdout" | jq -e . >/dev/null 2>&1; then
                echo "RESULT: FAIL (stdout is not valid JSON)"
                ok=false
            else
                local ctx
                ctx=$(printf '%s' "$actual_stdout" | jq -r '.additionalContext // empty')
                if [ -z "$ctx" ]; then
                    echo "RESULT: FAIL (JSON missing additionalContext)"
                    ok=false
                elif [[ "$ctx" != *"$expected_content"* ]]; then
                    echo "RESULT: FAIL (additionalContext does not contain '$expected_content')"
                    ok=false
                elif [[ "$expected_content" = "atlas-rjthk1" && "$ctx" != *"Do not call list_projects"* ]]; then
                    echo "RESULT: FAIL (additionalContext does not prohibit redundant list_projects calls)"
                    ok=false
                fi
            fi
        fi
    fi

    if [ "$ok" = true ]; then
        echo "RESULT: PASS"
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi
    echo ""
}

echo "=== Starting CBM Project Mention Detector Test Suite ==="
echo "Target router: ${ROUTER}"
echo ""

# Ensure cache is primed first
"${ROUTER}" <<< '{"prompt": "prime cache"}' >/dev/null 2>&1 || true

# Test 1: Single match
run_test "1" "Single match" \
    '{"prompt": "Please review atlas-rjthk1 code", "cwd": "/home", "session_id": "test-1"}' \
    "" "match" "atlas-rjthk1"

# Test 2: Multiple matches
run_test "2" "Multiple matches" \
    '{"prompt": "Can you compare atlas-rjthk1 and mercury-wvrbw3?", "cwd": "/home", "session_id": "test-2"}' \
    "" "match" "atlas-rjthk1, mercury-wvrbw3"

# Test 3: No match
run_test "3" "No match (unrelated prompt)" \
    '{"prompt": "How do I implement quicksort in Rust?", "cwd": "/home", "session_id": "test-3"}' \
    "" "empty" ""

# Test 4: Case differences and underscore substitution
run_test "4" "Case differences and _ vs -" \
    '{"prompt": "Check ATLAS_RJTHK1 and Mercury_WVRBW3", "cwd": "/home", "session_id": "test-4"}' \
    "" "match" "atlas-rjthk1, mercury-wvrbw3"

# Test 5a: False positive check (substring containment)
run_test "5a" "False positive check (longer identifiers only)" \
    '{"prompt": "We are evaluating super-atlas-rjthk1-v2 and atlas-rjthk1-mock.", "cwd": "/home", "session_id": "test-5a"}' \
    "" "empty" ""

# Test 5b: False positive check (longer identifier + legitimate separate token)
run_test "5b" "False positive check (substring coexisting with legitimate token)" \
    '{"prompt": "Don'\''t use super-atlas-rjthk1-v2, use atlas-rjthk1 instead.", "cwd": "/home", "session_id": "test-5b"}' \
    "" "match" "atlas-rjthk1"

# Test 6: Punctuation adjacency
run_test "6" "Punctuation adjacency" \
    '{"prompt": "What about atlas-rjthk1? Compare with (mercury-wvrbw3), `atlas-rjthk1`.", "cwd": "/home", "session_id": "test-6"}' \
    "" "match" "atlas-rjthk1, mercury-wvrbw3"

# Test 7a: Empty stdin
run_test "7a" "Empty stdin" \
    "" \
    "" "empty" ""

# Test 7b: Invalid JSON
run_test "7b" "Malformed JSON" \
    "{not valid json" \
    "" "empty" ""

# Test 7c: Missing prompt field
run_test "7c" "Missing prompt field" \
    '{"cwd": "/home", "session_id": "test-7c"}' \
    "" "empty" ""

# Test 8: Cold cache
TEST_COLD_DIR="/tmp/test-cbm-cold-cache-$$"
rm -rf "$TEST_COLD_DIR"
run_test "8" "Cold cache rebuilding" \
    '{"prompt": "Check atlas-rjthk1 on cold cache", "cwd": "/home", "session_id": "test-8"}' \
    "JUNIE_CBM_CACHE_DIR=\"$TEST_COLD_DIR\" JUNIE_CBM_CACHE_FILE=\"$TEST_COLD_DIR/projects.json\" " \
    "match" "atlas-rjthk1"
rm -rf "$TEST_COLD_DIR"

# Test 9: CBM binary temporarily missing with empty cache
TEST_MISSING_DIR="/tmp/test-cbm-missing-cache-$$"
rm -rf "$TEST_MISSING_DIR"
mkdir -p "$TEST_MISSING_DIR"
run_test "9" "CBM binary temporarily missing (fail-open silent exit 0)" \
    '{"prompt": "Check atlas-rjthk1 with missing binary", "cwd": "/home", "session_id": "test-9"}' \
    "PATH=\"/usr/bin:/bin\" JUNIE_CBM_CACHE_DIR=\"$TEST_MISSING_DIR\" JUNIE_CBM_CACHE_FILE=\"$TEST_MISSING_DIR/projects.json\" " \
    "empty" ""
rm -rf "$TEST_MISSING_DIR"

echo "======================================================================"
echo "Test Summary: ${PASSED} passed, ${FAILED} failed"
echo "======================================================================"

if [ "$FAILED" -eq 0 ]; then
    exit 0
else
    exit 1
fi
