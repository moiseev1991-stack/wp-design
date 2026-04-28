#!/usr/bin/env node
/**
 * Monthly auto-post generator for wp-design.org (Polish online casino guide).
 *
 * Generates ONE general-theme article (no Vulkan / brand mentions, moneyArticle: false)
 * under one of the 8 site categories. Run by GitHub Actions on the 1st of each month.
 *
 * Required env: OPENAI_API_KEY
 * Optional env: OPENAI_MODEL (default: gpt-4o)
 */
import fs from 'node:fs'
import path from 'node:path'
import process from 'node:process'

const OPENAI_API_KEY = process.env.OPENAI_API_KEY
if (!OPENAI_API_KEY) {
  console.error('OPENAI_API_KEY is not set')
  process.exit(1)
}

const OPENAI_MODEL = process.env.OPENAI_MODEL || 'gpt-4o'

const ROOT = process.cwd()
const POSTS_DIR = path.join(ROOT, 'content', 'posts')
const ILLUSTRATIONS_DIR = path.join(ROOT, 'public', 'illustrations')

// Site categories — must match lib/categories.ts
const CATEGORIES = [
  { slug: 'recenzje',    label: 'Recenzje kasyn', icon: '🎰', topics: 'recenzje konkretnych kasyn online (bez wymieniania marek z naszej promocji), kryteria oceny operatorów, porównania platform' },
  { slug: 'bonusy',      label: 'Bonusy',         icon: '🎁', topics: 'rodzaje bonusów, wagering, free spiny, cashback, reload, programy lojalnościowe, regulaminy' },
  { slug: 'sloty',       label: 'Sloty',          icon: '🎡', topics: 'mechaniki slotów, RTP, zmienność, recenzje konkretnych tytułów slotów, dostawcy oprogramowania' },
  { slug: 'jackpoty',    label: 'Jackpoty',       icon: '💰', topics: 'jackpoty progresywne, must-drop, mechanika pul, najgłośniejsze wygrane, szanse i strategia' },
  { slug: 'gry-stolowe', label: 'Gry stołowe',    icon: '🃏', topics: 'blackjack, ruletka, baccarat, poker kasynowy, live casino, strategie gier stołowych' },
  { slug: 'platnosci',   label: 'Płatności',      icon: '💳', topics: 'BLIK, Przelewy24, e-portfele, kryptowaluty, karty, wypłaty, KYC, AML' },
  { slug: 'mobilne',     label: 'Mobilne kasyna', icon: '📱', topics: 'aplikacje na Android i iOS, PWA, mobilne live casino, bezpieczeństwo na telefonie, mobilne bonusy' },
  { slug: 'poradniki',   label: 'Poradniki',      icon: '💡', topics: 'rejestracja, KYC, weryfikacja, odpowiedzialna gra, bezpieczeństwo, zarządzanie bankrollem' },
]

// Emoji → SVG gradient mapping in components/PostCard.tsx + app/[slug]/page.tsx.
// Stick to these so the article gets a proper themed thumbnail.
const ALLOWED_EMOJIS = ['🎰', '🎁', '🎡', '💰', '🃏', '💳', '📱', '💡', '✨']

// Slugs that collide with site routes — generator must never produce them.
const RESERVED_SLUGS = new Set([
  'blog', 'kategoria', 'o-nas', 'kontakt', 'polityka-prywatnosci', 'mapa-strony',
  'feed', 'sitemap.xml', 'robots.txt', 'wp-content', 'wp-json', 'wp-login.php',
  '_next', '_redirects', 'api', 'app', 'index', 'home', 'favicon',
])

// Brand mentions strictly forbidden in auto-generated content (money articles
// stay hand-written so we don't dilute the conversion link).
const FORBIDDEN_PHRASES = [
  'vulkan vegas', 'vulkan kasyno', 'vulkankasyno', 'vulkankasyno.pl', 'vulkan.pl',
]

