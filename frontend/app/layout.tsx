import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'OldCloths',
  description: 'Buy and sell pre-loved clothing sustainably.'
};

export default function RootLayout({
  children
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="bg-brand-50 text-slate-900 antialiased">{children}</body>
    </html>
  );
}
