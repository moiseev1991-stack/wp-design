import { siteConfig } from '@/lib/config'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Przekierowanie',
  description: 'Strona przeniesiona do indeksu kategorii.',
  alternates: { canonical: `${siteConfig.url}/kategoria/` },
  robots: { index: false, follow: true },
}

export default function BlogIndexRedirect() {
  const target = '/kategoria/'
  const script = `window.location.replace(${JSON.stringify(target)});`
  return (
    <div className="max-w-2xl mx-auto px-6 py-20 text-center">
      <noscript>
        <meta httpEquiv="refresh" content={`0; url=${target}`} />
      </noscript>
      <script dangerouslySetInnerHTML={{ __html: script }} />
      <h1 className="font-heading text-2xl font-bold text-[var(--text)] mb-4">Strona została przeniesiona</h1>
      <p className="text-[var(--text-muted)] mb-6">
        Indeks artykułów znajdziesz teraz w sekcji{' '}
        <a className="text-[var(--accent)] underline" href={target}>Kategorie</a>.
      </p>
    </div>
  )
}
