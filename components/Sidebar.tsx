import Link from 'next/link'
import type { Post } from '@/lib/posts'
import { categories } from '@/lib/categories'
import { getCategoryCounts } from '@/lib/posts'

interface Props {
  recentPosts: Post[]
}

function formatDate(d: string) {
  return new Date(d).toLocaleDateString('pl-PL', { day: 'numeric', month: 'short' })
}

export default function Sidebar({ recentPosts }: Props) {
  const counts = getCategoryCounts()

  return (
    <aside id="secondary" className="widget-area nv-sidebar-wrap flex flex-col gap-6">

      {/* Recent posts widget */}
      <section className="widget widget_recent_entries bg-[var(--bg-card)] rounded-2xl border border-[var(--border)] overflow-hidden" style={{ boxShadow: 'var(--shadow)' }}>
        <div className="widget-title bg-[var(--accent-dark)] px-5 py-3.5">
          <h3 className="font-heading text-sm font-bold text-white">📰 Ostatnie artykuły</h3>
        </div>
        <ul className="divide-y divide-[var(--border)]">
          {recentPosts.map(post => (
            <li key={post.slug} className="flex gap-3 items-start p-4 hover:bg-[var(--bg-section)] transition-colors">
              <span className="text-2xl mt-0.5 shrink-0">{post.emoji}</span>
              <div className="min-w-0">
                <Link href={`/${post.slug}/`} className="text-sm font-medium text-[var(--text)] hover:text-[var(--accent)] transition-colors leading-snug line-clamp-2 block">
                  {post.title}
                </Link>
                <time className="text-xs text-[var(--text-muted)] mt-0.5 block">{formatDate(post.date)}</time>
              </div>
            </li>
          ))}
        </ul>
      </section>

      {/* Categories widget */}
      <section className="widget widget_categories bg-[var(--bg-card)] rounded-2xl border border-[var(--border)] p-5" style={{ boxShadow: 'var(--shadow)' }}>
        <div className="widget-title mb-4 pb-2 border-b border-[var(--border)]">
          <h3 className="font-heading text-sm font-bold text-[var(--text)]">🎯 Tematy</h3>
        </div>
        <ul className="cat-list flex flex-col gap-1">
          {categories.map(cat => {
            const count = counts[cat.slug] ?? 0
            return (
              <li key={cat.slug} className={`cat-item cat-item-${cat.slug}`}>
                <Link href={`/kategoria/${cat.slug}/`} className="flex justify-between items-center text-sm text-[var(--text-muted)] hover:text-[var(--accent)] transition-colors py-1">
                  <span className="flex items-center gap-2">
                    <span>{cat.icon}</span>
                    <span>{cat.label}</span>
                  </span>
                  <span className="text-xs bg-[var(--bg-section)] px-2 py-0.5 rounded-full border border-[var(--border)]">{count}</span>
                </Link>
              </li>
            )
          })}
        </ul>
      </section>

      {/* Stats widget */}
      <section className="widget widget_text bg-[var(--bg-section)] rounded-2xl border border-[var(--border)] p-5 text-center" style={{ boxShadow: 'var(--shadow)' }}>
        <div className="widget-title mb-3">
          <h3 className="font-heading text-base font-bold text-[var(--text)]">📊 WP Design Stats</h3>
        </div>
        <div className="textwidget widget-text">
          <div className="grid grid-cols-2 gap-3 text-left mt-3">
            <div className="bg-white rounded-xl border border-[var(--border)] p-3">
              <div className="text-xl font-bold text-[var(--accent)]">50+</div>
              <div className="text-[10px] uppercase tracking-wider text-[var(--text-muted)]">recenzji</div>
            </div>
            <div className="bg-white rounded-xl border border-[var(--border)] p-3">
              <div className="text-xl font-bold text-[var(--accent)]">4000+</div>
              <div className="text-[10px] uppercase tracking-wider text-[var(--text-muted)]">gier</div>
            </div>
            <div className="bg-white rounded-xl border border-[var(--border)] p-3">
              <div className="text-xl font-bold text-[var(--accent)]">24/7</div>
              <div className="text-[10px] uppercase tracking-wider text-[var(--text-muted)]">wsparcie</div>
            </div>
            <div className="bg-white rounded-xl border border-[var(--border)] p-3">
              <div className="text-xl font-bold text-[var(--accent)]">100%</div>
              <div className="text-[10px] uppercase tracking-wider text-[var(--text-muted)]">niezależni</div>
            </div>
          </div>
          <p className="text-xs text-[var(--text-muted)] leading-relaxed mt-4 mb-3">
            Niezależny portal o legalnych kasynach online dla polskich graczy.
          </p>
          <Link href="/o-nas/" className="text-xs text-[var(--accent)] font-semibold hover:underline">
            Dowiedz się więcej →
          </Link>
        </div>
      </section>

    </aside>
  )
}
