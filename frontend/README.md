# OldCloths

A practical starter marketplace for buying and selling pre-loved clothes, built with **Next.js + Tailwind** and a **Supabase-ready environment setup**.

## What is included

- SEO-friendly Next.js App Router pages.
- Reusable marketplace UI components.
- Listings feed with query-based search and filters.
- Seller form with basic client validation.
- Environment variables prepared for Supabase wiring.

## Quick start

```bash
npm install
cp .env.example .env.local
npm run dev
```

Open `http://localhost:3000`.

## Environment variables

Set these in `.env.local` when ready:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`

## Routes

- `/` landing page + featured listings
- `/listings` searchable/filterable marketplace feed
- `/sell` listing form with validation

## Suggested next steps

1. Add Supabase auth (buyer/seller roles).
2. Add image upload to Supabase Storage.
3. Persist listings in Postgres and replace demo data.
4. Add order flow and checkout integration.
