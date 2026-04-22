# Инструкция: создать новый аффилиатный сайт с нуля

## Что получится

Статический Next.js сайт под WordPress-маскировку. Тематика — **автомобили и вождение** (немецкий язык, `auto-ratgeber.de`). Аффилиатная ссылка Vulkan Vegas встроена в первый пост, который всегда стоит первым в сетке на главной и в блоге. Без GitHub, без деплоя — только сборка локально.

---

## Шаг 1 — Создать проект Next.js

```bash
mkdir e:/cod/auto-ratgeber
cd e:/cod/auto-ratgeber
npx create-next-app@latest . --typescript --tailwind --app --no-src-dir --no-import-alias
```

На вопросы отвечай:
- `Would you like to use ESLint?` → **Yes**
- `Would you like to use Turbopack?` → **No**

---

## Шаг 2 — Установить зависимости

```bash
npm install gray-matter
npm install -D @types/node
```

`gray-matter` — парсит frontmatter в `.mdx` файлах (заголовок, дата, описание).

---

## Шаг 3 — Настроить next.config.js

Заменить содержимое `next.config.js`:

```js
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  trailingSlash: true,
  images: { unoptimized: true },
}

module.exports = nextConfig
```

`output: 'export'` — сборка в статические HTML файлы в папку `out/`.

---

## Шаг 4 — Создать конфиг сайта

Создать файл `lib/config.ts`:

```typescript
export const siteConfig = {
  name: "Auto Ratgeber",
  tagline: "Tipps und Ratschläge rund ums Auto",
  url: "https://auto-ratgeber.de",
  description: "Auto Ratgeber – Ihr Portal für Fahrtipps, Autopflege und Neuigkeiten aus der Autowelt für deutsche Fahrer.",
  language: "de",
  moneyPageUrl: "https://vulkankasyno.pl",
  moneyPageAnchor: "Vulkan Vegas",
  moneyPageAnchorAlt: "bestes Online Casino",
  moneyPageBonus: "Willkommensbonus bis 4000 PLN",
  featuredPostSlug: "beste-online-casinos-fuer-deutsche-spieler",  // ← слаг казино-поста
  author: "Redaktion Auto Ratgeber",
  wpVersion: "6.5.2",
  wpTheme: "autoratgeber-theme",
}
```

**`featuredPostSlug`** — это ключевое поле. Именно этот слаг будет закреплён первым на главной странице и в /blog/ независимо от даты.

---

## Шаг 5 — Создать парсер статей

Создать файл `lib/posts.ts`:

```typescript
import fs from 'fs'
import path from 'path'
import matter from 'gray-matter'

export interface Post {
  title: string
  slug: string
  date: string
  description: string
  emoji: string
  featured: boolean
  content: string
}

const postsDir = path.join(process.cwd(), 'content/posts')

export function getAllPosts(): Post[] {
  const files = fs.readdirSync(postsDir).filter(f => f.endsWith('.mdx'))
  const posts = files.map(file => {
    const raw = fs.readFileSync(path.join(postsDir, file), 'utf-8')
    const { data, content } = matter(raw)
    return {
      title: data.title as string,
      slug: data.slug as string,
      date: data.date as string,
      description: data.description as string,
      emoji: data.emoji as string,
      featured: Boolean(data.featured),
      content,
    }
  })
  return posts.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
}

export function getPostBySlug(slug: string): Post | null {
  const all = getAllPosts()
  return all.find(p => p.slug === slug) ?? null
}
```

---

## Шаг 6 — Главная страница (app/page.tsx)

Вот как работает логика закрепления казино-поста первым:

