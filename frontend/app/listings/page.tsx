import Link from 'next/link';
import { ListingCard } from '@/components/listing-card';
import { SiteHeader } from '@/components/site-header';
import {
  demoListings,
  listingCategories,
  listingConditions,
  listingSizes,
  type Listing
} from '@/lib/listings';

type SearchParams = {
  q?: string;
  size?: Listing['size'];
  condition?: Listing['condition'];
  category?: Listing['category'];
};

function applyFilters(items: Listing[], params: SearchParams): Listing[] {
  return items.filter((item) => {
    const matchesQuery = params.q
      ? item.title.toLowerCase().includes(params.q.toLowerCase())
      : true;
    const matchesSize = params.size ? item.size === params.size : true;
    const matchesCondition = params.condition ? item.condition === params.condition : true;
    const matchesCategory = params.category ? item.category === params.category : true;

    return matchesQuery && matchesSize && matchesCondition && matchesCategory;
  });
}

export default function ListingsPage({
  searchParams
}: {
  searchParams: SearchParams;
}) {
  const filtered = applyFilters(demoListings, searchParams);

  return (
    <>
      <SiteHeader />
      <main className="mx-auto max-w-6xl px-6 py-10">
        <div className="mb-8 flex items-end justify-between">
          <div>
            <h1 className="mb-2 text-3xl font-bold">Browse listings</h1>
            <p className="text-slate-600">Search and filter marketplace inventory for your MVP.</p>
          </div>
          <Link href="/listings" className="text-sm font-semibold text-brand-700 hover:text-brand-500">
            Clear filters
          </Link>
        </div>

        <form className="mb-8 grid gap-3 rounded-xl border border-slate-200 bg-white p-4 md:grid-cols-4">
          <input
            name="q"
            defaultValue={searchParams.q}
            placeholder="Search title"
            className="rounded-lg border border-slate-300 px-3 py-2 text-sm"
          />
          <select name="size" defaultValue={searchParams.size} className="rounded-lg border border-slate-300 px-3 py-2 text-sm">
            <option value="">Any size</option>
            {listingSizes.map((size) => (
              <option key={size} value={size}>
                {size}
              </option>
            ))}
          </select>
          <select
            name="condition"
            defaultValue={searchParams.condition}
            className="rounded-lg border border-slate-300 px-3 py-2 text-sm"
          >
            <option value="">Any condition</option>
            {listingConditions.map((condition) => (
              <option key={condition} value={condition}>
                {condition}
              </option>
            ))}
          </select>
          <select
            name="category"
            defaultValue={searchParams.category}
            className="rounded-lg border border-slate-300 px-3 py-2 text-sm"
          >
            <option value="">Any category</option>
            {listingCategories.map((category) => (
              <option key={category} value={category}>
                {category}
              </option>
            ))}
          </select>
          <button type="submit" className="rounded-lg bg-brand-700 px-4 py-2 text-sm font-semibold text-white md:col-span-4 md:w-fit">
            Apply filters
          </button>
        </form>

        {filtered.length > 0 ? (
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {filtered.map((listing) => (
              <ListingCard key={listing.id} listing={listing} />
            ))}
          </div>
        ) : (
          <div className="rounded-xl border border-dashed border-slate-300 bg-white p-8 text-center">
            <p className="text-slate-700">No listings match your filters yet.</p>
          </div>
        )}
      </main>
    </>
  );
}
