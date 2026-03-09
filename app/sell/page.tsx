'use client';

import { useMemo, useState } from 'react';
import { SiteHeader } from '@/components/site-header';
import { listingCategories, listingConditions, listingSizes } from '@/lib/listings';
import { hasSupabaseConfig } from '@/lib/supabase';

export default function SellPage() {
  const [price, setPrice] = useState('');
  const numericPrice = useMemo(() => Number(price), [price]);
  const priceIsValid = numericPrice > 0 && Number.isFinite(numericPrice);

  return (
    <>
      <SiteHeader />
      <main className="mx-auto max-w-2xl px-6 py-10">
        <h1 className="mb-2 text-3xl font-bold">Sell an item</h1>
        <p className="mb-8 text-slate-600">Seller form with basic validation. Connect this to storage + DB inserts next.</p>

        <form className="space-y-4 rounded-2xl bg-white p-6 shadow-sm">
          <label className="block text-sm font-medium">
            Title
            <input
              required
              minLength={5}
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
              placeholder="Vintage oversized shirt"
            />
          </label>
          <label className="block text-sm font-medium">
            Price (USD)
            <input
              required
              type="number"
              min={1}
              value={price}
              onChange={(event) => setPrice(event.target.value)}
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
              placeholder="25"
            />
          </label>
          <label className="block text-sm font-medium">
            Size
            <select className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2">
              {listingSizes.map((size) => (
                <option key={size}>{size}</option>
              ))}
            </select>
          </label>
          <label className="block text-sm font-medium">
            Category
            <select className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2">
              {listingCategories.map((category) => (
                <option key={category}>{category}</option>
              ))}
            </select>
          </label>
          <label className="block text-sm font-medium">
            Condition
            <select className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2">
              {listingConditions.map((condition) => (
                <option key={condition}>{condition}</option>
              ))}
            </select>
          </label>
          <button
            type="submit"
            disabled={!priceIsValid}
            className="rounded-lg bg-brand-700 px-5 py-2 text-sm font-semibold text-white enabled:hover:bg-brand-500 disabled:cursor-not-allowed disabled:bg-slate-300"
          >
            Publish listing
          </button>
          {!hasSupabaseConfig && (
            <p className="text-sm text-amber-700">
              Add Supabase keys in <code>.env.local</code> to enable real listing creation.
            </p>
          )}
        </form>
      </main>
    </>
  );
}
