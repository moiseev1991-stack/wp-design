import { notFound } from 'next/navigation'
import Link from 'next/link'
import { MDXRemote } from 'next-mdx-remote/rsc'
import { getAllPosts, getPostBySlug } from '@/lib/posts'
import { siteConfig } from '@/lib/config'
import { categoriesBySlug } from '@/lib/categories'
import Breadcrumbs from '@/components/Breadcrumbs'
import Sidebar from '@/components/Sidebar'
import type { Metadata } from 'next'

interface Props {
  params: { slug: string }
}

const RESERVED_SLUGS = new Set([
  'blog', 'kategoria', 'o-nas', 'kontakt', 'polityka-prywatnosci', 'mapa-strony',
  'feed', 'sitemap.xml', 'robots.txt', 'wp-content', 'wp-json', '_next', 'api', 'app',
])

export async function generateStaticParams() {
  return getAllPosts()
    .filter(p => !RESERVED_SLUGS.has(p.slug))
    .map(p => ({ slug: p.slug }))
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const post = getPostBySlug(params.slug)
  if (!post) return {}
  return {
    title: post.title,
    description: post.description,
    alternates: { canonical: `${siteConfig.url}/${post.slug}/` },
    openGraph: {
      title: post.title, description: post.description,
      type: 'article', publishedTime: post.date,
      url: `${siteConfig.url}/${post.slug}/`,
    },
  }
}

function formatDate(d: string) {
  return new Date(d).toLocaleDateString('pl-PL', { day: 'numeric', month: 'long', year: 'numeric' })
}

function readingTime(content: string) {
  return Math.max(1, Math.ceil(content.split(/\s+/).length / 200))
}

function slugToPostId(slug: string): number {
  let h = 0
  for (let i = 0; i < slug.length; i++) h = (h * 31 + slug.charCodeAt(i)) >>> 0
  return (h % 9000) + 1000
}

const GRADIENTS: Record<string, [string, string]> = {
  '🎰': ['#1b4332', '#2d6a4f'],
  '🪟': ['#1e3a5f', '#2563eb'],
  '🪵': ['#451a03', '#92400e'],
  '🎨': ['#4a1d96', '#7c3aed'],
  '🌿': ['#134e4a', '#0d9488'],
  '💻': ['#1e293b', '#334155'],
  '✨': ['#365314', '#65a30d'],
  '🍳': ['#7c2d12', '#c2410c'],
  '💡': ['#713f12', '#d97706'],
  '🎁': ['#7c2d12', '#dc2626'],
  '💰': ['#713f12', '#ca8a04'],
  '🃏': ['#1e293b', '#475569'],
  '💳': ['#1e3a5f', '#2563eb'],
  '🎡': ['#4a1d96', '#a21caf'],
  '📱': ['#0c4a6e', '#0284c7'],
}

