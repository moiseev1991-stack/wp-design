#!/usr/bin/env bash
# deploy.sh — Full deploy of wp-design on a fresh server
# Usage: bash deploy.sh example.com
# Or for local: bash deploy.sh localhost:8080

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}    $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
step() { echo -e "\n${BOLD}${CYAN}══> $1${NC}"; }

DOMAIN="${1:-}"
if [[ -z "$DOMAIN" ]]; then
  echo -e "${YELLOW}Usage: bash deploy.sh <domain>${NC}"
  echo "  Example: bash deploy.sh example.com"
  echo "  Local:   bash deploy.sh localhost:8080"
  exit 1
fi

# Determine protocol
if [[ "$DOMAIN" == localhost* ]]; then
  SITE_URL="http://$DOMAIN"
else
  SITE_URL="https://$DOMAIN"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── 1. Update docker-compose port if needed ──────────────────────────────────
step "Starting Docker containers"
if [[ "$DOMAIN" != localhost* ]]; then
  # On real server use port 80
  sed -i 's/"8080:80"/"80:80"/' "$SCRIPT_DIR/docker-compose.yml" 2>/dev/null || true
fi

docker compose -f "$SCRIPT_DIR/docker-compose.yml" up -d
ok "Containers started"

# ── 2. Wait for WordPress container to be ready ───────────────────────────────
step "Waiting for WordPress to be ready"
for i in $(seq 1 30); do
  if docker exec wp-design-web test -f /var/www/html/wp-includes/version.php 2>/dev/null; then
    ok "WordPress files ready"
    break
  fi
  echo "  Waiting... ($i/30)"
  sleep 3
done

# ── 3. Import database ────────────────────────────────────────────────────────
step "Importing database"
sleep 5  # give MySQL a moment after container start
docker exec -i wp-design-db mysql -u wordpress -pwordpress wordpress < "$SCRIPT_DIR/db-dump.sql"
ok "Database imported"

# ── 4. Copy uploads and theme ─────────────────────────────────────────────────
step "Restoring wp-content files"
docker cp "$SCRIPT_DIR/wp-content/uploads" wp-design-web:/var/www/html/wp-content/
docker exec wp-design-web chown -R www-data:www-data /var/www/html/wp-content/uploads
ok "Uploads restored"

# Restore modified neve functions.php
docker cp "$SCRIPT_DIR/neve-functions.php" wp-design-web:/var/www/html/wp-content/themes/neve/functions.php
docker exec wp-design-web chown www-data:www-data /var/www/html/wp-content/themes/neve/functions.php
ok "Theme files restored"

# ── 5. Update URLs ────────────────────────────────────────────────────────────
step "Updating site URL to $SITE_URL"
docker exec wp-design-web bash -c "
  WP='wp --allow-root'
  \$WP search-replace 'http://localhost:8080' '$SITE_URL' --skip-columns=guid --quiet
  \$WP option update siteurl '$SITE_URL'
  \$WP option update home '$SITE_URL'
  \$WP rewrite flush --hard
"
ok "URLs updated"

# ── 6. Done ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}✓ Deploy complete!${NC}"
echo -e "${CYAN}  → Site: $SITE_URL${NC}"
echo -e "${CYAN}  → Admin: $SITE_URL/wp-admin/${NC}"
echo -e "${YELLOW}  → Login: admin / admin123${NC}"
echo ""
