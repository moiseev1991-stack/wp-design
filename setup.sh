#!/usr/bin/env bash
# ============================================================
# setup.sh — WP Design (wp-design.org) Automated Setup
# ============================================================
#
# USAGE:
#   1. Upload this file to your WordPress root directory
#      (the folder containing wp-config.php)
#   2. Connect via SSH and run:
#        chmod +x setup.sh
#        ./setup.sh
#
# REQUIREMENTS:
#   - wp-cli available as 'wp' in PATH (or ~/bin/wp, or wp-cli.phar
#     in the same directory — auto-detected below)
#   - Script must run from the WordPress root directory
#   - WordPress must already be installed (wp-config.php + database)
#   - PHP 7.4+ on the server
#
# IF YOU HIT PHP MEMORY ERRORS:
#   Replace the WP_BIN line below with:
#     WP_BIN="php -d memory_limit=256M /path/to/wp-cli.phar"
#
# NOTE: This script is mostly idempotent for settings, but will
#   create duplicate posts/pages if run more than once. It will
#   prompt you if existing posts are detected.
# ============================================================

set -uo pipefail

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# ── Colors ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
step()    { echo -e "\n${BOLD}${CYAN}══> $1${NC}"; }
die()     { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ── Temp file tracking ───────────────────────────────────────
TMPFILES=()
cleanup() {
    for f in "${TMPFILES[@]:-}"; do
        [[ -f "$f" ]] && rm -f "$f"
    done
}
trap cleanup EXIT

make_tmpfile() {
    local f="/tmp/wpsetup_${RANDOM}_${RANDOM}.html"
    touch "$f"
    TMPFILES+=("$f")
    echo "$f"
}

# ── WP-CLI auto-detection ────────────────────────────────────
step "Detecting wp-cli"
if command -v wp &>/dev/null; then
    WP_BIN="wp"
elif [[ -f "$HOME/bin/wp" ]]; then
    WP_BIN="$HOME/bin/wp"
elif [[ -f "./wp-cli.phar" ]]; then
    WP_BIN="php wp-cli.phar"
else
    die "wp-cli not found. Install from https://wp-cli.org/ and place 'wp' in PATH."
fi
WP="$WP_BIN --allow-root"
success "wp-cli: $WP_BIN"

# ── Pre-flight checks ─────────────────────────────────────────
step "Pre-flight checks"

[[ -f "wp-config.php" ]] || die "wp-config.php not found. Run this script from the WordPress root directory."

if ! $WP core is-installed 2>/dev/null; then
    die "WordPress is not installed or wp-cli cannot connect to the database. Check wp-config.php."
fi

WP_VERSION=$($WP core version)
success "WordPress $WP_VERSION is installed"

POST_COUNT=$($WP post list --post_type=post --post_status=publish --format=count 2>/dev/null || echo "0")
if [[ "$POST_COUNT" -gt "0" ]]; then
    warn "Found $POST_COUNT existing published post(s). Running again will create duplicates."
    read -r -p "Continue anyway? [y/N] " reply
    echo
    [[ "$reply" =~ ^[Yy]$ ]] || { info "Aborted."; exit 0; }
fi

# ═════════════════════════════════════════════════════════════
# SECTION 3 — Core WordPress Settings
# ═════════════════════════════════════════════════════════════
step "Configuring core WordPress settings"

$WP option update blogname "WP Design"
$WP option update blogdescription "Inspiracje, porady i trendy dla Twojego domu"
$WP option update timezone_string "Europe/Warsaw"
$WP option update WPLANG "pl_PL"
$WP option update posts_per_page 10
$WP option update blog_public 1
$WP option update permalink_structure "/%postname%/"
$WP rewrite flush --hard 2>/dev/null || warn ".htaccess could not be written — flush permalinks manually in WP Admin → Settings → Permalinks"

$WP language core install pl_PL --activate 2>/dev/null || warn "Language pack install failed (may already be installed or no network access)"

success "Core settings applied"

# ═════════════════════════════════════════════════════════════
# SECTION 4 — Theme: Install Astra, Remove Others
# ═════════════════════════════════════════════════════════════
step "Installing Astra theme"

if $WP theme is-installed astra 2>/dev/null; then
    $WP theme activate astra
    warn "Astra already installed — activated"
else
    $WP theme install astra --activate
    success "Astra installed and activated"
fi

step "Removing unnecessary themes"
while IFS= read -r theme_name; do
    if [[ "$theme_name" != "astra" && "$theme_name" != "twentytwentyfour" ]]; then
        $WP theme delete "$theme_name" 2>/dev/null && success "Deleted theme: $theme_name" || warn "Could not delete theme: $theme_name"
    fi
done < <($WP theme list --field=name --format=csv 2>/dev/null)

# ═════════════════════════════════════════════════════════════
# SECTION 5 — Astra Theme Settings
# ═════════════════════════════════════════════════════════════
step "Configuring Astra colors, fonts and footer"

$WP eval '
$current = get_option( "astra-settings", array() );
$new = array(
    "theme-color"                     => "#2c3e50",
    "link-color"                      => "#2c3e50",
    "link-h-color"                    => "#e8b84b",
    "button-bg-color"                 => "#e8b84b",
    "button-bg-h-color"               => "#2c3e50",
    "button-color"                    => "#ffffff",
    "button-h-color"                  => "#ffffff",
    "text-color"                      => "#333333",
    "background-color"                => "#ffffff",
    "body-font-family"                => "Lato",
    "body-font-variant"               => "regular",
    "font-size-body"                  => 16,
    "headings-font-family"            => "Playfair Display",
    "headings-font-weight"            => "600",
    "display-site-title"              => true,
    "display-site-tagline"            => true,
    "header-color-site-title"         => "#2c3e50",
    "header-color-site-tagline"       => "#666666",
    "footer-sml-section-1"           => "\u00a9 2024 WP Design. Wszelkie prawa zastrze\u017cone.",
    "footer-sml-section-2"           => "Tre\u015bci na stronie maj\u0105 charakter informacyjny.",
    "footer-sml-layout"              => "footer-sml-layout-1",
    "footer-bg-obj"                  => array( "background-color" => "#2c3e50" ),
    "footer-color"                   => "#ffffff",
);
update_option( "astra-settings", array_merge( $current, $new ) );
echo "astra-settings updated.\n";
'

$WP eval '
update_option( "astra-google-fonts", array(
    "Playfair Display" => array( "600" ),
    "Lato"             => array( "400", "400italic", "700" ),
) );
echo "Google Fonts registered.\n";
'

success "Astra theme configured"

# ═════════════════════════════════════════════════════════════
# SECTION 6 — Plugins
# ═════════════════════════════════════════════════════════════
step "Installing plugins"

PLUGINS=( "wordpress-seo" "wp-super-cache" "redirection" "classic-editor" )

for plugin in "${PLUGINS[@]}"; do
    if $WP plugin is-installed "$plugin" 2>/dev/null; then
        $WP plugin activate "$plugin" 2>/dev/null && success "Activated: $plugin" || warn "Could not activate: $plugin"
    else
        $WP plugin install "$plugin" --activate 2>/dev/null && success "Installed + activated: $plugin" || warn "Failed to install: $plugin (install manually)"
    fi
done

step "Removing default plugins"
$WP plugin deactivate hello 2>/dev/null || true
$WP plugin delete hello 2>/dev/null && success "Deleted Hello Dolly" || true
$WP plugin deactivate akismet 2>/dev/null || true
$WP plugin delete akismet 2>/dev/null && success "Deleted Akismet" || true

# ═════════════════════════════════════════════════════════════
# SECTION 7 — Remove Default Content
# ═════════════════════════════════════════════════════════════
step "Removing default posts and pages"

HELLO_ID=$($WP post list --post_type=post --name=hello-world --field=ID --format=csv 2>/dev/null | head -1 || true)
if [[ -n "$HELLO_ID" ]]; then
    $WP post delete "$HELLO_ID" --force 2>/dev/null && success "Deleted Hello World post" || warn "Could not delete Hello World"
fi

SAMPLE_ID=$($WP post list --post_type=page --name=sample-page --field=ID --format=csv 2>/dev/null | head -1 || true)
if [[ -n "$SAMPLE_ID" ]]; then
    $WP post delete "$SAMPLE_ID" --force 2>/dev/null && success "Deleted Sample Page" || warn "Could not delete Sample Page"
fi

# ═════════════════════════════════════════════════════════════
# SECTION 8 — Category
# ═════════════════════════════════════════════════════════════
step "Creating category: Design i Wnętrza"

CAT_EXISTS=$($WP term list category --field=slug --format=csv 2>/dev/null | grep -c "design-i-wnetrza" || echo "0")
if [[ "$CAT_EXISTS" -eq "0" ]]; then
    DESIGN_CAT_ID=$($WP term create category "Design i Wnętrza" \
        --slug="design-i-wnetrza" \
        --description="Artykuły o designie i aranżacji wnętrz" \
        --porcelain)
    success "Created category (ID: $DESIGN_CAT_ID)"
else
    DESIGN_CAT_ID=$($WP term list category --field=term_id --format=csv 2>/dev/null | head -1)
    warn "Category already exists — using ID: $DESIGN_CAT_ID"
fi

# ═════════════════════════════════════════════════════════════
# SECTION 9 — Pages
# ═════════════════════════════════════════════════════════════
step "Creating pages"

# ── Homepage ──────────────────────────────────────────────────
HP_FILE=$(make_tmpfile)
cat > "$HP_FILE" << 'HOMEPAGE_EOF'
<div style="background:#2c3e50; padding:80px 20px; text-align:center;">
  <h1 style="color:#ffffff; font-size:2.4em; margin-bottom:20px; line-height:1.3;">
    Odkryj Inspirujące Wnętrza i&nbsp;Styl Życia
  </h1>
  <p style="color:#d0d8e0; font-size:1.15em; max-width:640px; margin:0 auto 30px;">
    WP Design to Twoje źródło inspiracji w dziedzinie designu, aranżacji wnętrz
    i nowoczesnego stylu życia. Sprawdź nasze porady i odmień swoje otoczenie.
  </p>
  <a href="/blog/"
     style="display:inline-block; background:#e8b84b; color:#2c3e50; padding:14px 36px;
            text-decoration:none; font-weight:700; border-radius:4px; font-size:1.05em;">
    Czytaj artykuły →
  </a>
</div>

<div style="background:#f8f4e8; border-left:4px solid #e8b84b; padding:30px 24px; margin:50px auto; max-width:800px; border-radius:4px;">
  <h2 style="color:#2c3e50; margin-top:0;">Polecamy dla naszych czytelników</h2>
  <p>Szukasz sprawdzonej rozrywki online? <strong>Vulkan Kasyno</strong> to platforma
  z tysiącami gier, atrakcyjnymi bonusami i błyskawicznymi wypłatami dla polskich graczy.</p>
  <a href="https://vulkankasyno.pl" rel="sponsored" target="_blank"
     style="display:inline-block; background:#2c3e50; color:#ffffff; padding:12px 28px;
            text-decoration:none; font-weight:700; border-radius:4px; margin-top:8px;">
    Sprawdź Vulkan Kasyno
  </a>
</div>

<div style="max-width:1100px; margin:50px auto; padding:0 20px;">
  <h2 style="text-align:center; color:#2c3e50; margin-bottom:8px;">Ostatnie artykuły</h2>
  <p style="text-align:center; color:#666; margin-bottom:40px;">
    Najświeższe porady i inspiracje ze świata designu
  </p>
  <p style="text-align:center; color:#888;">
    <em>(Najnowsze wpisy pojawią się tutaj automatycznie po dodaniu artykułów.)</em>
  </p>
</div>
HOMEPAGE_EOF

HOMEPAGE_ID=$($WP post create "$HP_FILE" \
    --post_type=page \
    --post_title="Strona główna" \
    --post_name="strona-glowna" \
    --post_status=publish \
    --porcelain)
success "Created homepage (ID: $HOMEPAGE_ID)"

# ── Blog page (needed for page_for_posts) ─────────────────────
BLOG_ID=$($WP post create \
    --post_type=page \
    --post_title="Blog" \
    --post_name="blog" \
    --post_status=publish \
    --post_content="" \
    --porcelain)
success "Created Blog page (ID: $BLOG_ID)"

# ── O nas ─────────────────────────────────────────────────────
ONAS_FILE=$(make_tmpfile)
cat > "$ONAS_FILE" << 'ONAS_EOF'
<h1>O nas</h1>

<p>WP Design to niezależny portal o aranżacji wnętrz, designie i stylu życia.
Od 2018 roku dostarczamy czytelnikom inspiracje, praktyczne porady
i przeglądy trendów ze świata designu.</p>

<p>Nasz zespół składa się z pasjonatów wnętrzarstwa, którzy na co dzień
śledzą światowe trendy i testują rozwiązania sprawdzające się
w polskich realiach.</p>

<h2>Co znajdziesz na WP Design?</h2>
<ul>
  <li>Poradniki aranżacji wnętrz dla różnych stylów i budżetów</li>
  <li>Przeglądy trendów sezonowych w designie i modzie wnętrzarskiej</li>
  <li>Praktyczne wskazówki dotyczące wyboru mebli, tkanin i oświetlenia</li>
  <li>Inspiracje z polskich i zagranicznych realizacji</li>
  <li>Recenzje produktów i materiałów do wnętrz</li>
</ul>

<h2>Kontakt</h2>
<p>Masz pytania lub chcesz nawiązać współpracę?<br>
Napisz do nas: <a href="mailto:redakcja@wp-design.org">redakcja@wp-design.org</a></p>
ONAS_EOF

ONAS_ID=$($WP post create "$ONAS_FILE" \
    --post_type=page \
    --post_title="O nas" \
    --post_name="o-nas" \
    --post_status=publish \
    --porcelain)
success "Created O nas page (ID: $ONAS_ID)"

# ── Kontakt ───────────────────────────────────────────────────
KONTAKT_FILE=$(make_tmpfile)
cat > "$KONTAKT_FILE" << 'KONTAKT_EOF'
<h1>Kontakt</h1>

<p>Chętnie odpowiemy na Twoje pytania i nawiążemy współpracę.</p>

<h2>Redakcja WP Design</h2>
<p><strong>E-mail:</strong> <a href="mailto:redakcja@wp-design.org">redakcja@wp-design.org</a><br>
<strong>Czas odpowiedzi:</strong> Staramy się odpowiadać w ciągu 2–3 dni roboczych.</p>

<h2>Współpraca</h2>
<p>Jeśli jesteś architektem wnętrz, projektantem lub marką związaną z designem
i chcesz nawiązać współpracę reklamową lub partnerską, napisz do nas z dopiskiem
<em>"Współpraca"</em>.</p>

<h2>Informacja dla reklamodawców</h2>
<p>Linki oznaczone atrybutem <code>rel="sponsored"</code> są linkami partnerskimi.
Współpracujemy wyłącznie z zaufanymi partnerami.</p>
KONTAKT_EOF

KONTAKT_ID=$($WP post create "$KONTAKT_FILE" \
    --post_type=page \
    --post_title="Kontakt" \
    --post_name="kontakt" \
    --post_status=publish \
    --porcelain)
success "Created Kontakt page (ID: $KONTAKT_ID)"

# ── Polityka prywatności ──────────────────────────────────────
PP_FILE=$(make_tmpfile)
cat > "$PP_FILE" << 'PP_EOF'
<h1>Polityka Prywatności</h1>
<p><em>Ostatnia aktualizacja: 1 listopada 2024</em></p>

<p>Niniejsza Polityka Prywatności opisuje, w jaki sposób WP Design
(<strong>redakcja@wp-design.org</strong>) gromadzi, wykorzystuje i chroni informacje
uzyskane od użytkowników serwisu wp-design.org.</p>

<h2>1. Administrator danych</h2>
<p>Administratorem danych osobowych jest redakcja portalu WP Design,
dostępna pod adresem: <a href="mailto:redakcja@wp-design.org">redakcja@wp-design.org</a>.</p>

<h2>2. Jakie dane zbieramy</h2>
<ul>
  <li>Dane podawane dobrowolnie w formularzach kontaktowych (imię, adres e-mail)</li>
  <li>Dane zbierane automatycznie: adres IP, typ przeglądarki, czas wizyty (logi serwera)</li>
  <li>Pliki cookies niezbędne do działania serwisu oraz analityczne (Google Analytics)</li>
</ul>

<h2>3. Cel przetwarzania danych</h2>
<p>Dane są przetwarzane w celu: odpowiedzi na zapytania, prowadzenia statystyk serwisu
oraz zapewnienia prawidłowego działania witryny. Podstawą prawną jest art. 6 ust. 1
lit. f RODO (prawnie uzasadniony interes administratora).</p>

<h2>4. Pliki cookies</h2>
<p>Serwis używa plików cookies w celu zapewnienia prawidłowego działania, zapamiętywania
preferencji użytkownika oraz zbierania anonimowych statystyk odwiedzin. Możesz zarządzać
ustawieniami cookies w swojej przeglądarce — wyłączenie cookies może ograniczyć
funkcjonalność serwisu.</p>

<h2>5. Google Analytics</h2>
<p>Korzystamy z Google Analytics do analizy ruchu na stronie. Dane są przetwarzane
anonimowo. Więcej informacji: <a href="https://policies.google.com/privacy" target="_blank" rel="noopener">Polityka prywatności Google</a>.</p>

<h2>6. Prawa użytkownika (RODO)</h2>
<p>Przysługuje Ci prawo do: dostępu do swoich danych, ich sprostowania, usunięcia,
ograniczenia przetwarzania, przenoszenia danych oraz wniesienia sprzeciwu wobec
przetwarzania. Możesz skorzystać z tych praw kontaktując się z nami:
<a href="mailto:redakcja@wp-design.org">redakcja@wp-design.org</a>.</p>

<h2>7. Linki zewnętrzne i partnerskie</h2>
<p>Serwis zawiera linki do zewnętrznych stron internetowych. Linki oznaczone
atrybutem <code>rel="sponsored"</code> są linkami partnerskimi — klikając je,
możesz opuścić nasz serwis. Nie ponosimy odpowiedzialności za treści i polityki
prywatności stron zewnętrznych.</p>

<h2>8. Zmiany polityki prywatności</h2>
<p>Zastrzegamy sobie prawo do zmian niniejszej Polityki Prywatności. Wszelkie zmiany
będą publikowane na tej stronie z aktualizowaną datą.</p>

<h2>9. Kontakt</h2>
<p>W sprawach związanych z ochroną danych osobowych prosimy o kontakt:
<a href="mailto:redakcja@wp-design.org">redakcja@wp-design.org</a></p>
PP_EOF

PP_ID=$($WP post create "$PP_FILE" \
    --post_type=page \
    --post_title="Polityka prywatności" \
    --post_name="polityka-prywatnosci" \
    --post_status=publish \
    --porcelain)
success "Created Polityka prywatności page (ID: $PP_ID)"

# ── Set static homepage ───────────────────────────────────────
step "Setting static homepage"
$WP option update show_on_front "page"
$WP option update page_on_front "$HOMEPAGE_ID"
$WP option update page_for_posts "$BLOG_ID"
success "Homepage: ID $HOMEPAGE_ID | Blog posts page: ID $BLOG_ID"

# ═════════════════════════════════════════════════════════════
# SECTION 10 — Navigation Menu
# ═════════════════════════════════════════════════════════════
step "Creating navigation menu"

MENU_ID=$($WP menu create "Główne menu" --porcelain)
success "Created menu (ID: $MENU_ID)"

$WP menu item add-custom "$MENU_ID" "Główna" "/"
$WP menu item add-custom "$MENU_ID" "Blog" "/blog/"
$WP menu item add-custom "$MENU_ID" "O nas" "/o-nas/"
$WP menu item add-custom "$MENU_ID" "Kontakt" "/kontakt/"

$WP menu location assign "$MENU_ID" primary 2>/dev/null || \
    $WP eval "set_theme_mod('nav_menu_locations', array('primary' => $MENU_ID));" && \
    success "Menu assigned to primary location"

# ═════════════════════════════════════════════════════════════
# SECTION 11 — Articles
# ═════════════════════════════════════════════════════════════
step "Creating articles (7 posts)"

SPONSORED='<div style="background:#f8f4e8; border-left:4px solid #e8b84b; padding:20px; margin:30px 0; border-radius:2px;">
  <strong>Polecamy również:</strong> Jeśli szukasz rozrywki online,
  sprawdź <a href="https://vulkankasyno.pl" rel="sponsored" target="_blank">Vulkan Kasyno</a>
  &#8211; jedna z najpopularniejszych platform hazardowych dla polskich graczy.
</div>'

# ── Article 1: Minimalizm ─────────────────────────────────────
A1=$(make_tmpfile)
cat > "$A1" << 'A1_EOF'
<p>Minimalizm to nie tylko styl aranżacji wnętrz – to filozofia życia, która zyskuje coraz
więcej zwolenników w Polsce i na całym świecie. Zasada „mniej znaczy więcej" (ang.
<em>less is more</em>) wywodzi się z modernistycznej architektury lat 20. XX wieku,
ale dziś przeżywa prawdziwy renesans.</p>