export default function PostPage({ params }: Props) {
  const post = getPostBySlug(params.slug)
  if (!post) notFound()

  const allPosts = getAllPosts()
  const sidebarPosts = allPosts.filter(p => p.slug !== post.slug).slice(0, 5)
  const mins = readingTime(post.content)
  const postId = slugToPostId(post.slug)
  const cat = categoriesBySlug[post.category]

  const [c1, c2] = GRADIENTS[post.emoji] ?? ['#1b4332', '#2d6a4f']

  const jsonLd = {
    '@context': 'https://schema.org', '@type': 'BlogPosting',
    headline: post.title, description: post.description,
    datePublished: post.date,
    author: { '@type': 'Organization', name: siteConfig.author },
    publisher: { '@type': 'Organization', name: siteConfig.name, url: siteConfig.url },
    url: `${siteConfig.url}/${post.slug}/`,
    inLanguage: 'pl',
  }

  return (
    <div className="nv-content-wrap max-w-6xl mx-auto px-4 sm:px-6 py-10">
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
      <Breadcrumbs items={cat ? [{ label: cat.label, href: `/kategoria/${cat.slug}/` }, { label: post.title }] : [{ label: post.title }]} />

      <div className="flex flex-col lg:flex-row gap-10">

        <div className="lg:w-[65%]">
          <article
            id={`post-${postId}`}
            className={`post-${postId} post type-post status-publish format-standard hentry category-${post.category} has-post-thumbnail`}
          >
            {/* Featured image */}
            <div
              className="post-thumbnail relative w-full rounded-2xl overflow-hidden mb-7 flex items-center justify-center"
              style={{ height: 280, background: `linear-gradient(135deg, ${c1} 0%, ${c2} 100%)` }}
            >
              <svg className="absolute inset-0 w-full h-full opacity-10" xmlns="http://www.w3.org/2000/svg">
                <defs>
                  <pattern id="art-dots" x="0" y="0" width="30" height="30" patternUnits="userSpaceOnUse">
                    <circle cx="15" cy="15" r="1" fill="white"/>
                  </pattern>
                </defs>
                <rect width="100%" height="100%" fill="url(#art-dots)"/>
              </svg>
              <div className="absolute -bottom-6 -right-6 w-40 h-40 rounded-full bg-white/5" />
              <span className="wp-post-image relative text-[110px] select-none drop-shadow-2xl" role="img" aria-label={post.title}>{post.emoji}</span>
            </div>

            <header className="entry-header">
              <div className="entry-meta flex flex-wrap items-center gap-3 mb-3">
                <span className="posted-on">
                  <time className="entry-date published updated text-sm text-[var(--text-muted)]" dateTime={post.date}>{formatDate(post.date)}</time>
                </span>
                <span className="w-1 h-1 rounded-full bg-[var(--border)]" />
                <span className="reading-time text-sm text-[var(--text-muted)]">{mins} min czytania</span>
                <span className="w-1 h-1 rounded-full bg-[var(--border)]" />
                <span className="byline vcard">
                  <span className="author fn n text-xs font-semibold text-[var(--accent)] bg-[var(--accent)]/10 px-2.5 py-0.5 rounded-full">{siteConfig.author}</span>
                </span>
              </div>

              <h1 className="entry-title font-heading text-3xl sm:text-4xl font-bold text-[var(--text)] leading-tight mb-6">
                {post.title}
              </h1>
            </header>

            <div className="entry-content prose prose-lg max-w-none prose-headings:font-heading prose-a:text-[var(--accent)] wp-block-post-content">
              <MDXRemote source={post.content} />
            </div>

            <footer className="entry-footer mt-6 pt-4 border-t border-[var(--border)]">
              <span className="cat-links text-xs text-[var(--text-muted)]">
                Kategoria: {cat ? (
                  <Link href={`/kategoria/${cat.slug}/`} rel="category tag" className="text-[var(--accent)] hover:underline">{cat.label}</Link>
                ) : (
                  <span className="text-[var(--accent)]">Inne</span>
                )}
              </span>
            </footer>
          </article>

          {/* Related articles */}
          <div className="mt-8 pt-8 border-t border-[var(--border)]">
            <h3 className="font-heading text-xl font-bold text-[var(--text)] mb-4">Czytaj również</h3>
            <div className="flex flex-col gap-3">
              {allPosts.filter(p => p.slug !== post.slug).slice(0, 3).map(related => (
                <Link key={related.slug} href={`/${related.slug}/`} className="flex items-center gap-3 p-3 rounded-xl hover:bg-[var(--bg-section)] transition-colors border border-[var(--border)] group">
                  <span className="text-2xl">{related.emoji}</span>
                  <div>
                    <div className="text-sm font-semibold text-[var(--text)] group-hover:text-[var(--accent)] transition-colors line-clamp-1">{related.title}</div>
                    <div className="text-xs text-[var(--text-muted)] mt-0.5">{readingTime(related.content)} min czytania</div>
                  </div>
                  <span className="ml-auto text-[var(--accent)] opacity-0 group-hover:opacity-100 transition-opacity">→</span>
                </Link>
              ))}
            </div>
          </div>
        </div>

        <div className="lg:w-[35%] nv-sidebar-wrap">
          <div className="sticky top-20">
            <Sidebar recentPosts={sidebarPosts} />
          </div>
        </div>
      </div>
    </div>
  )
}
