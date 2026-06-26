#!/usr/bin/env bash
# Next.js security scanner — first-pass automated detection
# Usage: bash ~/.cursor/skills/security-audit/scripts/scan.sh [directory]

set -euo pipefail

DIR="${1:-.}"
FOUND=0

echo "=== SECURITY-AUDIT SCAN (Next.js) ==="
echo "Directory: $DIR"
echo "Timestamp: $(date -Iseconds)"
echo ""

if ! command -v rg &> /dev/null; then
    echo "[ERROR] ripgrep (rg) required"
    exit 1
fi

report() {
    local severity="$1"
    local title="$2"
    local file="$3"
    local line="${4:-}"
    echo "[$severity] $title"
    if [[ -n "$line" ]]; then
        echo "  File: $file:$line"
    else
        echo "  File: $file"
    fi
    echo ""
    FOUND=$((FOUND + 1))
}

# Auth patterns recognized in Ruslan's repos (not exhaustive)
has_auth() {
    local file="$1"
    rg -q '(getUser|getServerSession|auth\(|getSession|currentUser|isValidSignature|isStudioAccessGranted|safeEqual|STUDIO_BASIC_AUTH|createServerClient)' "$file" 2>/dev/null
}

echo "=== CRITICAL: NEXT_PUBLIC_ secrets ==="
echo ""

for envfile in $(find "$DIR" -name ".env*" -type f 2>/dev/null); do
    while IFS=: read -r line_num content; do
        [[ -z "$content" ]] && continue
        if echo "$content" | grep -qiE 'NEXT_PUBLIC_.*(SECRET|WRITE|PASSWORD|PRIVATE|SERVICE_ROLE)'; then
            report "CRITICAL" "Suspicious NEXT_PUBLIC_ variable (likely secret exposed to client)" "$envfile" "$line_num"
        elif echo "$content" | grep -qiE 'NEXT_PUBLIC_.*(KEY|TOKEN)' && ! echo "$content" | grep -qiE 'ANON_KEY|PUBLISHABLE|API_KEY'; then
            report "CRITICAL" "NEXT_PUBLIC_ KEY/TOKEN — verify it is safe to bundle" "$envfile" "$line_num"
        fi
    done < <(grep -n 'NEXT_PUBLIC_' "$envfile" 2>/dev/null || true)
done

echo "=== HIGH: next.config env exposure ==="
echo ""

for NEXT_CONFIG_FILE in "$DIR/next.config.js" "$DIR/next.config.mjs" "$DIR/next.config.ts"; do
    [[ -f "$NEXT_CONFIG_FILE" ]] || continue
    if rg -q 'env\s*:' "$NEXT_CONFIG_FILE" 2>/dev/null; then
        if rg -q '(SECRET|PASSWORD|TOKEN|PRIVATE|SERVICE_ROLE)' "$NEXT_CONFIG_FILE" 2>/dev/null; then
            report "HIGH" "next.config env contains sensitive keys (values bundled to client)" "$NEXT_CONFIG_FILE"
        else
            report "MEDIUM" "next.config env detected (values bundled to client)" "$NEXT_CONFIG_FILE"
        fi
    fi
done

echo "=== HIGH: Server secrets in client components ==="
echo ""

while IFS=: read -r file line _; do
    [[ -z "$file" ]] && continue
    if rg -q 'process\.env\.(?!NEXT_PUBLIC_)' "$file" 2>/dev/null; then
        if rg -q '"use client"' "$file" 2>/dev/null; then
            report "CRITICAL" "Server env var referenced in use client file" "$file" "$line"
        fi
    fi
done < <(rg -n 'process\.env\.' "$DIR" -g "*.tsx" -g "*.ts" 2>/dev/null || true)

echo "=== HIGH: Unauthenticated Server Actions ==="
echo ""

ACTION_FILES=$(rg -l '"use server"' "$DIR" -g "*.ts" -g "*.tsx" 2>/dev/null || true)

for file in $ACTION_FILES; do
    [[ -z "$file" ]] && continue
    if ! has_auth "$file"; then
        report "HIGH" "Server Action file without recognized auth/signature check" "$file"
    fi
done

echo "=== HIGH: API routes without recognized auth ==="
echo ""

API_ROUTES=$(find "$DIR" \( -path "*/app/api/*" -name "route.ts" -o -path "*/app/api/*" -name "route.js" \) 2>/dev/null || true)

for file in $API_ROUTES; do
    [[ -z "$file" ]] && continue
    # Public routes — skip if path suggests intentional public access
    if echo "$file" | grep -qiE '(signup|contact|revalidate|draft-mode|sitemap)'; then
        if ! has_auth "$file" && ! rg -q '(safeParse|parseSignup|z\.object|Zod)' "$file" 2>/dev/null; then
            report "MEDIUM" "Public API route — verify validation and rate limiting" "$file"
        fi
        continue
    fi
    if ! has_auth "$file"; then
        report "HIGH" "API route without recognized auth or signature check" "$file"
    fi
done

echo "=== MEDIUM: Middleware ==="
echo ""

MIDDLEWARE_FILE="$DIR/middleware.ts"
if [[ -f "$MIDDLEWARE_FILE" ]]; then
    if ! rg -q 'matcher' "$MIDDLEWARE_FILE" 2>/dev/null; then
        report "MEDIUM" "Middleware without matcher (applies to all routes)" "$MIDDLEWARE_FILE"
    fi
fi

echo "=== MEDIUM: dangerouslySetInnerHTML ==="
echo ""

while IFS=: read -r file line _; do
    [[ -z "$file" ]] && continue
    report "MEDIUM" "dangerouslySetInnerHTML (XSS risk if unsanitized)" "$file" "$line"
done < <(rg -n --no-heading 'dangerouslySetInnerHTML' "$DIR" -g "*.tsx" -g "*.jsx" 2>/dev/null || true)

echo "=== LOW: Security headers ==="
echo ""

for NEXT_CONFIG in "$DIR/next.config.js" "$DIR/next.config.mjs" "$DIR/next.config.ts"; do
    [[ -f "$NEXT_CONFIG" ]] || continue
    if ! rg -q 'headers' "$NEXT_CONFIG" 2>/dev/null; then
        report "LOW" "No security headers in next.config" "$NEXT_CONFIG"
    fi
done

echo "=== SUMMARY ==="
if [[ $FOUND -gt 0 ]]; then
    echo "[!] Found $FOUND potential issues. Run security-audit review to confirm and fix."
    exit 1
else
    echo "[✓] No obvious issues detected. Manual audit still recommended."
    exit 0
fi