if (!fs.existsSync(ILLUSTRATIONS_DIR)) fs.mkdirSync(ILLUSTRATIONS_DIR, { recursive: true })
if (!fs.existsSync(POSTS_DIR)) fs.mkdirSync(POSTS_DIR, { recursive: true })

function readExistingPosts() {
  const files = fs.readdirSync(POSTS_DIR).filter(f => f.endsWith('.mdx'))
  const slugs = []
  const titles = []
  for (const f of files) {
    const raw = fs.readFileSync(path.join(POSTS_DIR, f), 'utf-8')
    const slugMatch = raw.match(/^slug:\s*"([^"]+)"/m)
    const titleMatch = raw.match(/^title:\s*"([^"]+)"/m)
    if (slugMatch) slugs.push(slugMatch[1])
    if (titleMatch) titles.push(titleMatch[1])
  }
  return { slugs, titles }
}

function pickLeastPopulatedCategory(existingSlugs) {
  const counts = Object.fromEntries(CATEGORIES.map(c => [c.slug, 0]))
  for (const slug of existingSlugs) {
    for (const c of CATEGORIES) {
      // Heuristic: if a slug clearly looks like one of the category topics, count it.
      // We can't be 100% accurate without parsing frontmatter, but this is good enough
      // to bias the generator toward thinner sections over time.
    }
  }
  // For now just pick a random category — readExistingPosts doesn't include category info.
  return CATEGORIES[Math.floor(Math.random() * CATEGORIES.length)]
}

