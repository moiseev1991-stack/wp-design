import { getAllPosts } from '@/lib/posts'
import { siteConfig } from '@/lib/config'
import PostCard from '@/components/PostCard'
import Breadcrumbs from '@/components/Breadcrumbs'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Blog – Wszystkie artykuły',
  description: 'Wszystkie artykuły WP Design – recenzje kasyn, bonusy, sloty, jackpoty, gry stołowe, płatności i mobilne kasyna online dla polskich graczy.',
  alternates: { canonical: `${siteConfig.url}/blog/` },
}

export default function BlogPage() {
  const posts = getAllPosts()

  return (
    <div className="archive blog max-w-6xl mx-auto px-4 sm:px-6 py-10">
      <Breadcrumbs items={[{ label: 'Blog', href: '/blog/' }]} />

      <header className="page-header mb-10">
        <h1 className="page-title font-heading text-4xl font-bold text-[var(--text)]">
          Blog – Wszystkie artykuły
        </h1>
        <p className="text-[var(--text-muted)] mt-3 max-w-2xl">
          Niezależne recenzje, bonusy, sloty, jackpoty, gry stołowe, płatności i mobilne kasyna — wszystkie artykuły WP Design w jednym miejscu.
        </p>
      </header>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-7">
        {posts.map(post => (
          <PostCard key={post.slug} post={post} />
        ))}
      </div>
    </div>
  )
}