<h2>Czym jest minimalizm we wnętrzach?</h2>
<p>Minimalistyczne wnętrze charakteryzuje się przede wszystkim ograniczoną liczbą mebli
i dodatków, dominacją neutralnych barw oraz dbałością o funkcjonalność każdego elementu.
Chodzi o to, żeby każda rzecz w pomieszczeniu miała swoje uzasadnienie i cel.</p>

<h2>Podstawowe zasady minimalizmu</h2>
<ul>
  <li><strong>Ograniczona paleta kolorów</strong> – biel, szarość, beż, czerń i naturalne
      odcienie drewna to fundamenty minimalistycznego wnętrza.</li>
  <li><strong>Czyste linie</strong> – meble o prostych, geometrycznych kształtach bez
      zbędnych zdobień i ornamentów.</li>
  <li><strong>Ukryte przechowywanie</strong> – pojemne szafy zabudowane do sufitu,
      schowki i wielofunkcyjne meble z ukrytymi szufladami.</li>
  <li><strong>Naturalne materiały</strong> – drewno, kamień, len i bawełna zamiast
      syntetycznych tworzyw i plastiku.</li>
  <li><strong>Dobre oświetlenie</strong> – naturalne światło to priorytet; duże okna
      bez ciężkich firan to znak rozpoznawczy stylu.</li>
