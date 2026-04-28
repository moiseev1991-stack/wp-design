import fs from 'fs'
import path from 'path'
import matter from 'gray-matter'
import { DEFAULT_CATEGORY, categoriesBySlug } from './categories'

export interface Post {
  title: string
  slug: string
  date: string
  description: string
  emoji: string
  featured: boolean
  moneyArticle: boolean
  category: string
  content: string
}

const postsDir = path.join(process.cwd(), 'content/posts')

export function getAllPosts(): Post[] {
  const files = fs.readdirSync(postsDir).filter(f => f.endsWith('.mdx'))
  const posts = files.map(file => {
    const raw = fs.readFileSync(path.join(postsDir, file), 'utf-8')
    const { data, content } = matter(raw)
    const rawCategory = (data.category as string | undefined) ?? DEFAULT_CATEGORY
    const category = categoriesBySlug[rawCategory] ? rawCategory : DEFAULT_CATEGORY
    return {
      title: data.title as string,
      slug: data.slug as string,
      date: data.date as string,
      description: data.description as string,
      emoji: (data.emoji as string) ?? '🎰',
      featured: Boolean(data.featured),
      moneyArticle: Boolean(data.moneyArticle),
      category,
      content,
    }
  })
  return posts.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
}

export function getPostBySlug(slug: string): Post | null {
  const all = getAllPosts()
  return all.find(p => p.slug === slug) ?? null
}

export function getRecentPosts(n: number): Post[] {
  return getAllPosts().slice(0, n)
}

export function getMoneyPosts(): Post[] {
  return getAllPosts().filter(p => p.moneyArticle)
}

export function getHomePosts(limit = 10, moneyOnHome = 3): Post[] {
  const posts = getAllPosts()
  const money = posts.filter(p => p.moneyArticle).slice(0, moneyOnHome)
  const moneySlugs = new Set(money.map(p => p.slug))
  const others = posts.filter(p => !moneySlugs.has(p.slug))
  return [...money, ...others].slice(0, limit)
}

export function getPostsByCategory(category: string): Post[] {
  return getAllPosts().filter(p => p.category === category)
}

export function getCategoryCounts(): Record<string, number> {
  const posts = getAllPosts()
  const counts: Record<string, number> = {}
  for (const p of posts) counts[p.category] = (counts[p.category] ?? 0) + 1
  return counts
}
