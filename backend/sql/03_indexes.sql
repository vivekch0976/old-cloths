-- Query-oriented indexes for the normalized sell-flow schema.
-- Run this after 02_tables.sql.

-- Items by owner and status (user closet, seller dashboard).
CREATE INDEX IF NOT EXISTS idx_items_user_status
    ON :"schema_name".items (user_id, status);

-- Items by category and status (category browsing).
CREATE INDEX IF NOT EXISTS idx_items_category_status
    ON :"schema_name".items (category_id, status);

-- Items by audience and status (women/men collection pages).
CREATE INDEX IF NOT EXISTS idx_items_audience_status
    ON :"schema_name".items (audience, status);

-- Items ordered by listing date (newest arrivals).
CREATE INDEX IF NOT EXISTS idx_items_listed_at
    ON :"schema_name".items (listed_at DESC);

-- Items ordered by last update (recently updated).
CREATE INDEX IF NOT EXISTS idx_items_updated_at
    ON :"schema_name".items (updated_at DESC);

-- Items by price (price-range filtering).
CREATE INDEX IF NOT EXISTS idx_item_pricing_list_price
    ON :"schema_name".item_pricing (list_price);

-- Items shared to homepage only (homepage featured items).
CREATE INDEX IF NOT EXISTS idx_item_pricing_share_to_homepage
    ON :"schema_name".item_pricing (share_to_homepage)
    WHERE share_to_homepage = TRUE;

-- Shipping queries filtered by seller location.
CREATE INDEX IF NOT EXISTS idx_item_shipping_location
    ON :"schema_name".item_shipping (location);

-- Media asset lookup and sort order per item.
CREATE INDEX IF NOT EXISTS idx_item_media_item_sort
    ON :"schema_name".item_media (item_id, sort_order);

-- Featured items only (home page spotlight).
CREATE INDEX IF NOT EXISTS idx_item_engagement_featured
    ON :"schema_name".item_engagement (featured)
    WHERE featured = TRUE;

-- Case-insensitive email lookup for auth (login/register).
CREATE INDEX IF NOT EXISTS idx_users_email_lower
    ON :"schema_name".users (lower(email));

-- Category lookup by slug (URL routing).
CREATE INDEX IF NOT EXISTS idx_categories_slug
    ON :"schema_name".categories (slug);