</ul>

<h2>Jak zacząć transformację?</h2>
<p>Pierwszym krokiem jest <em>decluttering</em> – pozbycie się wszystkich przedmiotów,
których nie używasz i które nie sprawiają Ci radości. Metoda KonMari Marie Kondo jest tu
świetnym punktem wyjścia. Następnie przejrzyj meble – zachowaj tylko te, które są
absolutnie niezbędne i pasują do neutralnej kolorystyki.</p>

<p>Pamiętaj, że minimalizm nie oznacza całkowitej rezygnacji z dekoracji. Kilka
starannie wybranych przedmiotów – ceramiczny wazon, grafika w prostej ramce,
suchy bukiet z traw pampasowych – nada przestrzeni charakter bez zbędnego zagracenia.</p>

<h2>Minimalizm w małym mieszkaniu</h2>
<p>Minimalistyczny styl jest szczególnie korzystny w małych przestrzeniach. Jasne kolory
optycznie powiększają pokój, a ograniczona liczba mebli zapewnia swobodę ruchu.
Wybieraj meble na nóżkach – podłoga widoczna pod nimi sprawia wrażenie większej
przestrzeni. Lustra strategicznie umieszczone na ścianie potrafią podwoić optycznie
wielkość pomieszczenia.</p>

<h2>Budżetowe podejście do minimalizmu</h2>
<p>Wbrew pozorom, minimalistyczne wnętrze nie musi być drogie. Wystarczy kilka
przemyślanych zakupów: biały lub szary dywan, drewniana półka, kilka roślin
w prostych doniczkach i czyste, białe ściany. Sklepy takie jak IKEA, Jysk czy
polskie marki oferują minimalistyczne meble w bardzo przystępnych cenach.</p>

