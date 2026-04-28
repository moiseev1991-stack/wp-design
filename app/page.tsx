import Link from 'next/link'
import { getHomePosts } from '@/lib/posts'
import { siteConfig } from '@/lib/config'
import PostCard from '@/components/PostCard'
import type { Metadata } from 'next'

const homeTitle = 'WP Design – Twój przewodnik po kasynach online w Polsce'
const homeDescription = 'Niezależne recenzje, bonusy, sloty i poradniki o legalnych kasynach online dla polskich graczy. Sprawdź najnowsze artykuły WP Design.'

export const metadata: Metadata = {
  title: homeTitle,
  description: homeDescription,
  alternates: { canonical: siteConfig.url + '/' },
  openGraph: { title: homeTitle, description: homeDescription, url: siteConfig.url, type: 'website' },
}

export default function HomePage() {
  const homePosts = getHomePosts(10, 3)

  const jsonLd = {
    '@context': 'https://schema.org', '@type': 'WebSite',
    name: siteConfig.name, url: siteConfig.url, description: siteConfig.description, inLanguage: 'pl',
  }

  return (
    <>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />

      {/* ── HERO ─────────────────────────────────────────────── */}
      <section className="max-w-6xl mx-auto px-4 sm:px-6 py-12 sm:py-16">
        <div className="text-center max-w-3xl mx-auto mb-12">
          <span className="section-label">WP Design</span>
          <h1 className="font-heading text-4xl sm:text-5xl font-bold text-[var(--text)] leading-tight mb-4">
            Twój przewodnik po kasynach online w&nbsp;Polsce
          </h1>
          <p className="text-[var(--text-muted)] text-lg leading-relaxed">
            Niezależne recenzje, bonusy, sloty i poradniki dla polskich graczy. Stawiamy na rzetelność, bezpieczeństwo i odpowiedzialną grę.
          </p>
          <div className="mt-6 flex flex-wrap justify-center gap-2">
            {['🛡️ Tylko legalne kasyna', '🎁 Aktualne bonusy', '💳 Płatności BLIK', '📱 Wersje mobilne'].map(badge => (
              <span key={badge} className="text-xs bg-[var(--bg-section)] text-[var(--text-muted)] px-3 py-1.5 rounded-full border border-[var(--border)]">
                {badge}
              </span>
            ))}
          </div>
        </div>

        {/* Features */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-16">
          {[
            { icon: '🔍', title: 'Niezależne recenzje', text: 'Bez kompromisów i ukrytych umów.' },
            { icon: '🎁', title: 'Najlepsze bonusy', text: 'Aktualne oferty z czytelnym wagering.' },
            { icon: '🛡️', title: 'Bezpieczeństwo', text: 'Tylko licencjonowane kasyna online.' },
            { icon: '⚡', title: 'Aktualne info', text: 'Trendy i nowości na 2026 rok.' },
          ].map(f => (
            <div key={f.title} className="bg-[var(--bg-card)] border border-[var(--border)] rounded-2xl p-5 text-center" style={{ boxShadow: 'var(--shadow)' }}>
              <div className="text-3xl mb-2">{f.icon}</div>
              <div className="font-heading font-bold text-sm text-[var(--text)] mb-1">{f.title}</div>
              <p className="text-xs text-[var(--text-muted)] leading-relaxed">{f.text}</p>
            </div>
          ))}
        </div>
      </section>

      {/* ── LATEST ARTICLES ──────────────────────────────────── */}
      <section className="max-w-6xl mx-auto px-4 sm:px-6 pb-16">
        <div className="flex items-end justify-between mb-10">
          <div>
            <span className="section-label">Najnowsze</span>
            <h2 className="font-heading text-3xl sm:text-4xl font-bold text-[var(--text)] fancy-heading">
              Artykuły i recenzje
            </h2>
          </div>
          <Link href="/kategoria/" className="hidden sm:inline-flex items-center gap-1.5 text-sm text-[var(--accent)] font-semibold hover:gap-3 transition-all">
            Wszystkie artykuły <span>→</span>
          </Link>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {homePosts.map((post, idx) => (
            <PostCard
              key={post.slug}
              post={post}
              moneyCTA={idx < 3 && post.moneyArticle ? { url: siteConfig.moneyPageUrl } : undefined}
            />
          ))}
        </div>

        <div className="mt-10 flex justify-center sm:hidden">
          <Link href="/kategoria/" className="text-sm text-[var(--accent)] font-semibold border border-[var(--accent)] px-6 py-2.5 rounded-xl hover:bg-[var(--accent)] hover:text-white transition-colors">
            Wszystkie artykuły →
          </Link>
        </div>
      </section>

      {/* ── CATEGORIES STRIP ─────────────────────────────────── */}
      <div className="max-w-6xl mx-auto px-4 sm:px-6 pb-16">
        <div className="bg-[var(--bg-section)] rounded-3xl p-8 sm:p-12 relative overflow-hidden border border-[var(--border)]">
          <div className="absolute inset-0 opacity-[0.03]">
            <svg width="100%" height="100%" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <pattern id="diamonds" x="0" y="0" width="30" height="30" patternUnits="userSpaceOnUse">
                  <polygon points="15,0 30,15 15,30 0,15" fill="none" stroke="currentColor" strokeWidth="0.8"/>
                </pattern>
              </defs>
              <rect width="100%" height="100%" fill="url(#diamonds)" className="text-[var(--accent)]" />
            </svg>
          </div>
          <div className="relative text-center max-w-2xl mx-auto">
            <div className="text-5xl mb-4">🎰</div>
            <h3 className="font-heading text-2xl sm:text-3xl font-bold text-[var(--text)] mb-3">
              Wybierz swoją kategorię
            </h3>
            <p className="text-[var(--text-muted)] mb-6">
              Recenzje, bonusy, sloty, jackpoty, gry stołowe, płatności, mobilne kasyna, poradniki — wszystko poukładane tematycznie.
            </p>
            <Link href="/kategoria/" className="inline-flex items-center gap-2 bg-[var(--accent)] hover:bg-[var(--accent-dark)] text-white font-bold px-7 py-3.5 rounded-xl transition-colors">
              Przeglądaj kategorie →
            </Link>
          </div>
        </div>
      </div>
    </>
  )
}
