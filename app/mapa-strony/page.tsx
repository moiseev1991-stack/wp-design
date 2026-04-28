import Link from 'next/link'
import type { Metadata } from 'next'
import { getAllPosts } from '@/lib/posts'
import { categories, categoriesBySlug } from '@/lib/categories'
import { siteConfig } from '@/lib/config'
import Breadcrumbs from '@/components/Breadcrumbs'

export const metadata: Metadata = {
  title: 'Mapa strony',
  description: 'Pełna mapa strony WP Design – wszystkie kategorie, artykuły i strony techniczne w jednym miejscu.',
  alternates: { canonical: `${siteConfig.url}/mapa-strony/` },
}

function formatDate(d: string) {
  return new Date(d).toLocaleDateString('pl-PL', { day: 'numeric', month: 'short', year: 'numeric' })
}

export default function MapaStronyPage() {
  const posts = getAllPosts()

  const postsByCategory = categories.map(cat => ({
    cat,
    items: posts.filter(p => p.category === cat.slug),
  }))

  return (
    <div className="max-w-6xl mx-auto px-4 sm:px-6 py-10">
      <Breadcrumbs items={[{ label: 'Mapa strony' }]} />

      <header className="page-header mb-10">
        <h1 className="page-title font-heading text-4xl font-bold text-[var(--text)] mb-3">Mapa strony</h1>
        <p className="text-[var(--text-muted)] max-w-2xl">
          Pełna lista zawartości WP Design – kategorie, artykuły i strony techniczne. Łącznie {posts.length} artykułów.
        </p>
      </header>

      <section className="mb-12">
        <h2 className="font-heading text-xl font-bold text-[var(--text)] mb-4">01 · Strony główne</h2>
        <ul className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-sm">
          {[
            { label: 'Strona główna', href: '/' },
            { label: 'Kategorie', href: '/kategoria/' },
            { label: 'O nas', href: '/o-nas/' },
            { label: 'Kontakt', href: '/kontakt/' },
            { label: 'Polityka prywatności', href: '/polityka-prywatnosci/' },
            { label: 'Mapa strony', href: '/mapa-strony/' },
          ].map(p => (
            <li key={p.href}>
              <Link href={p.href} className="text-[var(--accent)] hover:underline">{p.label}</Link>
            </li>
          ))}
        </ul>
      </section>

      <section className="mb-12">
        <h2 className="font-heading text-xl font-bold text-[var(--text)] mb-4">02 · Kategorie</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
          {categories.map(cat => (
            <Link
              key={cat.slug}
              href={`/kategoria/${cat.slug}/`}
              className="bg-[var(--bg-card)] border border-[var(--border)] rounded-xl p-4 hover:border-[var(--accent)] transition-colors text-sm flex items-center gap-3"
              style={{ boxShadow: 'var(--shadow)' }}
            >
              <span className="text-2xl">{cat.icon}</span>
              <span className="font-medium text-[var(--text)]">{cat.label}</span>
            </Link>
          ))}
        </div>
      </section>

      <section className="mb-12">
        <h2 className="font-heading text-xl font-bold text-[var(--text)] mb-4">03 · Artykuły</h2>
        <div className="space-y-8">
          {postsByCategory.map(({ cat, items }) => items.length > 0 && (
            <div key={cat.slug}>
              <h3 className="font-heading text-base font-semibold text-[var(--text)] mb-3 flex items-center gap-2">
                <span>{cat.icon}</span>
                <Link href={`/kategoria/${cat.slug}/`} className="hover:text-[var(--accent)]">{cat.label}</Link>
                <span className="text-xs text-[var(--text-muted)] font-normal">({items.length})</span>
              </h3>
              <ul className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-sm pl-7">
                {items.map(p => (
                  <li key={p.slug} className="flex items-start gap-2">
                    <Link href={`/${p.slug}/`} className="text-[var(--accent)] hover:underline line-clamp-1">{p.title}</Link>
                    <span className="text-xs text-[var(--text-muted)] shrink-0">{formatDate(p.date)}</span>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </section>

      <section>
        <h2 className="font-heading text-xl font-bold text-[var(--text)] mb-4">04 · Pliki techniczne</h2>
        <ul className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-sm">
          <li><a href="/sitemap.xml" className="text-[var(--accent)] hover:underline">sitemap.xml</a></li>
          <li><a href="/robots.txt" className="text-[var(--accent)] hover:underline">robots.txt</a></li>
          <li><a href="/feed/" className="text-[var(--accent)] hover:underline">RSS feed</a></li>
        </ul>
      </section>
    </div>
  )
}