<h2>Podsumowanie</h2>
<p>Minimalizm we wnętrzach to przede wszystkim świadome podejście do przestrzeni,
w której żyjemy. To rezygnacja z nadmiaru na rzecz jakości, funkcjonalności i spokoju.
Spróbuj zacząć od jednego pomieszczenia – najczęściej wystarczy weekend i kilka
worków na zbędne rzeczy, żeby poczuć prawdziwą różnicę.</p>
A1_EOF
echo "$SPONSORED" >> "$A1"
A1_ID=$($WP post create "$A1" \
    --post_type=post \
    --post_title="Minimalizm we Wnętrzach – Jak Urządzić Dom w Stylu Less is More" \
    --post_name="minimalizm-wnetrzach" \
    --post_status=publish \
    --post_date="2024-11-08 10:00:00" \
    --post_category="$DESIGN_CAT_ID" \
    --porcelain)
$WP post term set "$A1_ID" category "$DESIGN_CAT_ID" 2>/dev/null || true
success "Article 1: Minimalizm (ID: $A1_ID)"

# ── Article 2: Kolory roku 2024 ───────────────────────────────
A2=$(make_tmpfile)
cat > "$A2" << 'A2_EOF'
<p>Każdego roku Instytut Pantone ogłasza Kolor Roku, który wyznacza trendy w modzie,
designie wnętrz i grafice. W 2024 roku tym wyjątkowym odcieniem jest <strong>Peach Fuzz</strong>
(Pantone 13-1023) – delikatny, ciepły odcień brzoskwini, który wprowadza do przestrzeni
poczucie ciepła, komfortu i subtelnego optymizmu.</p>

<h2>Czym jest Peach Fuzz?</h2>
<p>Peach Fuzz to miękki, aksamitny odcień łączący różowe i pomarańczowe tony. Jest ciepły,
ale nie krzykliwy – co czyni go doskonałym wyborem zarówno do nowoczesnych, jak i klasycznych
wnętrz. Nazwa nawiązuje do miękkości i delikatności brzoskwiniowego meszku. Kolor kojarzy się
z przytulnością, troską i domowym ciepłem.</p>

<h2>Peach Fuzz w salonie</h2>
<p>Nie musisz malować całego salonu na brzoskwiniowo. Wystarczą przemyślane akcenty –
poduszki dekoracyjne, miękki koc, wazon ceramiczny lub obraz w tej tonacji.
Kolor doskonale komponuje się z naturalnym drewnem, bielą i odcieniami ciepłej szarości.</p>

<p>W większych przestrzeniach sprawdzi się sofa lub fotel tapicerowany w tym odcieniu.
Aksamit w kolorze Peach Fuzz wprowadza do wnętrza elegancję i przytulność jednocześnie.
Możesz też pokusić się o jedną ścianę akcentową – efekt będzie subtelny, ale wyraźny.</p>

<h2>Sypialnia w odcieniu brzoskwini</h2>
<p>Sypialnia to idealne miejsce do eksperymentowania z Peach Fuzz. Ciepły odcień sprzyja
relaksowi i spokojnemu zasypianiu. Pościel, zasłony lub tapicerowany zagłówek
w tym kolorze stworzą przytulną, romantyczną atmosferę. Połącz z beżem i kremem,
by uzyskać spójną, spokojną paletę. Złote detale – ramki, uchwyty szafki nocnej,
lampa stojąca – dodadzą elegancji bez przepychu.</p>

<h2>Inne trendy kolorystyczne 2024</h2>
<p>Oprócz Peach Fuzz w 2024 roku dominują ziemiste tony: terakota, głęboka zieleń
butelkowa i ciepły brąz. Te kolory nawiązują do natury i dobrze współgrają zarówno
z minimalistycznym, jak i boho designem.</p>

<p>Niebieskości w odcieniu szarego nieba – tzw. <em>slate blue</em> – to kolejny mocny
trend. Doskonale sprawdza się w łazienkach i sypialniach, tworząc spokojną,
niemal medytacyjną atmosferę.</p>