async function callOpenAI({ messages, jsonMode = false, maxTokens = 6000 }) {
  const res = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${OPENAI_API_KEY}`,
    },
    body: JSON.stringify({
      model: OPENAI_MODEL,
      messages,
      max_tokens: maxTokens,
      ...(jsonMode ? { response_format: { type: 'json_object' } } : {}),
    }),
  })
  if (!res.ok) {
    const errText = await res.text()
    throw new Error(`OpenAI API error ${res.status}: ${errText}`)
  }
  const data = await res.json()
  return data.choices[0].message.content
}

async function pickTopic({ existingSlugs, existingTitles, category }) {
  const messages = [
    {
      role: 'system',
      content:
        'You are a content strategist for wp-design.org — an independent Polish-language guide to online casinos for Polish players. You always respond with strict JSON.',
    },
    {
      role: 'user',
      content: `Pick a fresh topic for a new SEO-optimized blog post in Polish, in the category "${category.label}".

Suggested topic angles for this category:
${category.topics}

The post must NOT duplicate any of these existing posts.

Existing slugs:
${existingSlugs.map(s => `- ${s}`).join('\n')}

Existing titles:
${existingTitles.map(t => `- ${t}`).join('\n')}

CRITICAL constraints:
- The article will run on a casino-affiliate site, but THIS post is GENERAL/EDUCATIONAL, NOT a brand promotion.
- Do NOT mention "Vulkan Vegas", "Vulkan Kasyno", "vulkankasyno.pl" or any other specific casino brand by name.
- You may name SOFTWARE PROVIDERS (NetEnt, Pragmatic Play, Microgaming, Evolution, Play'n GO, Yggdrasil, Quickspin, Playtech) — those are OK.
- Stay informative, neutral, useful for Polish players.

Return strict JSON:
{
  "slug": "lowercase-kebab-case-without-polish-diacritics-max-50-chars-no-reserved-words",
  "title": "Polish title, attention-grabbing, max 70 chars, no brand names",
  "description": "SEO meta description in Polish, max 155 chars, concrete value, NO brand names"
}`,
    },
  ]
  const raw = await callOpenAI({ messages, jsonMode: true, maxTokens: 500 })
  const parsed = JSON.parse(raw)
  if (!parsed.slug || !parsed.title || !parsed.description) {
    throw new Error(`Topic JSON missing fields: ${raw}`)
  }
  if (existingSlugs.includes(parsed.slug)) {
    throw new Error(`Topic duplicates existing slug: ${parsed.slug}`)
  }
  if (RESERVED_SLUGS.has(parsed.slug)) {
    throw new Error(`Topic uses reserved slug: ${parsed.slug}`)
  }
  // Sanity check: no brand mentions in title/description
  const lowerCheck = `${parsed.title} ${parsed.description}`.toLowerCase()
  for (const phrase of FORBIDDEN_PHRASES) {
    if (lowerCheck.includes(phrase)) {
      throw new Error(`Topic contains forbidden phrase "${phrase}": ${parsed.title}`)
    }
  }
  return parsed
}

async function generateSvg({ slug, title, emoji }) {
  const messages = [
    {
      role: 'system',
      content:
        'You are an SVG illustrator. You return only raw SVG markup, no explanation, no markdown.',
    },
    {
      role: 'user',
      content: `Generate a clean, modern decorative SVG illustration (320x180 viewBox) for a Polish blog post about online casino topics.

Topic: "${title}"
Emoji theme: ${emoji}

Style requirements:
- viewBox="0 0 320 180", width="320" height="180"
- dark gradient background fitting the theme (no white background)
- a centered circular badge / focal element
- subtle decorative accents (stars, dots, lines) in corners
- a thin bottom strip / label area
- use semi-transparent whites and one accent color (gold #d4a843 or green #4ade80)
- no text, no emoji, no raster images, no external fonts
- clean, minimal, suitable as a thumbnail
- self-contained, valid SVG

Return ONLY the SVG markup starting with <svg ...> and ending with </svg>.`,
    },
  ]
  const raw = await callOpenAI({ messages, jsonMode: false, maxTokens: 2000 })
  let svg = raw.trim()
  svg = svg.replace(/^```(?:svg|xml)?\s*/i, '').replace(/```\s*$/i, '').trim()
  if (!svg.startsWith('<svg')) {
    throw new Error(`SVG response did not start with <svg: ${svg.slice(0, 200)}`)
  }
  const outPath = path.join(ILLUSTRATIONS_DIR, `${slug}.svg`)
  fs.writeFileSync(outPath, svg, 'utf-8')
  return `/illustrations/${slug}.svg`
}

async function generateOutline({ title, description, category }) {
  const messages = [
    {
      role: 'system',
      content:
        'You are a senior content editor writing in Polish for an online casino guide. You always respond with strict JSON.',
    },
    {
      role: 'user',
      content: `Plan a 1500+ word SEO blog post in Polish about online casino topics in the category "${category.label}".

Title: "${title}"
Description: "${description}"

Return strict JSON:
{
  "intro_points": ["3 concrete points to cover in the intro, in Polish"],
  "sections": [
    { "title": "## 1. Section title in Polish", "key_points": ["point1", "point2", "point3", "point4"] },
    ... exactly 8 sections numbered 1 to 8
  ]
}

Make sections specific, practical, non-overlapping. Use Polish.

CRITICAL: do NOT include sections that promote a specific casino brand. The article is general/educational.`,
    },
  ]
  const raw = await callOpenAI({ messages, jsonMode: true, maxTokens: 2000 })
  const parsed = JSON.parse(raw)
  if (!Array.isArray(parsed.sections) || parsed.sections.length !== 8) {
    throw new Error(`Outline must have 8 sections, got ${parsed.sections?.length}`)
  }
  return parsed
}

async function generateBody({ title, description, outline, category }) {
  const messages = [
    {
      role: 'system',
      content:
        'You write long-form SEO articles in fluent, natural Polish for an online casino guide site. No fluff, no filler. Concrete, practical, useful.',
    },
    {
      role: 'user',
      content: `Write the full article body in Polish based on this outline. Category: "${category.label}".

Title: "${title}"
Description: "${description}"

Intro must cover:
${outline.intro_points.map(p => `- ${p}`).join('\n')}

Sections (write each section as ## heading + 180+ words of dense, useful Polish prose, with **bold** key terms):
${outline.sections.map(s => `${s.title}\n  Key points: ${s.key_points.join('; ')}`).join('\n\n')}

After the 8 sections, add a short closing section "## Podsumowanie" (1-2 paragraphs) summarizing key takeaways.

End with EXACTLY this italic disclaimer line on its own line:
*Pamiętaj: hazard wiąże się z ryzykiem. Graj odpowiedzialnie i tylko w legalnych kasynach.*

ABSOLUTE constraints:
- Do NOT mention "Vulkan Vegas", "Vulkan Kasyno", "vulkankasyno.pl" or any specific casino brand name. Software providers (NetEnt, Pragmatic Play, Microgaming, Evolution, Play'n GO) are OK.
- Do NOT include any markdown links to external URLs (no [text](https://...)).
- Total length: at least 1500 words.
- Use markdown headings (##), bold (**term**), and occasional bullet lists.
- No H1, no frontmatter, no images, no code blocks.
- Start with the article title as a H2 heading: "## ${title}", then 3 intro paragraphs.
- Polish only.

Return only the markdown body.`,
    },
  ]
  const body = await callOpenAI({ messages, jsonMode: false, maxTokens: 6000 })
  return body.trim()
}

function assertNoForbiddenPhrases(text, where) {
  const lower = text.toLowerCase()
  for (const phrase of FORBIDDEN_PHRASES) {
    if (lower.includes(phrase)) {
      throw new Error(`Generated ${where} contains forbidden phrase "${phrase}"`)
    }
  }
  // Also reject any vulkankasyno.pl URLs even if escaped
  if (/vulkan[\s.-]?kasyno|vulkan[\s.-]?vegas/i.test(text)) {
    throw new Error(`Generated ${where} contains a Vulkan brand reference`)
  }
}

function buildMdx({ title, slug, description, emoji, category, image, body }) {
  const today = new Date().toISOString().slice(0, 10)
  const fm = [
    '---',
    `title: "${title.replace(/"/g, '\\"')}"`,
    `slug: "${slug}"`,
    `date: "${today}"`,
    `description: "${description.replace(/"/g, '\\"')}"`,
    `emoji: "${emoji}"`,
    `featured: false`,
    `moneyArticle: false`,
    `category: "${category}"`,
    `image: "${image}"`,
    '---',
    '',
    body,
    '',
  ].join('\n')
  return fm
}

async function main() {
  console.log('→ Reading existing posts')
  const { slugs, titles } = readExistingPosts()
  console.log(`  ${slugs.length} existing posts`)

  const category = pickLeastPopulatedCategory(slugs)
  console.log(`→ Category: ${category.icon} ${category.label} (${category.slug})`)

  console.log('→ Picking topic')
  const topic = await pickTopic({ existingSlugs: slugs, existingTitles: titles, category })
  console.log(`  topic: ${topic.slug} | ${category.icon} | ${topic.title}`)

  console.log('→ Generating SVG illustration')
  const image = await generateSvg({ slug: topic.slug, title: topic.title, emoji: category.icon })
  console.log(`  saved ${image}`)

  console.log('→ Generating outline')
  const outline = await generateOutline({ title: topic.title, description: topic.description, category })

  console.log('→ Generating body')
  const body = await generateBody({
    title: topic.title,
    description: topic.description,
    outline,
    category,
  })
  const wordCount = body.split(/\s+/).filter(Boolean).length
  console.log(`  ${wordCount} words`)

  // Hard guard: refuse to publish if generated content sneaks in a brand name.
  assertNoForbiddenPhrases(topic.title, 'title')
  assertNoForbiddenPhrases(topic.description, 'description')
  assertNoForbiddenPhrases(body, 'body')

  const mdx = buildMdx({
    title: topic.title,
    slug: topic.slug,
    description: topic.description,
    emoji: category.icon,
    category: category.slug,
    image,
    body,
  })
  const outFile = path.join(POSTS_DIR, `${topic.slug}.mdx`)
  fs.writeFileSync(outFile, mdx, 'utf-8')
  console.log(`✓ Wrote ${outFile}`)
}

main().catch(err => {
  console.error('FAILED:', err)
  process.exit(1)
})
