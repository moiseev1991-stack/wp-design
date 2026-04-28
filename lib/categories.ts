export interface Category {
  slug: string
  label: string
  icon: string
  description: string
}

export const categories: Category[] = [
  { slug: 'recenzje',    label: 'Recenzje kasyn', icon: '🎰', description: 'Pełne recenzje sprawdzonych kasyn online dla polskich graczy – licencje, oferta gier, bonusy i opinie.' },
  { slug: 'bonusy',      label: 'Bonusy',         icon: '🎁', description: 'Bonusy powitalne, reload, cashback i darmowe spiny – jak je odbierać i jak korzystać.' },
  { slug: 'sloty',       label: 'Sloty',          icon: '🎡', description: 'Sloty online – mechaniki, RTP, zmienność i przewodniki po najpopularniejszych tytułach.' },
  { slug: 'jackpoty',    label: 'Jackpoty',       icon: '💰', description: 'Jackpoty progresywne i stałe – jak działają, gdzie szukać i jak zwiększyć szansę na wygraną.' },
  { slug: 'gry-stolowe', label: 'Gry stołowe',    icon: '🃏', description: 'Ruletka, blackjack, baccarat, poker – zasady, strategie i live casino dla polskich graczy.' },
  { slug: 'platnosci',   label: 'Płatności',      icon: '💳', description: 'BLIK, Przelewy24, e-portfele i kryptowaluty – metody płatności w polskich kasynach online.' },
  { slug: 'mobilne',     label: 'Mobilne kasyna', icon: '📱', description: 'Granie w kasyno online z telefonu – aplikacje, strony PWA, bezpieczeństwo i bonusy mobilne.' },
  { slug: 'poradniki',   label: 'Poradniki',      icon: '💡', description: 'Praktyczne poradniki dla graczy – rejestracja, KYC, weryfikacja, odpowiedzialna gra.' },
]

export const categoriesBySlug: Record<string, Category> = Object.fromEntries(
  categories.map((c) => [c.slug, c]),
)

export const DEFAULT_CATEGORY = 'poradniki'