<h2>Jak wprowadzić trendy bez generalnego remontu?</h2>
<p>Wprowadzenie trendów kolorystycznych do wnętrza nie wymaga generalnego remontu.
Wystarczą przemyślane akcesoria: nowe poduszki, zasłony, dywan lub ceramika w modnym
odcieniu. Taki lifting można przeprowadzić dosłownie w jeden weekend, zmieniając
charakter pomieszczenia bez większych kosztów.</p>

<h2>Podsumowanie</h2>
<p>Peach Fuzz i towarzyszące mu trendy 2024 roku zapraszają do tworzenia wnętrz
ciepłych, przytulnych i bliskich naturze. Odważ się na odrobinę koloru – już kilka
zusów w odpowiednim odcieniu potrafi całkowicie odmienić charakter pomieszczenia.</p>
A2_EOF
echo "$SPONSORED" >> "$A2"
A2_ID=$($WP post create "$A2" \
    --post_type=post \
    --post_title="Kolory Roku 2024 – Jak Wprowadzić Trendy do Swojego Wnętrza" \
    --post_name="kolory-roku-2024-wnetrza" \
    --post_status=publish \
    --post_date="2024-11-01 10:00:00" \
    --post_category="$DESIGN_CAT_ID" \
    --porcelain)
$WP post term set "$A2_ID" category "$DESIGN_CAT_ID" 2>/dev/null || true
success "Article 2: Kolory roku 2024 (ID: $A2_ID)"

# ── Article 3: Rośliny doniczkowe ─────────────────────────────
A3=$(make_tmpfile)
cat > "$A3" << 'A3_EOF'
<p>Rośliny doniczkowe przeżywają prawdziwy renesans w aranżacji wnętrz. Nie tylko ożywiają
przestrzeń i poprawiają jakość powietrza, ale też stanowią naturalny element dekoracyjny
pasujący do każdego stylu – od minimalizmu po boho. Oto 10 gatunków, z którymi poradzi
sobie nawet kompletny początkujący.</p>

<h2>Dlaczego warto mieć rośliny w domu?</h2>
<p>Badania naukowe potwierdzają, że obecność roślin w pomieszczeniach obniża poziom stresu,
poprawia koncentrację i samopoczucie. Rośliny pochłaniają dwutlenek węgla, produkują tlen,
a niektóre gatunki aktywnie oczyszczają powietrze z toksycznych związków chemicznych
takich jak formaldehyd czy benzen.</p>

<p>Z estetycznego punktu widzenia rośliny dodają do wnętrza naturalność, teksturę i kolor.
Są też stosunkowo niedrogim sposobem na odświeżenie wystroju bez generalnego remontu.</p>

<h2>TOP 10 roślin doniczkowych dla początkujących</h2>

<p><strong>1. Sansewieria (Sansevieria / Dracaena trifasciata)</strong><br>
Niezniszczalna, toleruje niedobór światła i zapomniane podlewanie. Idealna do sypialni –
nocą produkuje tlen. Dostępna w dziesiątkach odmian.</p>

<p><strong>2. Pothos (Epipremnum aureum)</strong><br>
Pnąca roślina o sercowatych liściach. Rośnie praktycznie wszędzie, wymaga minimalnej
opieki. Świetna do zawieszenia lub oplatania półek.</p>

<p><strong>3. Zamiokulkas (Zamioculcas zamiifolia)</strong><br>
Błyszczące, ciemnozielone liście i niezwykła odporność na suszę. Jeden z najmodniejszych
wyborów do nowoczesnych wnętrz.</p>

<p><strong>4. Fikus benjamina (Ficus benjamina)</strong><br>
Klasyczny wybór do salonu. Lubi stałe miejsce i umiarkowane, regularne podlewanie.
Może osiągać imponujące rozmiary.</p>

<p><strong>5. Aloes (Aloe vera)</strong><br>
Nie tylko dekoracyjny, ale też użytkowy – żel aloesowy ma właściwości kojące
i lecznicze. Wymaga minimum opieki.</p>

<p><strong>6. Skrzydłokwiat (Spathiphyllum)</strong><br>
Kwitnie białymi, eleganckim kwiatami i skutecznie oczyszcza powietrze z toksyn.
Jeden z najlepiej przebadanych oczyszczaczy powietrza.</p>

<p><strong>7. Dracena (Dracaena)</strong><br>
Elegancka, tropikalna roślina dostępna w wielu odmianach. Toleruje słabe oświetlenie
i nieregularne podlewanie.</p>

<p><strong>8. Kaktus</strong><br>
Minimalistyczny wybór dla zapominalskich. Podlewaj raz na kilka tygodni, zapewnij
dużo słońca i gotowe. Tysiące odmian – od miniaturowych po metrowe kolumny.</p>

<p><strong>9. Monstera deliciosa</strong><br>
Modna roślina z charakterystycznymi otworami w liściach. Szybko rośnie i staje się
efektownym elementem dekoracyjnym każdego salonu.</p>

<p><strong>10. Chlorofitum (Chlorophytum comosum)</strong><br>
Produkuje rośliny potomne wiszące na długich pędach, idealne do dalszego rozmnażania.
Doskonały do zawieszenia w oknie.</p>

<h2>Podstawowe zasady pielęgnacji</h2>
<p>Najczęstszy błąd to <strong>przelanie</strong> – większość roślin doniczkowych ginie
z powodu zbyt częstego podlewania, a nie suszy. Sprawdzaj wilgotność podłoża przed
każdym podlaniem, wkładając palec ok. 2 cm w ziemię.</p>

<p>Doświetlenie to drugi kluczowy czynnik. Większość roślin preferuje jasne stanowisko
bez bezpośredniego, palącego słońca. Obserwuj liście – żółknące zwykle oznaczają
za dużo wody lub za mało światła.</p>

<h2>Podsumowanie</h2>
<p>Rośliny doniczkowe to jeden z najprostszych i najtańszych sposobów na ożywienie
wnętrza. Zacznij od jednego, odpornego gatunku, naucz się jego potrzeb i stopniowo
rozwijaj swój zielony zakątek w domu.</p>
A3_EOF
echo "$SPONSORED" >> "$A3"
A3_ID=$($WP post create "$A3" \
    --post_type=post \
    --post_title="Rośliny Doniczkowe w Salonie – TOP 10 Gatunków dla Początkujących" \
    --post_name="rosliny-doniczkowe-salon" \
    --post_status=publish \
    --post_date="2024-10-22 10:00:00" \
    --post_category="$DESIGN_CAT_ID" \
    --porcelain)
$WP post term set "$A3_ID" category "$DESIGN_CAT_ID" 2>/dev/null || true
success "Article 3: Rośliny doniczkowe (ID: $A3_ID)"

# ── Article 4: Home Office ─────────────────────────────────────
A4=$(make_tmpfile)
cat > "$A4" << 'A4_EOF'
<p>Praca zdalna na stałe zmieniła nasze podejście do organizacji przestrzeni domowej.
Dobre home office to już nie luksus, lecz konieczność – odpowiednio zaaranżowane
miejsce pracy przekłada się bezpośrednio na produktywność, komfort i zdrowie kręgosłupa.</p>

