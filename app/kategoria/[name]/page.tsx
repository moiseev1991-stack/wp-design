import { notFound } from 'next/navigation'
import type { Metadata } from 'next'
import { categories, categoriesBySlug } from '@/lib/categories'
import { getPostsByCategory } from '@/lib/posts'
import { siteConfig } from '@/lib/config'
import Breadcrumbs from '@/components/Breadcrumbs'
import PostCard from '@/components/PostCard'

interface Props {
  params: { name: string }
}

export function generateStaticParams() {
  return categories.map(c => ({ name: c.slug }))
}

export function generateMetadata({ params }: Props): Metadata {
  const cat = categoriesBySlug[params.name]
  if (!cat) return {}
  return {
    title: cat.label,
    description: cat.description,
    alternates: { canonical: `${siteConfig.url}/kategoria/${cat.slug}/` },
  }
}

export default function CategoryPage({ params }: Props) {
  const cat = categoriesBySlug[params.name]
  if (!cat) notFound()

  const posts = getPostsByCategory(cat.slug)

  return (
    <div className="archive max-w-6xl mx-auto px-4 sm:px-6 py-10">
      <Breadcrumbs items={[{ label: 'Kategorie', href: '/kategoria/' }, { label: cat.label }]} />

      <header className="page-header mb-10 flex items-start gap-5">
        <div className="text-6xl">{cat.icon}</div>
        <div>
          <h1 className="page-title font-heading text-4xl font-bold text-[var(--text)] mb-2">{cat.label}</h1>
          <p className="text-[var(--text-muted)] max-w-2xl leading-relaxed">{cat.description}</p>
          <div className="mt-3 text-sm text-[var(--text-muted)]">
            <span className="bg-[var(--bg-section)] px-3 py-1 rounded-full border border-[var(--border)]">
              {posts.length} {posts.length === 1 ? 'artykuł' : 'artykułów'}
            </span>
          </div>
        </div>
      </header>

      {posts.length === 0 ? (
        <div className="bg-[var(--bg-card)] border border-[var(--border)] rounded-2xl p-10 text-center">
          <div className="text-4xl mb-3">📭</div>
          <p className="text-[var(--text-muted)]">W tej kategorii nie ma jeszcze artykułów. Zajrzyj wkrótce.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-7">
          {posts.map(post => (
            <PostCard key={post.slug} post={post} />
          ))}
        </div>
      )}
    </div>
  )
}
