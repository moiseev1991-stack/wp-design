#!/usr/bin/env bash
# neve.sh — Switch to Neve theme + full redesign
# Run inside wp-design-web: docker exec wp-design-web bash -c "bash /tmp/neve.sh"

set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
success() { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
step()    { echo -e "\n${BOLD}${CYAN}══> $1${NC}"; }
die()     { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

WP="wp --allow-root"
cd /var/www/html
$WP core is-installed 2>/dev/null || die "WordPress not found."

# ═══════════════════════════════════════════════════
# STEP 1 — Install & activate Neve
# ═══════════════════════════════════════════════════
step "Installing Neve theme"

if $WP theme is-installed neve 2>/dev/null; then
    $WP theme activate neve
    warn "Neve already installed — activated"
else
    $WP theme install neve --activate 2>/dev/null && success "Neve installed" || {
        warn "Direct install failed — trying zip..."
        curl -sL --max-time 60 "https://downloads.wordpress.org/theme/neve.zip" -o /tmp/neve.zip
        $WP theme install /tmp/neve.zip --activate && success "Neve installed (zip)" || die "Could not install Neve"
        rm -f /tmp/neve.zip
    }
fi

# Remove broken themes / custom CSS from Kadence
step "Removing old theme data"
$WP theme delete kadence  2>/dev/null && success "Kadence deleted" || warn "Kadence not found"
$WP theme delete astra    2>/dev/null || true

# Remove all old custom CSS posts
$WP eval '
foreach (["astra","kadence","neve"] as $s) {
    $p = wp_get_custom_css_post($s);
    if ($p) { wp_delete_post($p->ID, true); echo "Deleted CSS post for $s\n"; }
}
' 2>/dev/null || true

# ═══════════════════════════════════════════════════
# STEP 2 — Configure Neve via theme mods
# ═══════════════════════════════════════════════════
step "Configuring Neve settings"

$WP eval '
// ── Container width ────────────────────────────────────
set_theme_mod("neve_container_width",       1120);
set_theme_mod("neve_single_content_width",  1120);

// ── Blog archive layout ────────────────────────────────
set_theme_mod("neve_blog_archive_layout",   "grid");
set_theme_mod("neve_grid_layout",           "1");   // 1=default grid
set_theme_mod("neve_blog_grid_columns",     3);

// Blog card elements
set_theme_mod("neve_enable_card_style", 1);

// ── Colours (simple theme mods — neve_global_colors is PHP-array-only, skip it) ──
set_theme_mod("neve_link_color",                "#2d6a4f");
set_theme_mod("neve_text_color",                "#1a1a2e");
set_theme_mod("neve_form_fields_background_color", "#ffffff");
delete_option("neve_global_colors"); // ensure no stale broken value

// ── Typography ─────────────────────────────────────────
set_theme_mod("neve_body_font_family",      "DM Sans");
set_theme_mod("neve_headings_font_family",  "Playfair Display");
set_theme_mod("neve_body_font_size", json_encode([
    "mobile" => 16, "tablet" => 16, "desktop" => 17
]));

// ── Header ─────────────────────────────────────────────
set_theme_mod("neve_header_background_color", "#ffffff");
// hfg_header_layout_v2 intentionally not set — Neve default layout is fine

// ── Footer ─────────────────────────────────────────────
set_theme_mod("neve_footer_bg_color", "#1a2e1a");
set_theme_mod("neve_footer_text_color", "rgba(255,255,255,0.6)");

echo "All Neve settings applied.\n";
'
success "Neve configured"

# ═══════════════════════════════════════════════════
# STEP 3 — Custom CSS
# ═══════════════════════════════════════════════════
step "Writing custom CSS"

cat > /tmp/neve_custom.css << 'CSS_EOF'
@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;700;900&family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;0,9..40,600;1,9..40,400&display=swap');

/* ── Variables ── */
:root {
  --green:       #2d6a4f;
  --green-light: #52b788;
  --green-pale:  #f0f7f4;
  --green-dark:  #1b4332;
  --gold:        #d4a843;
  --gold-hover:  #e8c065;
  --text:        #1a1a2e;
  --text-muted:  #6b7280;
  --bg:          #f7f7f5;
  --white:       #ffffff;
  --border:      #e5e7eb;
  --radius:      16px;
  --shadow:      0 2px 16px rgba(0,0,0,0.07);
  --shadow-h:    0 8px 32px rgba(45,106,79,0.14);
  --font-head:   'Playfair Display', Georgia, serif;
  --font-body:   'DM Sans', system-ui, sans-serif;
}

/* ── Base ── */
html, body {
  font-family: var(--font-body) !important;
  background: var(--bg) !important;
  color: var(--text) !important;
  font-size: 17px !important;
  line-height: 1.75 !important;
  -webkit-font-smoothing: antialiased !important;
}
h1,h2,h3,h4,h5,h6,.entry-title {
  font-family: var(--font-head) !important;
  color: var(--text) !important;
  line-height: 1.25 !important;
  letter-spacing: -0.02em !important;
}
a { color: var(--green) !important; text-decoration: none !important; transition: color .2s; }
a:hover { color: var(--green-dark) !important; }

/* ── Animated background blobs ── */
@keyframes blob1 {
  0%,100% { transform: translate(0,0) scale(1); }
  33%      { transform: translate(28px,-36px) scale(1.07); }
  66%      { transform: translate(-18px,24px) scale(.95); }
}
@keyframes blob2 {
  0%,100% { transform: translate(0,0) scale(1); }
  33%      { transform: translate(-30px,20px) scale(1.05); }
  66%      { transform: translate(16px,-28px) scale(.97); }
}
@keyframes blob3 {
  0%,100% { transform: translate(0,0) scale(1); }
  50%      { transform: translate(12px,30px) scale(1.04); }
}
body { position: relative !important; overflow-x: hidden !important; }
body::before {
  content: '' !important;
  position: fixed !important; inset: 0 !important;
  background:
    radial-gradient(ellipse 65% 55% at 10% 16%, rgba(45,106,79,.07) 0%, transparent 60%),
    radial-gradient(ellipse 58% 50% at 90% 82%, rgba(82,183,136,.055) 0%, transparent 55%),
    radial-gradient(ellipse 48% 38% at 52% 48%, rgba(212,168,67,.025) 0%, transparent 60%) !important;
  pointer-events: none !important; z-index: 0 !important;
}
body::after {
  content: '' !important; position: fixed !important;
  top: -110px !important; left: -110px !important;
  width: 500px !important; height: 500px !important;
  border-radius: 50% !important;
  background: radial-gradient(circle, rgba(45,106,79,.09) 0%, transparent 70%) !important;
  animation: blob1 18s ease-in-out infinite !important;
  pointer-events: none !important; z-index: 0 !important;
}
#page::before {
  content: '' !important; position: fixed !important;
  bottom: -90px !important; right: -90px !important;
  width: 460px !important; height: 460px !important;
  border-radius: 50% !important;
  background: radial-gradient(circle, rgba(82,183,136,.07) 0%, transparent 70%) !important;
  animation: blob2 22s ease-in-out infinite !important;
  pointer-events: none !important; z-index: 0 !important;
}
#page::after {
  content: '' !important; position: fixed !important;
  top: 38% !important; left: 58% !important;
  width: 320px !important; height: 320px !important;
  border-radius: 50% !important;
  background: radial-gradient(circle, rgba(212,168,67,.045) 0%, transparent 70%) !important;
  animation: blob3 26s ease-in-out infinite !important;
  pointer-events: none !important; z-index: 0 !important;
}
#page,#masthead,.site-header,.neve-main,.site-footer,
.nv-content-wrap,.nv-sidebar-wrap { position: relative !important; z-index: 1 !important; }