<h2>Wybór miejsca do pracy</h2>
<p>Idealnie, jeśli home office mieści się w osobnym pokoju z zamykanymi drzwiami.
Jednak nie wszyscy mają taką możliwość. W małym mieszkaniu wyznacz kąt do pracy –
nawet metr kwadratowy w sypialni lub salonie może stać się funkcjonalnym miejscem
pracy, jeśli zostanie odpowiednio urządzony.</p>

<p>Unikaj pracy z łóżka lub kanapy – takie nawyki szkodzą zarówno ergonomii,
jak i jakości wypoczynku. Mózg przestaje kojarzyć sypialnię z odpoczynkiem,
co może prowadzić do problemów ze snem.</p>

<h2>Biurko i krzesło – fundament dobrego home office</h2>
<p>Biurko powinno mieć odpowiednią wysokość – blat na poziomie łokci przy wyprostowanych
plecach. Szerokość co najmniej 120 cm daje komfort pracy przy dwóch monitorach.
Biurko z regulowaną wysokością, umożliwiające pracę na stojąco, to inwestycja,
która opłaca się zdrowotnie.</p>

<p>Krzesło ergonomiczne to absolutna konieczność dla osób pracujących kilka godzin
dziennie. Powinno zapewniać wsparcie dla odcinka lędźwiowego kręgosłupa, regulację
wysokości siedziska i kąta oparcia. Nie oszczędzaj na krześle – efekty złej
postawy odczujesz boleśnie po kilku latach.</p>

<h2>Oświetlenie miejsca pracy</h2>
<p>Naturalne światło to priorytet – ustaw biurko przy oknie, ale tak, by monitor
nie był oświetlony bezpośrednio od tyłu ani od przodu (odblask na ekranie).
Ustawiaj okno po lewej stronie monitora, jeśli jesteś praworęczny.</p>

<p>Dodatkowa lampa biurkowa z regulowaną temperaturą barwową (ciepłe 2700K
do relaksu, chłodne 4000K do skupionej pracy) zapobiegnie zmęczeniu oczu
podczas długich sesji.</p>

<h2>Organizacja i porządek</h2>
<p>Bałagan na biurku to cichy zabójca produktywności. Zadbaj o organizery na biurko,
zarządzanie kablami (opaski, kanały kablowe) i system przechowywania dokumentów.
Zasada jest prosta: wszystko, czego nie używasz codziennie, chowasz z widoku.</p>

<p>Tablica korkowa lub magnetyczna nad biurkiem pomaga w organizacji zadań i inspiracji
bez zaśmiecania przestrzeni wirtualnymi karteczkami. Roślina na biurku – mały kaktus
lub sukulenty – pozytywnie wpływa na samopoczucie i kreatywność.</p>

<h2>Akustyka i prywatność</h2>
<p>Jeśli pracujesz z rodziną w domu lub mieszkasz w bloku, rozważ panele akustyczne
lub dywany pochłaniające dźwięk. Słuchawki z aktywną redukcją hałasu (ANC)
to szybkie rozwiązanie na czas wideokonferencji.</p>

<h2>Podsumowanie</h2>
<p>Dobre home office to inwestycja w zdrowie, produktywność i komfort pracy.
Zaczyna się od właściwego miejsca, przyzwoitego krzesła i odpowiedniego oświetlenia.
Resztę można dobudowywać stopniowo, dopasowując przestrzeń do swoich potrzeb.</p>
A4_EOF
echo "$SPONSORED" >> "$A4"
A4_ID=$($WP post create "$A4" \
    --post_type=post \
    --post_title="Home Office – Jak Urządzić Wygodne Biuro w Domu?" \
    --post_name="home-office-biuro-w-domu" \
    --post_status=publish \
    --post_date="2024-10-10 10:00:00" \
    --post_category="$DESIGN_CAT_ID" \
    --porcelain)
$WP post term set "$A4_ID" category "$DESIGN_CAT_ID" 2>/dev/null || true
success "Article 4: Home Office (ID: $A4_ID)"

# ── Article 5: Styl skandynawski ──────────────────────────────
A5=$(make_tmpfile)
cat > "$A5" << 'A5_EOF'
<p>Styl skandynawski to jeden z najpopularniejszych trendów aranżacji wnętrz na świecie.
Jego popularność nie słabnie od dekad – bo łączy w sobie estetykę, funkcjonalność
i przytulność na poziomie, który trudno osiągnąć w innym stylu. Najlepsza wiadomość?
Można go wprowadzić nawet przy ograniczonym budżecie.</p>

<h2>Czym charakteryzuje się styl skandynawski?</h2>
<p>Skandynawski design narodził się z konieczności – długie, ciemne zimy wymusiły
tworzenie wnętrz jasnych, funkcjonalnych i maksymalnie przytulnych. Stąd dominacja
bieli i jasnych odcieni, naturalne materiały i minimalizm połączony z ciepłem
domowego ogniska.</p>

<p>Kluczowe cechy stylu skandynawskiego:</p>
<ul>
  <li>Jasna paleta kolorów: biel, szarość, ciepły beż i naturalne odcienie drewna</li>
  <li>Naturalne materiały: drewno, wełna, len, skóra, kamień</li>
  <li>Proste formy mebli bez zbędnych ozdób i ornamentów</li>
  <li>Dużo tekstyliów tworzących warstwowość i przytulność</li>
  <li>Rośliny doniczkowe i naturalne dekoracje (gałęzie, kamienie, drewno)</li>
  <li>Dobre, wielopoziomowe oświetlenie jako antidotum na ciemność</li>
</ul>

