import Image from 'next/image';
import type { Listing } from '@/lib/listings';

export function ListingCard({ listing }: { listing: Listing }) {
  return (
    <article className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
      <div className="relative h-56 w-full">
        <Image src={listing.image} alt={listing.title} fill className="object-cover" />
      </div>
      <div className="space-y-2 p-4">
        <div className="flex items-center justify-between gap-3">
          <h3 className="text-lg font-semibold">{listing.title}</h3>
          <span className="rounded-full bg-brand-100 px-2 py-1 text-xs font-semibold text-brand-700">
            {listing.category}
          </span>
        </div>
        <p className="text-sm text-slate-500">Sold by {listing.seller}</p>
        <div className="flex items-center justify-between text-sm">
          <span className="rounded-full bg-slate-100 px-3 py-1">Size {listing.size}</span>
          <span className="rounded-full bg-slate-100 px-3 py-1">{listing.condition}</span>
        </div>
        <p className="text-xl font-bold text-brand-700">${listing.price}</p>
      </div>
    </article>
  );
}