/* ── Neve container ── */
.container,
.neve-main > .container,
.neve-main > .container-fluid {
  max-width: 1120px !important;
  padding-left: 24px !important; padding-right: 24px !important;
  box-sizing: border-box !important;
}

/* ── Header ── */
.header--row,
.header-menu-sidebar,
.hfg-row-inner {
  max-width: 1120px !important;
  margin: 0 auto !important;
  padding: 0 24px !important;
  box-sizing: border-box !important;
}
.site-header,.header-main-inner,
.hfg_header,.hfg-header,
header.hfg_header {
  background: var(--white) !important;
  border-bottom: 1px solid var(--border) !important;
  box-shadow: 0 1px 12px rgba(0,0,0,.05) !important;
}
.site-logo .custom-logo,
.site-logo .site-title,
.builder-item--logo .site-title {
  font-family: var(--font-head) !important;
  font-size: 24px !important; font-weight: 900 !important;
  color: var(--green) !important; letter-spacing: -.03em !important;
}
.builder-item--logo a { color: var(--green) !important; }

.nv-nav-wrap a,
.header--row .nv-nav-wrap a,
li.menu-item a,
.primary-menu-ul a {
  font-family: var(--font-body) !important;
  font-size: 15px !important; font-weight: 500 !important;
  color: var(--text) !important;
  padding: 6px 14px !important; border-radius: 8px !important;
  transition: all .18s !important;
}
.nv-nav-wrap a:hover,
li.menu-item a:hover,
.primary-menu-ul a:hover {
  background: var(--green-pale) !important; color: var(--green) !important;
}