<h2>Hygge – duński sekret przytulności</h2>
<p><em>Hygge</em> (czyt. „hüge") to duńska filozofia czerpania przyjemności z prostych,
codziennych chwil. W kontekście wnętrz oznacza tworzenie przestrzeni sprzyjających
relaksowi i bliskości: miękkie koce, świeczki, ciepłe oświetlenie, wygodne miejsca
do siedzenia z kubkiem gorącej herbaty.</p>

<p>Stwórz swój kąt hygge – fotel przy oknie obity miękką tkaniną, koc z grubego splotu,
stolik na herbatę i dobra lampka. To wystarczy, żeby poczuć duńską przytulność
nawet w małym polskim mieszkaniu.</p>

<h2>Meble w stylu skandynawskim</h2>
<p>Szukaj mebli o prostych, czystych liniach i naturalnym wykończeniu. Drewno –
szczególnie jasne: brzoza, dąb, jesion, sosna – to podstawa skandynawskiego salonu.
IKEA oferuje wiele produktów w tym stylu w przystępnych cenach, ale warto też
rozejrzeć się za polskimi producentami drewnianych mebli.</p>

<p>Charakterystyczne cienkie, drewniane nóżki mebli to wizytówka stylu nordyckiego.
Nadają meblom lekkości i elegancji, a podłoga widoczna pod sofą optycznie powiększa
przestrzeń.</p>

<h2>Tekstylia i oświetlenie</h2>
<p>W skandynawskim wnętrzu tekstylia odgrywają kluczową rolę. Wełniany dywan,
lniane zasłony przepuszczające światło, bawełniane poduszki i koce z grubego splotu
tworzą warstwowość i komfort. Wzory geometryczne lub nordyckie motywy (herringbone,
jodełka) dodają charakteru bez zbędnego zamieszania.</p>

<p>Oświetlenie w stylu skandynawskim jest wielopoziomowe: lampa sufitowa jako ogólne
źródło, lampa stojąca do czytania, świeczniki i girlandy tworzące atmosferę wieczorem.
Unikaj jednego centralnego źródła – wiele małych punktów świetlnych kreuje
nieporównanie cieplejszą atmosferę.</p>

<h2>Podsumowanie</h2>
<p>Styl skandynawski to nie tylko estetyka – to sposób na życie, w którym dom jest
prawdziwym azylem. Jasne kolory, naturalne materiały i dbałość o przytulność tworzą
przestrzeń, w której naprawdę odpoczywasz. Zacznij od jednego pokoju i poczuj różnicę.</p>
A5_EOF
echo "$SPONSORED" >> "$A5"
A5_ID=$($WP post create "$A5" \
    --post_type=post \
    --post_title="Styl Skandynawski w Polskim Domu – Praktyczny Poradnik" \
    --post_name="styl-skandynawski-wnetrza" \
    --post_status=publish \
    --post_date="2024-09-28 10:00:00" \
    --post_category="$DESIGN_CAT_ID" \
    --porcelain)
$WP post term set "$A5_ID" category "$DESIGN_CAT_ID" 2>/dev/null || true
success "Article 5: Styl skandynawski (ID: $A5_ID)"

# ── Article 6: Odświeżenie mieszkania ─────────────────────────
A6=$(make_tmpfile)
cat > "$A6" << 'A6_EOF'
<p>Odświeżenie mieszkania nie musi oznaczać generalnego remontu ani dużych wydatków.
Często wystarczy kilka przemyślanych zmian, by przestrzeń nabrała nowego charakteru.
Oto 10 sprawdzonych sposobów na metamorfozę wnętrza bez opróżniania portfela.</p>

<h2>1. Pomaluj jedną ścianę na akcent</h2>
<p>Ściana akcentowa to najprostszy sposób na zmianę charakteru pomieszczenia.
Wybierz jedną ścianę i pomaluj ją na odważny kolor, użyj farby tablicowej
lub magnetycznej. Koszt: kilkadziesiąt złotych za farbę i wałek, efekt: ogromny.</p>

<h2>2. Zmień oświetlenie</h2>
<p>Wymiana żarówek na ciepłe (2700K) i dodanie lampek dekoracyjnych całkowicie zmienia
atmosferę wnętrza. Girlanda świetlna nad łóżkiem lub w salonie kosztuje kilkanaście
złotych i robi zaskakująco dużą różnicę.</p>

<h2>3. Przestaw meble</h2>
<p>Zero złotych, a efekt może być rewelacyjny. Zmiana układu mebli odświeża perspektywę
i często optymalizuje przepływ przestrzeni. Eksperymentuj – przesuń sofę, obróć dywan,
zmień stronę łóżka. Możesz być zaskoczony rezultatem.</p>

<h2>4. Nowe tekstylia i poduszki</h2>
<p>Poduszki, narzuta na sofę, zasłony – to najtańszy i najszybszy sposób na odświeżenie
wystroju. W sezonowych wyprzedażach komplety poduszek kupisz za 20–30 zł. Zmień
kolor przewodni pomieszczenia w jeden weekend.</p>

<h2>5. Galeria zdjęć i grafik</h2>
<p>Stwórz galerię na ścianie. Wydrukuj ulubione fotografie lub kup plakaty online,
kup proste ramki w sieciówkach i stwórz osobiste dzieło sztuki. Galeria ścian
to jeden z najpopularniejszych trendów we współczesnym designie wnętrz.</p>

<h2>6. Rośliny doniczkowe</h2>
<p>Kilka roślin doniczkowych – szczególnie tych rozmnażanych od znajomych (gratis!) –
natychmiast ożywia wnętrze i dodaje naturalnego koloru. Monstera, pothos i sansewieria
to popularne wybory, które przeżyją nawet niezbyt troskliwą opiekę.</p>

<h2>7. Gruntowne sprzątanie i decluttering</h2>
<p>Czasem wystarczy gruntowne sprzątanie i wyrzucenie zbędnych przedmiotów, by mieszkanie
wyglądało jak nowe. Minimalizm jest bezpłatny. Przeznacz weekend na każdy pokój –
efekt potrafi zaszokować.</p>

<h2>8. Nowe uchwyty do mebli</h2>
<p>Wymiana uchwytów w szafkach kuchennych lub komodzie na nowe, designerskie to tani
sposób na lifting mebli. Uchwyty miedziowane, mosiężne lub ceramiczne kupisz już
od kilku złotych za sztukę, a efekt jest natychmiastowy.</p>

<h2>9. Dywan jako element strefowania</h2>
<p>Dywan wyznacza strefy w otwartej przestrzeni, dodaje przytulności i pochłania dźwięk.
W sklepach internetowych znajdziesz przyzwoite dywany już od 100–150 zł.
Właściwy wybór rozmiaru jest kluczowy – za mały dywan to najczęstszy błąd.</p>

<h2>10. DIY dekoracje</h2>
<p>Zrób dekoracje samodzielnie: makrama z sznurka, wazon z butelki po winie,
świecznik z plastrów drewna. YouTube pełen jest tutoriali krok po kroku.
Koszt: minimalny. Satysfakcja: ogromna. I zawsze będziesz mieć unikalne elementy.</p>

<h2>Podsumowanie</h2>
<p>Metamorfoza mieszkania nie wymaga fortuny – wymaga pomysłowości i odwagi
do eksperymentowania. Zacznij od najprostszych zmian i obserwuj, jak Twoja
przestrzeń nabiera nowego życia.</p>
A6_EOF
echo "$SPONSORED" >> "$A6"
A6_ID=$($WP post create "$A6" \
    --post_type=post \
    --post_title="Jak Odświeżyć Mieszkanie Małym Kosztem – 10 Pomysłów" \
    --post_name="odswiezenie-mieszkania-malo-kosztem" \
    --post_status=publish \
    --post_date="2024-09-15 10:00:00" \
    --post_category="$DESIGN_CAT_ID" \
    --porcelain)
$WP post term set "$A6_ID" category "$DESIGN_CAT_ID" 2>/dev/null || true
success "Article 6: Odświeżenie mieszkania (ID: $A6_ID)"

# ── Article 7: Kuchnia otwarta ────────────────────────────────
A7=$(make_tmpfile)
cat > "$A7" << 'A7_EOF'
<p>Kuchnia otwarta na salon to jeden z najpopularniejszych układów mieszkań w nowym
budownictwie. Daje poczucie przestrzeni i sprzyja rodzinnym spotkaniom, ale ma też
swoje wady. Zanim zdecydujesz się na wyburzenie ściany, poznaj wszystkie za i przeciw.</p>

<h2>Zalety kuchni otwartej na salon</h2>
<p>Największą zaletą jest poczucie przestrzeni – połączone pomieszczenia optycznie
powiększają mieszkanie, co jest szczególnie cenne w małych metrażach polskich mieszkań.
Naturalne światło swobodnie przepływa przez całą przestrzeń dzienną.</p>

<p>Kuchnia otwarta sprzyja kontaktowi społecznemu podczas gotowania. Możesz rozmawiać
z gośćmi siedzącymi w salonie, pilnować bawiących się dzieci lub oglądać telewizję
podczas przygotowywania posiłków. Dla rodzin z dziećmi to często decydujący argument.</p>

<h2>Wady kuchni otwartej</h2>
<p>Zapachy to największy problem. Aromat gotowanego jedzenia – szczególnie smażonej ryby
lub czosnku – rozprzestrzenia się na cały salon i długo pozostaje w tekstyliach.
Dobry, wydajny okap to absolutna konieczność; nie kupuj najtańszego modelu.</p>

<p>Hałas urządzeń kuchennych (zmywarka, okap, blender, ekspres) może przeszkadzać
osobom pracującym zdalnie lub odpoczywającym w salonie. Trudniej też ukryć
bałagan kuchenny przed nieoczekiwanymi gośćmi.</p>

<h2>Jak strefować przestrzeń otwartą?</h2>
<p>Choć kuchnia i salon są połączone, warto je optycznie rozdzielić. Sprawdzone metody:</p>
<ul>
  <li><strong>Wyspa kuchenna lub bar śniadaniowy</strong> – tworzy naturalną granicę
      i dodaje powierzchni roboczej</li>
  <li><strong>Różne materiały podłogowe</strong> – płytki w kuchni, drewno lub panele
      w salonie</li>
  <li><strong>Odmienne oświetlenie strefowe</strong> – lampy wiszące nad wyspą,
      inne oświetlenie w salonie</li>
  <li><strong>Dywan wyznaczający strefę wypoczynku</strong> – tańsze i elastyczne
      rozwiązanie</li>
</ul>

<h2>Spójny wystrój obu stref</h2>
<p>Kuchnia i salon muszą tworzyć jedną spójną całość kolorystyczną i stylistyczną.
Wybierz dwie lub trzy dominujące barwy i stosuj je konsekwentnie. Fronty szafek
kuchennych powinny korespondować z meblami w salonie – podobny styl, zbliżone
kolory lub materiały.</p>

<p>Naturalne materiały – drewno, kamień, metal – doskonale spinają obie przestrzenie
w harmonijną całość. Blat kamienny z marmurowym wzorem, który nawiązuje do kafli
w salonie, to przykład spójności, który robi wrażenie.</p>

<h2>Wentylacja jako priorytet</h2>
<p>Przed decyzją o otwartej kuchni sprawdź możliwości wentylacyjne. Okap musi być
podłączony do przewodu wentylacyjnego lub zewnętrznego – nie recyrkulacyjny.
Wydajność okapu powinna być dostosowana do rozmiaru kuchni i intensywności gotowania.
To nie jest miejsce na oszczędności.</p>

<h2>Podsumowanie</h2>
<p>Kuchnia otwarta na salon to rozwiązanie, które działa świetnie w odpowiednich warunkach –
przy dobrej wentylacji, spójnym designie i akceptacji dla większego dźwięku i zapachów.
Podejmuj tę decyzję świadomie, a efekt będzie spełniał oczekiwania przez długie lata.</p>
A7_EOF
echo "$SPONSORED" >> "$A7"
A7_ID=$($WP post create "$A7" \
    --post_type=post \
    --post_title="Kuchnia Otwarta na Salon – Wady, Zalety i Praktyczne Wskazówki" \
    --post_name="kuchnia-otwarta-na-salon" \
    --post_status=publish \
    --post_date="2024-09-03 10:00:00" \
    --post_category="$DESIGN_CAT_ID" \
    --porcelain)
$WP post term set "$A7_ID" category "$DESIGN_CAT_ID" 2>/dev/null || true
success "Article 7: Kuchnia otwarta (ID: $A7_ID)"

# ═════════════════════════════════════════════════════════════
# SECTION 12 — Yoast SEO Configuration
# ═════════════════════════════════════════════════════════════
step "Configuring Yoast SEO"

# Enable XML sitemap
$WP option patch update wpseo enable_xml_sitemap true 2>/dev/null || \
    $WP eval 'update_option("wpseo", array_merge(
        (array) get_option("wpseo", array()),
        array("enable_xml_sitemap" => true)
    )); echo "wpseo updated\n";'

