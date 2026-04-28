import { getAllPosts, getPostBySlug } from '@/lib/posts'
import { siteConfig } from '@/lib/config'
import type { Metadata } from 'next'

interface Props {
  params: { slug: string }
}

export async function generateStaticParams() {
  return getAllPosts().map(p => ({ slug: p.slug }))
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const post = getPostBySlug(params.slug)
  const target = `${siteConfig.url}/${params.slug}/`
  return {
    title: post ? post.title : 'Przekierowanie',
    description: post?.description ?? `Strona przeniesiona pod nowy adres: ${target}`,
    alternates: { canonical: target },
    robots: { index: false, follow: true },
  }
}

export default function BlogPostRedirect({ params }: Props) {
  const target = `/${params.slug}/`
  const script = `window.location.replace(${JSON.stringify(target)});`
  return (
    <div className="max-w-2xl mx-auto px-6 py-20 text-center">
      <noscript>
        <meta httpEquiv="refresh" content={`0; url=${target}`} />
      </noscript>
      <script dangerouslySetInnerHTML={{ __html: script }} />
      <h1 className="font-heading text-2xl font-bold text-[var(--text)] mb-4">Strona została przeniesiona</h1>
      <p className="text-[var(--text-muted)] mb-6">
        Trwa przekierowanie pod nowy adres. Jeśli to nie nastąpi automatycznie,{' '}
        <a className="text-[var(--accent)] underline" href={target}>kliknij tutaj</a>.
      </p>
    </div>
  )
}
