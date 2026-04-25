#!/usr/bin/env bash
#
# fetch-client-logos.sh — Download client logos for clients.html
#
# Usage:
#   cd /Users/tallapa/obvez-website
#   chmod +x fetch-client-logos.sh
#   ./fetch-client-logos.sh
#
# What it does:
#   Tries multiple sources per company (in priority order) and saves the first
#   one that looks like a real logo (>= 1KB, non-error HTTP status).
#
#   Priority:
#     1. Clearbit logo API — https://logo.clearbit.com/{domain}  (clean PNG, usually transparent)
#     2. Direct apple-touch-icon (largest site-provided icon, usually 180×180)
#     3. Direct /favicon.svg (vector if available)
#     4. Direct /favicon.ico (last-resort raster)
#     5. Google's favicon service at 256px (always works if domain exists)
#
#   All files land in /Users/tallapa/obvez-website/clients/{slug}.{ext}
#   Slugs match what clients.html expects.
#
# Requirements: curl, file (both ship with macOS).

set -u

OUT_DIR="$(cd "$(dirname "$0")" && pwd)/clients"
mkdir -p "$OUT_DIR"

LOG="$OUT_DIR/_fetch.log"
: > "$LOG"

UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

# ---------- helpers ----------

# Try a URL; if it returns HTTP 200 and the response is > MIN_BYTES, save it.
# Sets $SAVED=path on success, empty on failure.
MIN_BYTES=800
try_url() {
  local url="$1" out_base="$2"
  local tmp="$out_base.tmp"
  local code
  code=$(curl -sL -A "$UA" --max-time 15 -o "$tmp" -w "%{http_code}" "$url" 2>/dev/null || echo "000")
  if [ "$code" != "200" ]; then
    rm -f "$tmp"
    return 1
  fi
  local size
  size=$(wc -c < "$tmp" | tr -d ' ')
  if [ "$size" -lt "$MIN_BYTES" ]; then
    rm -f "$tmp"
    return 1
  fi
  # Detect real type
  local mime ext
  mime=$(file -b --mime-type "$tmp")
  case "$mime" in
    image/svg+xml) ext="svg" ;;
    image/png)     ext="png" ;;
    image/jpeg)    ext="jpg" ;;
    image/x-icon|image/vnd.microsoft.icon) ext="ico" ;;
    image/webp)    ext="webp" ;;
    *)             rm -f "$tmp"; return 1 ;;
  esac
  local final="$out_base.$ext"
  mv "$tmp" "$final"
  SAVED="$final"
  return 0
}

# fetch SLUG DOMAIN  (+ optional extra_urls "url1|url2")
fetch() {
  local slug="$1" domain="$2" extras="${3:-}"
  local out_base="$OUT_DIR/$slug"

  # Skip if we already have a non-ICO file for this slug
  if ls "$out_base".{svg,png,jpg,webp} 2>/dev/null | head -n 1 | grep -q .; then
    echo "  ✓ already have $slug — skipping"
    echo "SKIP $slug (already have file)" >> "$LOG"
    return 0
  fi

  SAVED=""

  # Priority order — try each URL
  local urls=(
    "https://logo.clearbit.com/$domain"
    "https://$domain/apple-touch-icon.png"
    "https://www.$domain/apple-touch-icon.png"
    "https://$domain/apple-touch-icon-precomposed.png"
    "https://$domain/favicon.svg"
    "https://www.$domain/favicon.svg"
    "https://$domain/assets/images/logo.png"
    "https://$domain/images/logo.png"
    "https://$domain/img/logo.png"
    "https://$domain/logo.png"
    "https://$domain/favicon.ico"
    "https://www.$domain/favicon.ico"
  )

  # Inject caller-supplied extras at the top (right after Clearbit)
  if [ -n "$extras" ]; then
    local injected=()
    injected+=("${urls[0]}")   # Clearbit first
    IFS='|' read -r -a extra_arr <<< "$extras"
    for u in "${extra_arr[@]}"; do injected+=("$u"); done
    for u in "${urls[@]:1}"; do injected+=("$u"); done
    urls=("${injected[@]}")
  fi

  for url in "${urls[@]}"; do
    if try_url "$url" "$out_base"; then
      echo "  ✓ $slug  ←  $url  →  $(basename "$SAVED")"
      echo "OK   $slug  $(basename "$SAVED")  $url" >> "$LOG"
      return 0
    fi
  done

  # Last-resort fallback: Google s2 (always returns something)
  local gurl="https://www.google.com/s2/favicons?domain=$domain&sz=256"
  if try_url "$gurl" "$out_base"; then
    echo "  ~ $slug  ←  google s2 (fallback)  →  $(basename "$SAVED")"
    echo "FB   $slug  $(basename "$SAVED")  $gurl" >> "$LOG"
    return 0
  fi

  echo "  ✗ $slug  —  NOTHING WORKED ($domain)"
  echo "FAIL $slug  $domain" >> "$LOG"
  return 1
}

# ---------- companies (26) ----------

echo "Fetching logos to $OUT_DIR"
echo ""

fetch alcedo-pharmaceuticals        alcedo.co.in
fetch apl-research-center           aurobindo.com
fetch archiesh                      archeeshhealth.com
fetch aurobindo-pharma              aurobindo.com
fetch bharath-parenterals           bplindia.in
fetch biological-e                  biologicale.com
fetch brawn-laboratory              brawnlabs.in
fetch chromo-laboratories           chromolabs.com
fetch clininvent                    tcgls.com   "https://www.tcgls.com/clininvent/|https://clininvent.com/favicon.ico"
fetch dr-reddys                     drreddys.com
fetch enal-drugs                    enaldrugs.com
fetch finiso-pharma                 finoso.com
fetch gland-pharma                  glandpharma.com
fetch hetero                        hetero.com
fetch honour                        honourlab.com
fetch ichor-biologicals             ichor.in
fetch makcur                        makcur.com
fetch ritsa-pharma                  ritsapharma.com
fetch rusan-pharma                  rusanpharma.com
fetch sionc-pharma                  sioncpharmaceuticals.com
fetch sriam-labs                    sriamlabs.com       "https://sriam-labs.lookchem.com/favicon.ico"
fetch synergene-active-ingredients  synergeneapi.com
fetch taurus-pharma                 tauruspharma.com
fetch vaasava-pharmaceuticals       vaasavaa.com
fetch vhb-medisciences              vhbgroup.com        "https://vhbgroup.vistashopee.com/favicon.ico"
fetch zenotech                      zenotechlabs.com

echo ""
echo "----"
echo "Done. Log: $LOG"
echo ""
echo "Summary:"
grep -c '^OK'   "$LOG" | xargs -I{} echo "  {} logos fetched from site"
grep -c '^FB'   "$LOG" | xargs -I{} echo "  {} used Google s2 fallback"
grep -c '^FAIL' "$LOG" | xargs -I{} echo "  {} FAILED — edit the script with better URLs"
grep -c '^SKIP' "$LOG" | xargs -I{} echo "  {} skipped (already had file)"
echo ""
echo "Review visually:  open $OUT_DIR"
echo "Re-run anytime — existing non-ico files are skipped so it's idempotent."