```typescript
import Link from 'next/link'
import { getAllPosts, getPostBySlug } from '@/lib/posts'
import { siteConfig } from '@/lib/config'
import PostCard from '@/components/PostCard'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: `${siteConfig.name} – ${siteConfig.tagline}`,
  description: siteConfig.description,
  alternates: { canonical: siteConfig.url + '/' },
  openGraph: { title: siteConfig.name, description: siteConfig.description, url: siteConfig.url, type: 'website' },
}

export default function HomePage() {
  const allPosts = getAllPosts()

  // Казино-пост всегда первый, остальные — по дате
  const featuredPost = getPostBySlug(siteConfig.featuredPostSlug)
  const otherPosts = allPosts.filter(p => p.slug !== siteConfig.featuredPostSlug).slice(0, 5)
  const latestPosts = featuredPost ? [featuredPost, ...otherPosts] : allPosts.slice(0, 6)

  const jsonLd = {
    '@context': 'https://schema.org', '@type': 'WebSite',
    name: siteConfig.name, url: siteConfig.url, description: siteConfig.description, inLanguage: 'de',
  }

  return (
    <>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />

      <section className="max-w-6xl mx-auto px-4 sm:px-6 py-16">
        <div className="flex items-end justify-between mb-10">
          <div>
            <h2 className="text-3xl sm:text-4xl font-bold">
              Artikel und Ratschläge
            </h2>
          </div>
          <Link href="/blog/" className="hidden sm:inline-flex items-center gap-1.5 text-sm font-semibold hover:gap-3 transition-all">
            Alle Artikel <span>→</span>
          </Link>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {latestPosts.map(post => (
            <PostCard
              key={post.slug}
              post={post}
              // Для казино-поста подставляем кастомный анонс с аффилиатной ссылкой
              customExcerpt={post.slug === siteConfig.featuredPostSlug ? (
                <>
                  Die besten Casinos für deutsche Spieler.{' '}
                  <a href={siteConfig.moneyPageUrl} target="_blank" rel="noopener" className="font-semibold underline">
                    {siteConfig.moneyPageAnchor}
                  </a>
                  {' '}– {siteConfig.moneyPageBonus} und schnelle Auszahlungen.
                </>
              ) : undefined}
            />
          ))}
        </div>

        <div className="mt-10 flex justify-center sm:hidden">
          <Link href="/blog/" className="text-sm font-semibold border px-6 py-2.5 rounded-xl">
            Alle Artikel →
          </Link>
        </div>
      </section>
    </>
  )
}
```

**Как работает вставка ссылки на главной:**
- `PostCard` принимает необязательный проп `customExcerpt`
- Если пост — это `featuredPostSlug`, передаётся JSX с аффилиатной ссылкой вместо обычного `description`
- Ссылка `<a href={siteConfig.moneyPageUrl}>` открывается в новой вкладке с `rel="noopener"`
- Для всех других постов `customExcerpt` не передаётся, рендерится стандартный `post.description`

---

## Шаг 7 — Страница блога (app/blog/page.tsx)

Та же логика закрепления — казино-пост всегда первым:

```typescript
import Link from 'next/link'
import { getAllPosts, getPostBySlug } from '@/lib/posts'
import { siteConfig } from '@/lib/config'
import PostCard from '@/components/PostCard'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Blog – Tipps und Ratschläge',
  description: 'Artikel über Autopflege, Fahrtipps und Neuigkeiten für deutsche Autofahrer.',
  alternates: { canonical: `${siteConfig.url}/blog/` },
}

export default function BlogPage() {
  // Казино-пост вытягиваем отдельно и ставим первым
  const featuredPost = getPostBySlug(siteConfig.featuredPostSlug)
  const otherPosts = getAllPosts().filter(p => p.slug !== siteConfig.featuredPostSlug)
  const posts = featuredPost ? [featuredPost, ...otherPosts] : getAllPosts()

  return (
    <div className="max-w-6xl mx-auto px-4 sm:px-6 py-10">
      <h1 className="text-4xl font-bold mb-10">Blog – Tipps und Ratschläge</h1>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-7">
        {posts.map(post => (
          <PostCard
            key={post.slug}
            post={post}
            customExcerpt={post.slug === siteConfig.featuredPostSlug ? (
              <>
                Die besten Casinos für deutsche Spieler.{' '}
                <a href={siteConfig.moneyPageUrl} target="_blank" rel="noopener" className="font-semibold underline">
                  {siteConfig.moneyPageAnchor}
                </a>
                {' '}– {siteConfig.moneyPageBonus} und schnelle Auszahlungen.
              </>
            ) : undefined}
          />
        ))}
      </div>
    </div>
  )
}
```

