import Link from 'next/link';
import { ListingCard } from '@/components/listing-card';
import { SiteHeader } from '@/components/site-header';
import { demoListings } from '@/lib/listings';

export default function HomePage() {
  return (
    <>
      <SiteHeader />
      <main className="mx-auto max-w-6xl space-y-16 px-6 py-10">
        <section className="rounded-2xl bg-white p-8 shadow-sm">
          <p className="mb-2 text-sm font-semibold uppercase tracking-wide text-brand-700">Sustainable fashion marketplace</p>
          <h1 className="mb-4 text-4xl font-bold tracking-tight text-slate-900">Buy and sell pre-loved clothes in minutes.</h1>
          <p className="mb-6 max-w-2xl text-slate-600">
            OldCloths helps people give clothing a second life with trusted sellers, clear condition labels, and affordable prices.
          </p>
          <div className="flex gap-3">
            <Link href="/listings" className="rounded-lg bg-brand-700 px-5 py-3 text-sm font-semibold text-white hover:bg-brand-500">
              Start browsing
            </Link>
            <Link href="/sell" className="rounded-lg border border-slate-300 px-5 py-3 text-sm font-semibold hover:border-brand-700 hover:text-brand-700">
              List an item
            </Link>
          </div>
        </section>

        <section>
          <div className="mb-6 flex items-end justify-between">
            <h2 className="text-2xl font-bold">Featured listings</h2>
            <Link href="/listings" className="text-sm font-semibold text-brand-700 hover:text-brand-500">
              View all →
            </Link>
          </div>
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {demoListings.map((listing) => (
              <ListingCard key={listing.id} listing={listing} />
            ))}
          </div>
        </section>
      </main>
    </>
  );
}