/* ── Blog archive grid ── */
.posts-wrapper {
  display: grid !important;
  grid-template-columns: repeat(3, 1fr) !important;
  gap: 28px !important; align-items: start !important;
}

/* Neve card */
article.layout-grid {
  background: var(--white) !important;
  border-radius: var(--radius) !important;
  overflow: hidden !important;
  box-shadow: var(--shadow) !important;
  border: 1px solid var(--border) !important;
  transition: transform .25s ease, box-shadow .25s ease, border-color .25s ease !important;
  display: flex !important; flex-direction: column !important;
  width: 100% !important;   /* prevent collapsing */
}
article.layout-grid:hover {
  transform: translateY(-5px) !important;
  box-shadow: var(--shadow-h) !important;
  border-color: rgba(45,106,79,.2) !important;
}

/* Neve thumbnail */
article.layout-grid .nv-post-thumbnail-wrap {
  display: block !important; overflow: hidden !important;
  border-radius: var(--radius) var(--radius) 0 0 !important;
}
article.layout-grid .nv-post-thumbnail-wrap img {
  width: 100% !important; height: 220px !important;
  object-fit: cover !important; display: block !important;
  border-radius: 0 !important;
  transition: transform .4s ease !important;
}
article.layout-grid:hover .nv-post-thumbnail-wrap img {
  transform: scale(1.06) !important;
}

/* Neve card body */
article.layout-grid .nv-card-content-padding {
  padding: 22px 24px 28px !important; flex: 1 !important;
}
article.layout-grid .entry-title {
  font-size: 19px !important; font-weight: 700 !important;
  line-height: 1.35 !important; margin-bottom: 10px !important;
}
article.layout-grid .entry-title a { color: var(--text) !important; }
article.layout-grid .entry-title a:hover { color: var(--green) !important; }

.nv-meta-list { font-size: 13px !important; color: var(--text-muted) !important; margin-bottom: 10px !important; }

/* More-link button */
.nv-read-more-wrap a,
article .more-link {
  display: inline-flex !important; align-items: center !important; gap: 5px !important;
  color: var(--green) !important; font-weight: 600 !important; font-size: 14px !important;
  border: 1.5px solid var(--green) !important; border-radius: 50px !important;
  padding: 7px 18px !important; transition: all .2s !important;
  background: transparent !important; box-shadow: none !important;
  margin-top: 12px !important;
}
.nv-read-more-wrap a:hover,
article .more-link:hover {
  background: var(--green) !important; color: var(--white) !important;
}