---

## Шаг 8 — Компонент карточки (components/PostCard.tsx)

```typescript
import Link from 'next/link'
import type { Post } from '@/lib/posts'

interface Props {
  post: Post
  customExcerpt?: React.ReactNode
}

function formatDate(d: string) {
  return new Date(d).toLocaleDateString('de-DE', { day: 'numeric', month: 'long', year: 'numeric' })
}

function readingTime(content: string) {
  return Math.max(1, Math.ceil(content.split(/\s+/).length / 200))
}

export default function PostCard({ post, customExcerpt }: Props) {
  const mins = readingTime(post.content)

  return (
    <article className="bg-white rounded-2xl overflow-hidden border flex flex-col shadow-sm hover:shadow-md transition-shadow">
      <div className="p-5 flex flex-col flex-1">
        <div className="flex items-center gap-3 text-xs text-gray-400 mb-2.5">
          <time dateTime={post.date}>{formatDate(post.date)}</time>
          <span>·</span>
          <span>{mins} Min. Lesezeit</span>
        </div>

        <h3 className="text-lg font-bold mb-2 leading-snug line-clamp-2">
          <Link href={`/blog/${post.slug}/`} className="hover:text-blue-600 transition-colors">
            {post.title}
          </Link>
        </h3>

        {/* customExcerpt для казино-поста содержит аффилиатную ссылку */}
        <p className="text-sm text-gray-500 leading-relaxed line-clamp-2 flex-1 mb-4">
          {customExcerpt ?? post.description}
        </p>

        <Link
          href={`/blog/${post.slug}/`}
          className="self-start text-sm text-blue-600 font-semibold hover:underline"
        >
          Weiterlesen →
        </Link>
      </div>
    </article>
  )
}
```

---

## Шаг 9 — Страница поста (app/blog/[slug]/page.tsx)

Создать директорию `app/blog/[slug]/` и файл `page.tsx`:

```typescript
import { getAllPosts, getPostBySlug } from '@/lib/posts'
import { siteConfig } from '@/lib/config'
import { notFound } from 'next/navigation'
import type { Metadata } from 'next'

export async function generateStaticParams() {
  return getAllPosts().map(post => ({ slug: post.slug }))
}

export async function generateMetadata({ params }: { params: { slug: string } }): Promise<Metadata> {
  const post = getPostBySlug(params.slug)
  if (!post) return {}
  return {
    title: post.title,
    description: post.description,
    alternates: { canonical: `${siteConfig.url}/blog/${post.slug}/` },
  }
}

export default function PostPage({ params }: { params: { slug: string } }) {
  const post = getPostBySlug(params.slug)
  if (!post) notFound()

  return (
    <article className="max-w-3xl mx-auto px-4 sm:px-6 py-12">
      <h1 className="text-3xl sm:text-4xl font-bold mb-4">{post.title}</h1>
      <p className="text-sm text-gray-400 mb-8">{post.date}</p>
      {/* Рендер контента — замени на MDX-рендерер если нужна разметка */}
      <div className="prose prose-gray max-w-none whitespace-pre-wrap">
        {post.content}
      </div>
    </article>
  )
}
```

---

## Шаг 10 — layout.tsx с WordPress-маскировкой

