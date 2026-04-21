#!/usr/bin/env bash
# featured-images.sh — Download casino images and set as featured images
# Run inside wp-design-web: docker exec wp-design-web bash /tmp/featured-images.sh

set -uo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
success() { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
step()    { echo -e "\n${BOLD}${CYAN}══> $1${NC}"; }

WP="wp --allow-root"
cd /var/www/html

# Post IDs => image URL + filename
# Using Unsplash direct image IDs (free/public domain)
declare -A POST_IMAGES
POST_IMAGES[80]="https://images.unsplash.com/photo-1596838132731-3301c3fd4317?w=800&q=80|vulkan-kasyno.jpg"
POST_IMAGES[81]="https://images.unsplash.com/photo-1518895312237-a9e23508077d?w=800&q=80|kasyna-ranking.jpg"
POST_IMAGES[82]="https://images.unsplash.com/photo-1601987077677-5346c463c823?w=800&q=80|sloty-online.jpg"
POST_IMAGES[83]="https://images.unsplash.com/photo-1606167668584-78701c57f13d?w=800&q=80|bonus-bez-depozytu.jpg"
POST_IMAGES[84]="https://images.unsplash.com/photo-1541278107931-e006523892df?w=800&q=80|ruletka-online.jpg"
POST_IMAGES[85]="https://images.unsplash.com/photo-1529480038880-5fc8b76a24f2?w=800&q=80|blackjack-online.jpg"
POST_IMAGES[86]="https://images.unsplash.com/photo-1511193311914-0346f16efe90?w=800&q=80|kasyna-mobilne.jpg"
POST_IMAGES[87]="https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?w=800&q=80|szybkie-wyplaty.jpg"
POST_IMAGES[88]="https://images.unsplash.com/photo-1586348943529-beaae6c28db9?w=800&q=80|jackpot-progresywny.jpg"
POST_IMAGES[89]="https://images.unsplash.com/photo-1620714223084-8fcacc2dfd4d?w=800&q=80|program-vip.jpg"

step "Downloading images and setting featured images"

for POST_ID in "${!POST_IMAGES[@]}"; do
    IFS='|' read -r URL FILENAME <<< "${POST_IMAGES[$POST_ID]}"

    LOCAL="/tmp/$FILENAME"

    # Download image
    if curl -sL --max-time 30 --fail "$URL" -o "$LOCAL" 2>/dev/null; then
        SIZE=$(stat -c%s "$LOCAL" 2>/dev/null || echo "0")
        if [[ "$SIZE" -lt 5000 ]]; then
            warn "Image too small ($SIZE bytes), skipping post $POST_ID"
            rm -f "$LOCAL"
            continue
        fi

        # Import into WP media library
        ATTACH_ID=$($WP media import "$LOCAL" \
            --post_id="$POST_ID" \
            --title="$(basename "$FILENAME" .jpg)" \
            --porcelain 2>/dev/null)

        if [[ -n "$ATTACH_ID" ]]; then
            # Set as featured image
            $WP post meta update "$POST_ID" _thumbnail_id "$ATTACH_ID" 2>/dev/null
            success "Post $POST_ID → image set (attach ID: $ATTACH_ID)"
        else
            warn "Could not import image for post $POST_ID"
        fi

        rm -f "$LOCAL"
    else
        warn "Failed to download image for post $POST_ID: $URL"
    fi
done

step "Done!"
echo -e "\n${GREEN}${BOLD}✓ Featured images set for all posts!${NC}"
echo -e "${CYAN}  → Check http://localhost:8080${NC}\n"
