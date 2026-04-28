import Link from 'next/link'
import type { Metadata } from 'next'
import { categories } from '@/lib/categories'
import { getCategoryCounts } from '@/lib/posts'
import { siteConfig } from '@/lib/config'
import Breadcrumbs from '@/components/Breadcrumbs'

export const metadata: Metadata = {
  title: 'Kategorie',
  description: 'Wszystkie kategorie artykułów na WP Design – recenzje kasyn, bonusy, sloty, jackpoty, gry stołowe, płatności, mobilne i poradniki.',
  alternates: { canonical: `${siteConfig.url}/kategoria/` },
}

export default function CategoriesIndexPage() {
  const counts = getCategoryCounts()

  return (
    <div className="archive max-w-6xl mx-auto px-4 sm:px-6 py-10">
      <Breadcrumbs items={[{ label: 'Kategorie' }]} />

      <header className="page-header mb-10">
        <h1 className="page-title font-heading text-4xl font-bold text-[var(--text)] mb-3">Kategorie</h1>
        <p className="text-[var(--text-muted)] max-w-2xl">
          Przeglądaj artykuły WP Design w wygodnych kategoriach – od pełnych recenzji kasyn online po praktyczne poradniki dla graczy.
        </p>
      </header>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        {categories.map(cat => {
          const count = counts[cat.slug] ?? 0
          return (
            <Link
              key={cat.slug}
              href={`/kategoria/${cat.slug}/`}
              className="bg-[var(--bg-card)] rounded-2xl border border-[var(--border)] p-6 hover:shadow-lg hover:-translate-y-0.5 transition-all flex flex-col gap-3 group"
              style={{ boxShadow: 'var(--shadow)' }}
            >
              <div className="flex items-center justify-between">
                <span className="text-4xl">{cat.icon}</span>
                <span className="text-xs bg-[var(--bg-section)] text-[var(--text-muted)] px-3 py-1 rounded-full border border-[var(--border)]">
                  {count} {count === 1 ? 'artykuł' : 'artykułów'}
                </span>
              </div>
              <h2 className="font-heading text-xl font-bold text-[var(--text)] group-hover:text-[var(--accent)] transition-colors">
                {cat.label}
              </h2>
              <p className="text-sm text-[var(--text-muted)] leading-relaxed flex-1">
                {cat.description}
              </p>
              <span className="text-sm text-[var(--accent)] font-semibold inline-flex items-center gap-1.5 group-hover:gap-3 transition-all">
                Zobacz artykuły <span>→</span>
              </span>
            </Link>
          )
        })}
      </div>
    </div>
  )
}