```typescript
import type { Metadata } from 'next'
import './globals.css'
import { siteConfig } from '@/lib/config'

export const metadata: Metadata = {
  title: { default: siteConfig.name, template: `%s | ${siteConfig.name}` },
  description: siteConfig.description,
  metadataBase: new URL(siteConfig.url),
  other: { generator: `WordPress ${siteConfig.wpVersion}` },
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang={siteConfig.language}>
      <head>
        <link rel="dns-prefetch" href="//s.w.org" />
        <link rel="pingback" href={`${siteConfig.url}/xmlrpc.php`} />
        <link rel="https://api.w.org/" href={`${siteConfig.url}/wp-json/`} />
        <link rel="EditURI" type="application/rsd+xml" href={`${siteConfig.url}/xmlrpc.php?rsd`} />
        <meta name="generator" content={`WordPress ${siteConfig.wpVersion}`} />
        <link rel="stylesheet" href={`${siteConfig.url}/wp-content/themes/${siteConfig.wpTheme}/style.css?ver=${siteConfig.wpVersion}`} />
      </head>
      <body className="wordpress home blog">
        <div id="page" className="site">
          <header id="masthead">
            <div className="max-w-6xl mx-auto px-4 py-4 flex items-center justify-between">
              <a href="/" className="text-xl font-bold">{siteConfig.name}</a>
              <nav>
                <a href="/blog/" className="text-sm hover:underline">Blog</a>
              </nav>
            </div>
          </header>
          <div id="content">
            <main id="main" className="min-h-screen">{children}</main>
          </div>
          <footer id="colophon" className="border-t mt-16 py-8 text-center text-sm text-gray-400">
            <p>© {new Date().getFullYear()} {siteConfig.name}. Alle Rechte vorbehalten.</p>
            <p className="mt-2">
              <a href="/datenschutz/" className="hover:underline">Datenschutz</a>
              {' · '}
              <a href="/impressum/" className="hover:underline">Impressum</a>
            </p>
          </footer>
        </div>
      </body>
    </html>
  )
}
```

---

## Шаг 11 — Создать статьи

Создать папку `content/posts/`.

### Структура frontmatter каждого `.mdx` файла:

```
---
title: "Заголовок статьи"
slug: "url-slug-statyi"
date: "2026-11-20"
description: "Краткое описание, видно в карточке и в meta description."
emoji: "🚗"
featured: false
---

Текст статьи...
```

**Поле `emoji`** определяет цвет и иконку карточки в `PostCard`. Задай разные эмодзи для каждой статьи — тематические.

**Поле `slug`** должно совпадать с именем файла (без `.mdx`) и с URL страницы `/blog/SLUG/`.

---

### Пример обычной статьи — `content/posts/auto-wintercheck.mdx`:

```mdx
---
title: "Auto-Wintercheck: So bereiten Sie Ihr Fahrzeug auf den Winter vor"
slug: "auto-wintercheck"
date: "2026-11-20"
description: "Ein gründlicher Wintercheck schützt Sie und Ihr Auto. Wir erklären, worauf Sie achten müssen."
emoji: "❄️"
featured: false
---

Der Winter stellt besondere Anforderungen an Fahrzeug und Fahrer. Wer rechtzeitig handelt, vermeidet teure Pannen und bleibt sicher auf der Straße.

## Reifen und Bremsen

Winterreifen sind in Deutschland bei winterlichen Straßenverhältnissen Pflicht. Das Reifenprofil sollte mindestens 4 mm betragen – auch wenn gesetzlich nur 1,6 mm vorgeschrieben sind. Kontrollieren Sie außerdem den Reifendruck...
```

---

### Обязательная казино-статья — `content/posts/beste-online-casinos-fuer-deutsche-spieler.mdx`

**Имя файла должно совпадать со `slug` в frontmatter и с `featuredPostSlug` в `lib/config.ts`.**