# Organization settings
$WP option patch update wpseo_social company_name "WP Design" 2>/dev/null || true
$WP option patch update wpseo_social company_or_person "company" 2>/dev/null || \
    $WP eval 'update_option("wpseo_social", array_merge(
        (array) get_option("wpseo_social", array()),
        array("company_name" => "WP Design", "company_or_person" => "company")
    )); echo "wpseo_social updated\n";'

# Title templates
$WP option patch update wpseo_titles title-post "%%title%% &#8211; WP Design" 2>/dev/null || true
$WP option patch update wpseo_titles title-page "%%title%% &#8211; WP Design" 2>/dev/null || true

success "Yoast SEO configured"

# ═════════════════════════════════════════════════════════════
# SECTION 13 — Verification Summary
# ═════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║   WP Design setup complete!              ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Site URL:${NC}       $($WP option get siteurl)"
echo -e "${CYAN}Site Title:${NC}     $($WP option get blogname)"
echo -e "${CYAN}Language:${NC}       $($WP option get WPLANG)"
echo -e "${CYAN}Timezone:${NC}       $($WP option get timezone_string)"
echo -e "${CYAN}Active Theme:${NC}   $($WP theme list --status=active --field=name 2>/dev/null)"
echo -e "${CYAN}Front page:${NC}     ID $HOMEPAGE_ID | Blog page: ID $BLOG_ID"
echo ""
echo -e "${CYAN}Active plugins:${NC}"
$WP plugin list --status=active --fields=name,version 2>/dev/null
echo ""
echo -e "${CYAN}Published articles:${NC}"
$WP post list --post_type=post --post_status=publish --fields=ID,post_title,post_date 2>/dev/null
echo ""
echo -e "${CYAN}Published pages:${NC}"
$WP post list --post_type=page --post_status=publish --fields=ID,post_title,post_name 2>/dev/null
echo ""
echo -e "${BOLD}${YELLOW}NEXT STEPS (manual):${NC}"
echo "  1. Visit WP Admin → Appearance → Customize to verify Astra colors"
echo "  2. Check the navigation menu appears correctly in the header"
echo "  3. Verify Yoast sitemap: https://wp-design.org/sitemap_index.xml"
echo "  4. Verify robots.txt: https://wp-design.org/robots.txt"
echo "  5. Enable WP Super Cache: WP Admin → Settings → WP Super Cache"
echo "  6. Add Featured Images to articles via WP Admin → Posts"
echo "  7. Set Cloudflare DNS to 'DNS Only' (grey cloud) for unique IP"
echo "  8. Verify SSL certificate is active (green lock in browser)"
echo ""
