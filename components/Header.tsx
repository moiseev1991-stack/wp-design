'use client'

import Link from 'next/link'
import { useState } from 'react'
import { categories } from '@/lib/categories'

const navLinks = [
  { label: 'Główna', href: '/' },
  { label: 'O nas', href: '/o-nas/' },
  { label: 'Kontakt', href: '/kontakt/' },
]

export default function Header() {
  const [menuOpen, setMenuOpen] = useState(false)
  const [catOpen, setCatOpen] = useState(false)
  const [mobileCatOpen, setMobileCatOpen] = useState(false)

  return (
    <header className="site-header sticky top-0 z-50 bg-white/95 backdrop-blur-md border-b border-[var(--border)] shadow-sm">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 h-16 flex items-center justify-between">
        <Link href="/" className="text-2xl font-black font-heading tracking-tight text-[var(--accent)]">
          WP<span className="text-[var(--accent-light)]">Design</span>
        </Link>

        <nav className="hidden md:flex items-center gap-1 nav-menu">
          <Link
            href="/"
            className="text-sm font-medium px-4 py-2 rounded-lg transition-all text-[var(--text-muted)] hover:text-[var(--accent)] hover:bg-[var(--bg-section)]"
          >
            Główna
          </Link>

          <div
            className="relative"
            onMouseEnter={() => setCatOpen(true)}
            onMouseLeave={() => setCatOpen(false)}
          >
            <button
              type="button"
              className="text-sm font-medium px-4 py-2 rounded-lg transition-all text-[var(--text-muted)] hover:text-[var(--accent)] hover:bg-[var(--bg-section)] flex items-center gap-1"
              onClick={() => setCatOpen(v => !v)}
              aria-expanded={catOpen}
              aria-haspopup="true"
            >
              📂 Kategorie <span className={`text-xs transition-transform ${catOpen ? 'rotate-180' : ''}`}>▾</span>
            </button>
            {catOpen && (
              <div className="absolute top-full right-0 mt-1 w-72 bg-white rounded-xl shadow-xl border border-[var(--border)] py-2 z-50">
                {categories.map(cat => (
                  <Link
                    key={cat.slug}
                    href={`/kategoria/${cat.slug}/`}
                    className="flex items-center gap-3 px-4 py-2.5 text-sm text-[var(--text-muted)] hover:text-[var(--accent)] hover:bg-[var(--bg-section)] transition-colors"
                  >
                    <span className="text-lg">{cat.icon}</span>
                    <span className="font-medium">{cat.label}</span>
                  </Link>
                ))}
                <div className="border-t border-[var(--border)] mt-2 pt-2">
                  <Link
                    href="/kategoria/"
                    className="flex items-center justify-end gap-1 px-4 py-2 text-xs text-[var(--accent)] font-semibold hover:gap-2 transition-all"
                  >
                    Wszystkie kategorie →
                  </Link>
                </div>
              </div>
            )}
          </div>

          {navLinks.slice(1).map(link => (
            <Link
              key={link.href}
              href={link.href}
              className="text-sm font-medium px-4 py-2 rounded-lg transition-all text-[var(--text-muted)] hover:text-[var(--accent)] hover:bg-[var(--bg-section)]"
            >
              {link.label}
            </Link>
          ))}
        </nav>

        <button
          className="md:hidden p-2 rounded-lg transition-colors text-[var(--text)]"
          onClick={() => setMenuOpen(v => !v)}
          aria-label="Menu"
        >
          <div className="w-5 space-y-1.5">
            <span className={`block h-0.5 bg-current transition-all ${menuOpen ? 'rotate-45 translate-y-2' : ''}`} />
            <span className={`block h-0.5 bg-current transition-all ${menuOpen ? 'opacity-0' : ''}`} />
            <span className={`block h-0.5 bg-current transition-all ${menuOpen ? '-rotate-45 -translate-y-2' : ''}`} />
          </div>
        </button>
      </div>

      {menuOpen && (
        <div className="md:hidden bg-white border-t border-[var(--border)] px-4 py-4 flex flex-col gap-1 nav-menu shadow-lg">
          <Link
            href="/"
            className="text-sm font-medium text-[var(--text-muted)] hover:text-[var(--accent)] hover:bg-[var(--bg-section)] px-4 py-2.5 rounded-lg transition-colors"
            onClick={() => setMenuOpen(false)}
          >
            Główna
          </Link>

          <button
            type="button"
            className="text-sm font-medium text-[var(--text-muted)] hover:text-[var(--accent)] hover:bg-[var(--bg-section)] px-4 py-2.5 rounded-lg transition-colors flex items-center justify-between"
            onClick={() => setMobileCatOpen(v => !v)}
          >
            <span>📂 Kategorie</span>
            <span className={`text-xs transition-transform ${mobileCatOpen ? 'rotate-180' : ''}`}>▾</span>
          </button>

          {mobileCatOpen && (
            <div className="ml-4 flex flex-col gap-0.5 border-l-2 border-[var(--border)] pl-3">
              {categories.map(cat => (
                <Link
                  key={cat.slug}
                  href={`/kategoria/${cat.slug}/`}
                  className="flex items-center gap-2 text-sm text-[var(--text-muted)] hover:text-[var(--accent)] px-3 py-2 rounded-lg transition-colors"
                  onClick={() => setMenuOpen(false)}
                >
                  <span>{cat.icon}</span>
                  <span>{cat.label}</span>
                </Link>
              ))}
              <Link
                href="/kategoria/"
                className="text-xs text-[var(--accent)] font-semibold px-3 py-2"
                onClick={() => setMenuOpen(false)}
              >
                Wszystkie kategorie →
              </Link>
            </div>
          )}

          {navLinks.slice(1).map(link => (
            <Link
              key={link.href}
              href={link.href}
              className="text-sm font-medium text-[var(--text-muted)] hover:text-[var(--accent)] hover:bg-[var(--bg-section)] px-4 py-2.5 rounded-lg transition-colors"
              onClick={() => setMenuOpen(false)}
            >
              {link.label}
            </Link>
          ))}
        </div>
      )}
    </header>
  )
}