```mdx
---
title: "Beste Online Casinos für deutsche Spieler – Ratgeber 2026"
slug: "beste-online-casinos-fuer-deutsche-spieler"
date: "2026-11-12"
description: "Welche Online Casinos sind für deutsche Spieler am besten? Vulkan Vegas überzeugt mit MGA-Lizenz, großem Willkommensbonus und schnellen Auszahlungen."
emoji: "🎰"
featured: true
---

Der Online-Casino-Markt wächst rasant. Doch welche Plattformen sind wirklich vertrauenswürdig? Wer auf der Suche nach einem seriösen Anbieter ist, stößt schnell auf [Vulkan Vegas](https://vulkankasyno.pl) – ein lizenziertes Casino mit breitem Spielangebot und attraktivem Willkommensbonus. In diesem Ratgeber erklären wir, worauf Sie achten sollten.

## Worauf kommt es bei der Wahl an?

Das wichtigste Kriterium ist die **Lizenz**. Seriöse Casinos verfügen über eine Genehmigung der Malta Gaming Authority (MGA) oder der UK Gambling Commission (UKGC). Ohne sichtbare Lizenz sollten Sie die Finger von einer Plattform lassen.

Ebenso entscheidend ist die **SSL-Verschlüsselung** – erkennbar am Schloss-Symbol in der Adressleiste. Geben Sie niemals Zahlungsdaten auf einer unverschlüsselten Seite ein.

## Bonusangebote richtig bewerten

Ein Willkommensbonus kann mehrere tausend Zloty betragen, dazu kommen oft Freispiele. Entscheidend ist jedoch der **Umsatzbedarf** (Wagering Requirement). Ein Faktor von x30 bedeutet, dass Sie den Bonusbetrag 30-mal umsetzen müssen, bevor eine Auszahlung möglich ist. Der Standard liegt bei x20 bis x40.

[Vulkan Vegas](https://vulkankasyno.pl) bietet einen transparenten Willkommensbonus mit fairen Umsatzbedingungen und einem umfangreichen Spielangebot von Topanbietern.

## Zahlungsmethoden für deutsche Spieler

Für Spieler aus Deutschland sind Visa, Mastercard und PayPal die beliebtesten Optionen. E-Wallets wie Skrill und Neteller bieten zusätzliche Privatsphäre und oft schnellere Auszahlungen. Auszahlungen sollten innerhalb von 24 bis 48 Stunden bearbeitet werden.

## Live-Casino – das Spielhallen-Erlebnis zuhause

Jedes seriöse Online-Casino bietet heute eine Live-Casino-Sektion mit echten Dealern per Video-Stream. Blackjack, Roulette und Baccarat in Dutzenden Varianten – authentisches Spielhallen-Feeling vom Sofa aus.

## Verantwortungsvolles Spielen

Seriöse Plattformen bieten Werkzeuge zur Spielkontrolle: Einzahlungslimits, Auszeiten und Selbstsperrung. Setzen Sie sich vor jeder Session ein Budget und halten Sie es ein.

Wer einen vertrauenswürdigen Anbieter sucht, sollte [Vulkan Vegas](https://vulkankasyno.pl) besuchen und das aktuelle Bonusangebot prüfen.

*Glücksspiel kann süchtig machen. Spielen Sie verantwortungsbewusst. Nur für Personen ab 18 Jahren.*
```

---

## Шаг 12 — Как связана казино-статья с главной страницей

Вся логика держится на трёх местах:

**1. `lib/config.ts`** — `featuredPostSlug` содержит слаг казино-поста:
```typescript
featuredPostSlug: "beste-online-casinos-fuer-deutsche-spieler",
```

**2. `app/page.tsx`** — выдёргивает казино-пост и ставит первым вне зависимости от даты:
```typescript
const featuredPost = getPostBySlug(siteConfig.featuredPostSlug)
const otherPosts = allPosts.filter(p => p.slug !== siteConfig.featuredPostSlug).slice(0, 5)
const latestPosts = featuredPost ? [featuredPost, ...otherPosts] : allPosts.slice(0, 6)
```

**3. В `latestPosts.map()`** — для казино-поста передаётся `customExcerpt` с аффилиатной ссылкой:
```tsx
customExcerpt={post.slug === siteConfig.featuredPostSlug ? (
  <>Текст... <a href={siteConfig.moneyPageUrl}>{siteConfig.moneyPageAnchor}</a> ...текст.</>
) : undefined}
```

Если `customExcerpt` передан — `PostCard` рендерит его вместо `post.description`. Если не передан — рендерит обычное описание из frontmatter.

То же самое в `app/blog/page.tsx` — одинаковая логика.

---

## Шаг 13 — Написать остальные статьи

Написать минимум 5–7 статей по тематике сайта. Примеры для авто-тематики:

| Файл | Slug | Emoji | Тема |
|------|------|-------|------|
| `auto-wintercheck.mdx` | `auto-wintercheck` | ❄️ | Зимняя подготовка |
| `reifencheck-sommer.mdx` | `reifencheck-sommer` | ☀️ | Летние шины |
| `autobatterie-wechseln.mdx` | `autobatterie-wechseln` | 🔋 | Замена аккумулятора |
| `motoroel-ratgeber.mdx` | `motoroel-ratgeber` | 🛢️ | Выбор моторного масла |
| `stau-tipps.mdx` | `stau-tipps` | 🚦 | Советы в пробках |
| `autopflege-tipps.mdx` | `autopflege-tipps` | ✨ | Уход за автомобилем |

Казино-статья: файл `beste-online-casinos-fuer-deutsche-spieler.mdx` — слаг должен точно совпадать с `featuredPostSlug` в конфиге.

---

## Шаг 14 — Favicon

Создать `public/favicon.svg`:

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <rect width="100" height="100" rx="20" fill="#1d4ed8"/>
  <text x="50" y="45" text-anchor="middle" dominant-baseline="middle"
    font-family="Arial Black, sans-serif" font-weight="900" font-size="38" fill="#ffffff">
    AUTO
  </text>
  <text x="50" y="72" text-anchor="middle" dominant-baseline="middle"
    font-family="Arial, sans-serif" font-weight="400" font-size="22" fill="#93c5fd">
    Ratgeber
  </text>
</svg>
```

---

## Шаг 15 — Проверить что все файлы на месте

```
auto-ratgeber/
├── app/
│   ├── layout.tsx
│   ├── page.tsx
│   ├── globals.css
│   └── blog/
│       ├── page.tsx
│       └── [slug]/
│           └── page.tsx
├── components/
│   └── PostCard.tsx
├── content/
│   └── posts/
│       ├── beste-online-casinos-fuer-deutsche-spieler.mdx  ← казино
│       ├── auto-wintercheck.mdx
│       ├── reifencheck-sommer.mdx
│       └── ... (остальные статьи)
├── lib/
│   ├── config.ts
│   └── posts.ts
├── public/
│   └── favicon.svg
└── next.config.js
```

---

## Шаг 16 — Локальная сборка и проверка

```bash
# Запустить dev-сервер
npm run dev
# Открыть http://localhost:3000

# Проверить:
# - Казино-пост стоит первым на главной /
# - Казино-пост стоит первым на /blog/
# - В карточке казино-поста видна ссылка Vulkan Vegas
# - Остальные посты рендерятся без аффилиатной ссылки в описании
# - Страница /blog/beste-online-casinos-fuer-deutsche-spieler/ открывается
# - Ссылки на Vulkan Vegas внутри статьи кликабельны

# Финальная сборка в статику
npm run build
# Файлы появятся в папке out/
```

---

## Чеклист перед сборкой

- [ ] `lib/config.ts` — `featuredPostSlug` совпадает со `slug` в frontmatter казино-поста
- [ ] `lib/config.ts` — `featuredPostSlug` совпадает с именем `.mdx` файла (без расширения)
- [ ] Казино-пост первым на главной: `getPostBySlug(siteConfig.featuredPostSlug)` возвращает пост
- [ ] Казино-пост первым в блоге: та же проверка в `app/blog/page.tsx`
- [ ] В казино-посте хотя бы одна ссылка `[Vulkan Vegas](https://vulkankasyno.pl)` в первом абзаце
- [ ] В `customExcerpt` на главной и в блоге — ссылка `<a href={siteConfig.moneyPageUrl}>`
- [ ] Все статьи имеют уникальный `slug`
- [ ] `npm run build` проходит без ошибок

---

## Что менять при создании каждого нового сайта

| Файл | Что менять |
|------|-----------|
| `lib/config.ts` | `name`, `tagline`, `url`, `language`, `featuredPostSlug`, `author` |
| `content/posts/` | все статьи — новый язык, новая тематика |
| `app/page.tsx` | текст заголовка секции, текст `customExcerpt` на нужном языке |
| `app/blog/page.tsx` | заголовок страницы, текст `customExcerpt` |
| `public/favicon.svg` | буквы и цвет под тематику |
| `app/layout.tsx` | язык `lang=`, текст в footer |