/* Pagination */
.neve-pagination,
.pagination { margin-top: 48px !important; text-align: center !important; }
.neve-pagination a,.neve-pagination span,
.page-numbers {
  border-radius: 8px !important;
  padding: 8px 14px !important;
  border: 1px solid var(--border) !important;
  margin: 0 3px !important;
  font-size: 14px !important;
  font-weight: 600 !important;
}
.current.page-numbers {
  background: var(--green) !important;
  color: var(--white) !important;
  border-color: var(--green) !important;
}

/* ── Single post ── */
.single-post .nv-single-post-wrap {
  max-width: 760px !important; margin: 0 auto !important;
}
.single-post .entry-title {
  font-size: clamp(28px, 4vw, 46px) !important;
  font-weight: 900 !important; line-height: 1.2 !important;
  margin-bottom: 16px !important;
}
.single-post .nv-thumb-wrap {
  border-radius: var(--radius) !important; overflow: hidden !important;
  margin-bottom: 40px !important; box-shadow: var(--shadow) !important;
}
.single-post .nv-thumb-wrap img {
  width: 100% !important; height: 460px !important;
  object-fit: cover !important; display: block !important;
}
.single-post .entry-content {
  font-size: 17px !important; line-height: 1.82 !important; color: #2a2a3e !important;
}
.single-post .entry-content h2 {
  font-size: 26px !important; font-weight: 800 !important;
  margin: 52px 0 18px !important;
  padding-left: 18px !important; border-left: 4px solid var(--green) !important;
}
.single-post .entry-content h3 {
  font-size: 20px !important; font-weight: 700 !important;
  margin: 32px 0 14px !important; color: var(--green-dark) !important;
}
.single-post .entry-content ul li::marker { color: var(--green) !important; }
.single-post .entry-content strong { color: var(--green-dark) !important; }

