export type ListingCondition = 'Like New' | 'Good' | 'Fair';
export type ListingCategory = 'Outerwear' | 'Dresses' | 'Tops' | 'Bottoms';

export type Listing = {
  id: string;
  title: string;
  price: number;
  size: 'XS' | 'S' | 'M' | 'L' | 'XL';
  condition: ListingCondition;
  category: ListingCategory;
  image: string;
  seller: string;
};

export const demoListings: Listing[] = [
  {
    id: '1',
    title: 'Vintage Denim Jacket',
    price: 32,
    size: 'M',
    condition: 'Good',
    category: 'Outerwear',
    image:
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=800&q=80',
    seller: 'Maya'
  },
  {
    id: '2',
    title: 'Floral Summer Dress',
    price: 24,
    size: 'S',
    condition: 'Like New',
    category: 'Dresses',
    image:
      'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=800&q=80',
    seller: 'Priya'
  },
  {
    id: '3',
    title: 'Classic Black Hoodie',
    price: 18,
    size: 'L',
    condition: 'Fair',
    category: 'Tops',
    image:
      'https://images.unsplash.com/photo-1617952236317-74f0f6f0c6e4?auto=format&fit=crop&w=800&q=80',
    seller: 'Noah'
  },
  {
    id: '4',
    title: 'Relaxed Linen Trousers',
    price: 20,
    size: 'M',
    condition: 'Good',
    category: 'Bottoms',
    image:
      'https://images.unsplash.com/photo-1473966968600-fa801b869a1a?auto=format&fit=crop&w=800&q=80',
    seller: 'Aanya'
  }
];

export const listingSizes: Listing['size'][] = ['XS', 'S', 'M', 'L', 'XL'];
export const listingConditions: ListingCondition[] = ['Like New', 'Good', 'Fair'];
export const listingCategories: ListingCategory[] = ['Outerwear', 'Dresses', 'Tops', 'Bottoms'];
