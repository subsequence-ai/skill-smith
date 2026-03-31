#!/usr/bin/env bash
# validate-skill.sh — Structural validation harness for Claude Code skills
# Implements all (S)-tagged checks from the quality checklist.
# No external dependencies — uses grep/sed/awk only.
# Exit code: 0 = all pass, 1 = any fail

set -euo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

# --- Counters ---
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf "  ${GREEN}PASS${NC} %s\n" "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf "  ${RED}FAIL${NC} %s\n" "$1"; }
warn() { WARN_COUNT=$((WARN_COUNT + 1)); printf "  ${YELLOW}WARN${NC} %s\n" "$1"; }

# --- Argument check ---
if [[ $# -ne 1 ]]; then
    echo "Usage: validate-skill.sh <skill-directory>"
    echo "Example: validate-skill.sh ~/.claude/skills/my-skill"
    exit 2
fi

SKILL_DIR="$1"
SKILL_DIR="${SKILL_DIR%/}"  # strip trailing slash
SKILL_FILE="$SKILL_DIR/SKILL.md"
DIR_NAME=$(basename "$SKILL_DIR")

if [[ ! -d "$SKILL_DIR" ]]; then
    echo "Error: Directory '$SKILL_DIR' does not exist."
    exit 2
fi

if [[ ! -f "$SKILL_FILE" ]]; then
    echo "Error: No SKILL.md found in '$SKILL_DIR'."
    exit 2
fi

CONTENT=$(cat "$SKILL_FILE")
TOTAL_LINES=$(wc -l < "$SKILL_FILE" | tr -d ' ')

# --- Extract frontmatter ---
# Frontmatter is between the first and second '---' lines
FRONTMATTER_START=$(grep -n '^---$' "$SKILL_FILE" | head -1 | cut -d: -f1)
FRONTMATTER_END=$(grep -n '^---$' "$SKILL_FILE" | head -2 | tail -1 | cut -d: -f1)

if [[ -z "$FRONTMATTER_START" ]] || [[ -z "$FRONTMATTER_END" ]] || [[ "$FRONTMATTER_START" -eq "$FRONTMATTER_END" ]]; then
    HAVE_FRONTMATTER=false
    FRONTMATTER=""
    BODY=""
    BODY_LINES=$TOTAL_LINES
else
    HAVE_FRONTMATTER=true
    FRONTMATTER=$(sed -n "$((FRONTMATTER_START+1)),$((FRONTMATTER_END-1))p" "$SKILL_FILE")
    BODY=$(sed -n "$((FRONTMATTER_END+1)),\$p" "$SKILL_FILE")
    BODY_LINES=$(echo "$BODY" | wc -l | tr -d ' ')
fi

# Strip fenced code blocks for pattern checks (S19, S22)
# Removes everything between ``` markers (inclusive)
BODY_NO_CODEBLOCKS=$(echo "$BODY" | awk '/^```/{skip=!skip; next} !skip{print}')

# Extract name and description from frontmatter
NAME_VALUE=""
DESC_VALUE=""
if $HAVE_FRONTMATTER; then
    NAME_VALUE=$(echo "$FRONTMATTER" | grep -E '^name:' | sed 's/^name:[[:space:]]*//' | tr -d '"' | tr -d "'" || true)
    # Description: grab everything after 'description:' on the same line
    DESC_VALUE=$(echo "$FRONTMATTER" | grep -E '^description:' | sed 's/^description:[[:space:]]*//' | tr -d '"' | tr -d "'" || true)
fi

# ============================================================
printf "\n${BOLD}=== Skill Validation: %s ===${NC}\n" "$DIR_NAME"
printf "File: %s (%s lines)\n\n" "$SKILL_FILE" "$TOTAL_LINES"

# ============================================================
printf "${BOLD}── Structural Validation ──${NC}\n"

# S1: YAML frontmatter present and parses
if $HAVE_FRONTMATTER; then
    pass "YAML frontmatter is present and parses correctly"
else
    fail "YAML frontmatter is missing or malformed (need two '---' delimiters)"
fi

# S2: name exists and is kebab-case
if [[ -n "$NAME_VALUE" ]]; then
    if echo "$NAME_VALUE" | grep -qE '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$'; then
        pass "name field exists and is kebab-case: '$NAME_VALUE'"
    else
        fail "name field is not kebab-case (lowercase letters, numbers, hyphens only): '$NAME_VALUE'"
    fi
else
    fail "name field is missing"
fi

# S3: name max 64 characters
if [[ -n "$NAME_VALUE" ]]; then
    NAME_LEN=${#NAME_VALUE}
    if [[ $NAME_LEN -le 64 ]]; then
        pass "name is $NAME_LEN chars (max 64)"
    else
        fail "name is $NAME_LEN chars (max 64)"
    fi
fi

# S4: name matches parent directory name
if [[ -n "$NAME_VALUE" ]]; then
    if [[ "$NAME_VALUE" == "$DIR_NAME" ]]; then
        pass "name matches directory: '$NAME_VALUE' == '$DIR_NAME'"
    else
        fail "name '$NAME_VALUE' does not match directory '$DIR_NAME'"
    fi
fi

# S5: name does not contain "anthropic" or "claude"
if [[ -n "$NAME_VALUE" ]]; then
    if echo "$NAME_VALUE" | grep -qiE 'anthropic|claude'; then
        fail "name contains 'anthropic' or 'claude': '$NAME_VALUE'"
    else
        pass "name does not contain 'anthropic' or 'claude'"
    fi
fi

# S6: name does not start or end with hyphen
if [[ -n "$NAME_VALUE" ]]; then
    if echo "$NAME_VALUE" | grep -qE '^-|-$'; then
        fail "name starts or ends with a hyphen: '$NAME_VALUE'"
    else
        pass "name does not start or end with a hyphen"
    fi
fi

# S7: name does not contain consecutive hyphens
if [[ -n "$NAME_VALUE" ]]; then
    if echo "$NAME_VALUE" | grep -qE '\-\-'; then
        fail "name contains consecutive hyphens: '$NAME_VALUE'"
    else
        pass "name does not contain consecutive hyphens"
    fi
fi

# S8: description exists and is non-empty
if [[ -n "$DESC_VALUE" ]]; then
    pass "description field exists and is non-empty"
else
    fail "description field is missing or empty"
fi

# S9: description is single line
if [[ -n "$DESC_VALUE" ]]; then
    DESC_LINE_COUNT=$(echo "$FRONTMATTER" | grep -c '^description:' || true)
    # Check if there are continuation lines (indented lines after description)
    DESC_LINE_NUM=$(echo "$FRONTMATTER" | grep -n '^description:' | head -1 | cut -d: -f1 || true)
    if [[ -n "$DESC_LINE_NUM" ]]; then
        NEXT_LINE_NUM=$((DESC_LINE_NUM + 1))
        NEXT_LINE=$(echo "$FRONTMATTER" | sed -n "${NEXT_LINE_NUM}p" || true)
        # If next line starts with whitespace and isn't a new key, it's a continuation
        if echo "$NEXT_LINE" | grep -qE '^\s+[^\s]' 2>/dev/null && ! echo "$NEXT_LINE" | grep -qE '^\s*[a-z_-]+:' 2>/dev/null; then
            fail "description spans multiple lines (must be single line in YAML)"
        else
            pass "description is a single line"
        fi
    else
        pass "description is a single line"
    fi
fi

# S10: description max 1024 characters
if [[ -n "$DESC_VALUE" ]]; then
    DESC_LEN=${#DESC_VALUE}
    if [[ $DESC_LEN -le 1024 ]]; then
        pass "description is $DESC_LEN chars (max 1,024)"
    else
        fail "description is $DESC_LEN chars (max 1,024)"
    fi
fi

# S11: description does not contain XML tags
if [[ -n "$DESC_VALUE" ]]; then
    if echo "$DESC_VALUE" | grep -qE '<[a-zA-Z][^>]*>'; then
        fail "description contains XML tags"
    else
        pass "description does not contain XML tags"
    fi
fi

# S12: body under 500 lines
if [[ $BODY_LINES -le 500 ]]; then
    pass "body is $BODY_LINES lines (max 500)"
else
    fail "body is $BODY_LINES lines (max 500)"
fi

# S13: required sections present
printf "\n${BOLD}── Required Sections ──${NC}\n"
REQUIRED_SECTIONS=("Purpose" "Methodology" "Output Format" "Edge Cases" "Example" "Quality Criteria")
for section in "${REQUIRED_SECTIONS[@]}"; do
    # Look for markdown headers containing the section name (case-insensitive)
    if echo "$BODY" | grep -qiE "^#{1,4}.*${section}"; then
        pass "Section found: $section"
    else
        fail "Section missing: $section"
    fi
done

# S13b: required sections have content (at least 2 non-empty lines before next header)
for section in "${REQUIRED_SECTIONS[@]}"; do
    # Find the line number of the section header
    SECTION_LINE=$(echo "$BODY" | grep -niE "^#{1,4}.*${section}" | head -1 | cut -d: -f1 || true)
    if [[ -z "$SECTION_LINE" ]]; then
        continue  # already failed S13, skip content check
    fi
    # Find the next header after this section
    NEXT_HEADER_LINE=$(echo "$BODY" | tail -n +"$((SECTION_LINE+1))" | grep -nE "^#{1,4} " | head -1 | cut -d: -f1 || true)
    if [[ -n "$NEXT_HEADER_LINE" ]]; then
        # Extract lines between this header and the next
        SECTION_CONTENT=$(echo "$BODY" | sed -n "$((SECTION_LINE+1)),$((SECTION_LINE+NEXT_HEADER_LINE-1))p")
    else
        # Last section — extract to end of body
        SECTION_CONTENT=$(echo "$BODY" | tail -n +"$((SECTION_LINE+1))")
    fi
    # Count non-empty lines
    NON_EMPTY=$(echo "$SECTION_CONTENT" | grep -c '[^[:space:]]' || true)
    if [[ $NON_EMPTY -ge 1 ]]; then
        pass "Section '$section' has content ($NON_EMPTY non-empty lines)"
    else
        fail "Section '$section' header exists but has no content"
    fi
done

# S14: referenced files one level deep
printf "\n${BOLD}── File References ──${NC}\n"
HAS_SUBDIRS=false
if [[ -d "$SKILL_DIR" ]]; then
    # Check for files more than one level deep (excluding hidden dirs)
    DEEP_FILES=$(find "$SKILL_DIR" -mindepth 3 -not -path '*/.*' -type f 2>/dev/null || true)
    if [[ -n "$DEEP_FILES" ]]; then
        fail "Referenced files are deeper than one level:\n$DEEP_FILES"
    else
        pass "All referenced files are one level deep (or no subdirectories)"
    fi
fi

# ============================================================
printf "\n${BOLD}── Description Quality ──${NC}\n"

# S15: first 250 chars contain routing info
if [[ -n "$DESC_VALUE" ]]; then
    FIRST_250="${DESC_VALUE:0:250}"
    # Check for verb-like words that indicate action/routing
    if echo "$FIRST_250" | grep -qiE '(use when|invoke|creates?|produces?|generates?|builds?|analyzes?|reviews?|validates?|implements?|designs?|writes?)'; then
        pass "First 250 chars contain routing-relevant language"
    else
        warn "First 250 chars may lack routing verbs/trigger phrases (review manually)"
    fi
fi

# S16: third-person voice
if [[ -n "$DESC_VALUE" ]]; then
    if echo "$DESC_VALUE" | grep -qiE '\b(I can|I will|you can|you will|we can|we will|I am|you are|we are)\b'; then
        fail "description uses first/second person (must be third person)"
    else
        pass "description uses third-person voice"
    fi
fi

# S17: meaningful length (>100 chars)
if [[ -n "$DESC_VALUE" ]]; then
    if [[ ${#DESC_VALUE} -ge 100 ]]; then
        pass "description is ${#DESC_VALUE} chars (minimum 100 for meaningful routing)"
    else
        fail "description is only ${#DESC_VALUE} chars (minimum 100 for meaningful routing)"
    fi
fi

# ============================================================
printf "\n${BOLD}── Output Format ──${NC}\n"

# S18: output format section exists
if echo "$BODY" | grep -qiE "^#{1,4}.*[Oo]utput [Ff]ormat"; then
    pass "Output Format section exists"
else
    fail "Output Format section missing"
fi

# S19: no vague output instructions (excludes fenced code blocks)
VAGUE_OUTPUT_PATTERNS='(produce a summary|write a structured analysis|generate a report|create a document|provide an overview)'
if echo "$BODY_NO_CODEBLOCKS" | grep -qiE "$VAGUE_OUTPUT_PATTERNS"; then
    MATCHES=$(echo "$BODY_NO_CODEBLOCKS" | grep -iE "$VAGUE_OUTPUT_PATTERNS" | head -3)
    fail "Vague output instructions found:\n$MATCHES"
else
    pass "No vague output instructions found"
fi

# ============================================================
printf "\n${BOLD}── Edge Cases ──${NC}\n"

# S20: edge cases section exists
if echo "$BODY" | grep -qiE "^#{1,4}.*[Ee]dge [Cc]ases"; then
    pass "Edge Cases section exists"
else
    fail "Edge Cases section missing"
fi

# ============================================================
printf "\n${BOLD}── Methodology Quality ──${NC}\n"

# S21: no placeholder text
PLACEHOLDER_PATTERNS='\[(INSERT|TODO|YOUR|FILL|PLACEHOLDER|ADD|REPLACE)'
if echo "$BODY" | grep -qE "$PLACEHOLDER_PATTERNS"; then
    MATCHES=$(echo "$BODY" | grep -E "$PLACEHOLDER_PATTERNS" | head -3)
    fail "Placeholder text found:\n$MATCHES"
else
    pass "No placeholder text found"
fi

# S22: no vague guidance (excludes fenced code blocks)
VAGUE_GUIDANCE='(use good judgment|be thorough|be creative|as appropriate|as needed|consider the context|use discretion)'
if echo "$BODY_NO_CODEBLOCKS" | grep -qiE "$VAGUE_GUIDANCE"; then
    MATCHES=$(echo "$BODY_NO_CODEBLOCKS" | grep -iE "$VAGUE_GUIDANCE" | head -3)
    fail "Vague guidance found:\n$MATCHES"
else
    pass "No vague guidance phrases found"
fi

# S23: at least one example present
EXAMPLE_IN_BODY=false
EXAMPLE_IN_FILES=false

if echo "$BODY" | grep -qiE "^#{1,4}.*(Example|Sample)"; then
    EXAMPLE_IN_BODY=true
fi

# Check for example files in subdirectories
if find "$SKILL_DIR" -mindepth 2 -maxdepth 2 -type f -name '*example*' -o -name '*sample*' 2>/dev/null | grep -q .; then
    EXAMPLE_IN_FILES=true
fi

if $EXAMPLE_IN_BODY || $EXAMPLE_IN_FILES; then
    pass "At least one example present"
else
    fail "No example section or example files found"
fi

# S24: body under 150 lines (warning only)
if [[ $BODY_LINES -le 150 ]]; then
    pass "Body is $BODY_LINES lines (target: under 150 for core methodology)"
else
    warn "Body is $BODY_LINES lines (target: under 150 — consider moving content to references/)"
fi

# ============================================================
printf "\n${BOLD}── Summary ──${NC}\n"
printf "  ${GREEN}Passed:${NC}   %d\n" "$PASS_COUNT"
printf "  ${RED}Failed:${NC}   %d\n" "$FAIL_COUNT"
printf "  ${YELLOW}Warnings:${NC} %d\n" "$WARN_COUNT"
printf "  Total checks: %d\n\n" $((PASS_COUNT + FAIL_COUNT + WARN_COUNT))

if [[ $FAIL_COUNT -gt 0 ]]; then
    printf "${RED}${BOLD}RESULT: FAIL${NC} (%d issue(s) found)\n\n" "$FAIL_COUNT"
    exit 1
else
    printf "${GREEN}${BOLD}RESULT: PASS${NC}"
    if [[ $WARN_COUNT -gt 0 ]]; then
        printf " (with %d warning(s))" "$WARN_COUNT"
    fi
    printf "\n\n"
    exit 0
fi