/* ── Polecamy inline (in posts) ── */
.polecamy-inline {
  background: linear-gradient(135deg, #f0f7f4, #e8f5e9) !important;
  border: 2px solid rgba(45,106,79,.18) !important;
  border-radius: var(--radius) !important;
  padding: 28px 36px !important; margin: 44px 0 !important;
  position: relative !important; overflow: hidden !important;
}
.polecamy-inline::after {
  content: '🎲'; position: absolute; font-size: 60px; opacity: .12;
  right: 20px; top: 50%; transform: translateY(-50%); pointer-events: none;
}
.polecamy-inline strong {
  display: block !important; font-size: 16px !important;
  color: var(--green) !important; margin-bottom: 6px !important;
}
.polecamy-inline a { color: var(--green) !important; font-weight: 700 !important; text-decoration: underline !important; }

/* ── Hero ── */
.hero-wrap {
  background: linear-gradient(135deg, #e8f5e9 0%, #f0f7f4 60%, #e3f2fd 100%) !important;
  border-radius: var(--radius) !important;
  padding: 72px 64px !important; margin: 32px 0 48px !important;
  position: relative !important; overflow: hidden !important;
  border: 1px solid rgba(45,106,79,.1) !important;
}
.hero-wrap::before {
  content: '🛋️'; position: absolute; font-size: 150px; line-height: 1;
  opacity: .055; right: 40px; top: 20px; pointer-events: none; transform: rotate(8deg);
}
.hero-wrap h1 {
  font-size: clamp(30px, 4.5vw, 52px) !important;
  font-weight: 900 !important; line-height: 1.15 !important;
  max-width: 680px !important; margin-bottom: 20px !important;
}
.hero-wrap p {
  font-size: 18px !important; color: var(--text-muted) !important;
  max-width: 520px !important; margin-bottom: 36px !important;
}

/* ── Polecamy block (homepage) ── */
.polecamy-block {
  background: linear-gradient(135deg, var(--green-dark) 0%, var(--green) 100%) !important;
  border-radius: var(--radius) !important;
  padding: 48px 56px !important; margin: 48px 0 !important;
  position: relative !important; overflow: hidden !important;
  color: var(--white) !important;
}
.polecamy-block::before {
  content: '🏆'; position: absolute; font-size: 170px; line-height: 1;
  opacity: .07; right: -10px; top: -20px; pointer-events: none;
}
.polecamy-block h2,.polecamy-block h3 {
  color: var(--white) !important; font-size: 30px !important; margin-bottom: 14px !important;
}
.polecamy-block p {
  color: rgba(255,255,255,.85) !important;
  font-size: 17px !important; max-width: 520px !important; margin-bottom: 28px !important;
}
.polecamy-block a {
  display: inline-block !important; background: var(--gold) !important;
  color: #1a1a2e !important; font-weight: 700 !important; font-size: 16px !important;
  padding: 14px 36px !important; border-radius: 50px !important;
  box-shadow: 0 4px 18px rgba(212,168,67,.4) !important; transition: all .2s !important;
}
.polecamy-block a:hover { background: var(--gold-hover) !important; color: #1a1a2e !important; transform: translateY(-2px) !important; }

/* ── Buttons ── */
.wp-block-button__link,
.nv-btn, button.btn,
.button, a.button {
  background: var(--green) !important; color: var(--white) !important;
  border-radius: 50px !important; padding: 13px 30px !important;
  font-family: var(--font-body) !important; font-weight: 600 !important; font-size: 15px !important;
  border: none !important; display: inline-block !important;
  transition: all .22s ease !important; box-shadow: 0 4px 14px rgba(45,106,79,.22) !important;
}
.wp-block-button__link:hover,.nv-btn:hover {
  background: var(--green-dark) !important; color: var(--white) !important;
  transform: translateY(-2px) !important; box-shadow: 0 8px 24px rgba(45,106,79,.3) !important;
}

/* ── Sidebar ── */
.nv-sidebar-wrap .widget,
aside.widget-area .widget {
  background: var(--white) !important; border-radius: var(--radius) !important;
  padding: 24px !important; margin-bottom: 24px !important;
  box-shadow: var(--shadow) !important; border: 1px solid var(--border) !important;
}
.widget-title,.widgettitle {
  font-family: var(--font-head) !important; font-size: 17px !important;
  font-weight: 700 !important; padding-bottom: 12px !important;
  margin-bottom: 16px !important; border-bottom: 2px solid var(--green) !important;
}

/* ── Footer ── */
.site-footer, footer.site-footer,
.footer-widget-area, .footer-bottom-inner {
  background: #1a2e1a !important;
  color: rgba(255,255,255,.65) !important;
}
.site-footer a,footer.site-footer a { color: rgba(255,255,255,.65) !important; }
.site-footer a:hover,footer.site-footer a:hover { color: var(--green-light) !important; }
.nv-footer-content {
  font-size: 13px !important; color: rgba(255,255,255,.4) !important;
  text-align: center !important; padding: 20px 0 !important;
  border-top: 1px solid rgba(255,255,255,.08) !important;
}

/* ── Page title ── */
.nv-page-title-wrap .nv-page-title {
  font-family: var(--font-head) !important;
  font-size: clamp(28px, 4vw, 48px) !important;
  font-weight: 900 !important; color: var(--text) !important;
  padding: 48px 0 36px !important;
}
.page-title-section {
  background: var(--green-pale) !important;
  border-bottom: 1px solid rgba(45,106,79,.12) !important;
}

/* ── Mobile ── */
@media (max-width: 900px) {
  .posts-wrapper { grid-template-columns: repeat(2,1fr) !important; }
  .hero-wrap { padding: 48px 32px !important; }
  .polecamy-block { padding: 40px 32px !important; }
}
@media (max-width: 640px) {
  .container, .neve-main > .container { padding-left: 16px !important; padding-right: 16px !important; }
  .posts-wrapper { grid-template-columns: 1fr !important; gap: 20px !important; }
  .hero-wrap { padding: 36px 20px !important; border-radius: 12px !important; }
  .hero-wrap h1 { font-size: 26px !important; }
  .polecamy-block { padding: 28px 20px !important; border-radius: 12px !important; }
  .single-post .nv-thumb-wrap img { height: 220px !important; }
  body::after { width: 260px !important; height: 260px !important; top: -70px !important; left: -70px !important; }
  #page::before { width: 240px !important; height: 240px !important; }
  #page::after { display: none !important; }
}
CSS_EOF

$WP eval '
$css = file_get_contents("/tmp/neve_custom.css");
$result = wp_update_custom_css_post($css, ["stylesheet" => "neve"]);
if (is_wp_error($result)) { die("CSS error: " . $result->get_error_message() . "\n"); }
echo "CSS applied (post ID: " . $result->ID . ", bytes: " . strlen($css) . ")\n";
'
success "CSS applied"

# ═══════════════════════════════════════════════════
# STEP 4 — Menu location
# ═══════════════════════════════════════════════════
step "Assigning menu to primary location"

MENU_ID=$($WP menu list --format=csv --fields=term_id,name 2>/dev/null | tail -n +2 | head -1 | cut -d',' -f1)
if [[ -n "$MENU_ID" ]]; then
    $WP menu location assign "$MENU_ID" primary 2>/dev/null && success "Menu $MENU_ID → primary" || \
    $WP eval "set_theme_mod('nav_menu_locations', array_merge((array)get_theme_mod('nav_menu_locations',[]), ['primary'=>$MENU_ID]));" 2>/dev/null || \
    warn "Could not assign menu — do it manually"
else
    warn "No menu found — skipping"
fi

# ═══════════════════════════════════════════════════
# STEP 5 — Update sidebar widget
# ═══════════════════════════════════════════════════
step "Updating casino widget in sidebar"

# Neve uses sidebar-1 by default
WIDGET_HTML='<div style="background:linear-gradient(135deg,#1b4332,#2d6a4f);border-radius:16px;padding:24px;color:#fff;overflow:hidden;">
  <div style="font-family:Playfair Display,serif;font-size:17px;font-weight:700;color:#d4a843;border-bottom:2px solid #d4a843;padding-bottom:12px;margin-bottom:16px;">🏆 Polecane Kasyno</div>
  <p style="color:rgba(255,255,255,.88);font-size:15px;margin-bottom:16px;"><strong style="color:#fff;">Vulkan Kasyno</strong> – bonus do 4000 PLN + 200 free spinów!</p>
  <a href="https://vulkankasyno.pl" rel="sponsored" target="_blank" style="display:inline-block;background:#d4a843;color:#1a1a2e;font-weight:700;font-size:14px;padding:10px 24px;border-radius:50px;text-decoration:none;">Odbierz bonus →</a>
</div>'

for SIDEBAR in sidebar-1 neve-right-sidebar; do
    EXISTING=$($WP widget list "$SIDEBAR" --format=csv 2>/dev/null | grep "custom_html" | wc -l)
    if [[ "$EXISTING" -gt 0 ]]; then
        warn "Widget exists in $SIDEBAR — skipping"
    else
        $WP widget add custom_html "$SIDEBAR" 1 --content="$WIDGET_HTML" 2>/dev/null && \
            success "Casino widget added to $SIDEBAR" && break || true
    fi
done

# ═══════════════════════════════════════════════════
# STEP 6 — Flush
# ═══════════════════════════════════════════════════
step "Flushing"
$WP rewrite flush 2>/dev/null || true
$WP cache flush   2>/dev/null || true

echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║   Neve theme active — redesign complete!     ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Site:${NC}  http://localhost:8080"
echo -e "${CYAN}Admin:${NC} http://localhost:8080/wp-admin"
echo ""
echo -e "${YELLOW}Active theme:${NC} $($WP theme list --status=active --field=name 2>/dev/null)"
