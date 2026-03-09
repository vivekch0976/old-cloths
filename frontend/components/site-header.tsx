import Link from 'next/link';

const links = [
  { href: '/', label: 'Home' },
  { href: '/listings', label: 'Browse' },
  { href: '/sell', label: 'Sell' }
];

export function SiteHeader() {
  return (
    <header className="border-b border-slate-200 bg-white/90 backdrop-blur">
      <nav className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        <Link href="/" className="text-xl font-bold text-brand-700">
          OldCloths
        </Link>
        <ul className="flex items-center gap-6 text-sm font-medium">
          {links.map((link) => (
            <li key={link.href}>
              <Link href={link.href} className="text-slate-700 hover:text-brand-700">
                {link.label}
              </Link>
            </li>
          ))}
        </ul>
      </nav>
    </header>
  );
}
