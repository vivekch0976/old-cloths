-- Query-oriented indexes for normalized sell-flow schema.

CREATE INDEX IF NOT EXISTS idx_items_user_status
    ON :"schema_name".items (user_id, status);

CREATE INDEX IF NOT EXISTS idx_items_category_status
    ON :"schema_name".items (category_id, status);

CREATE INDEX IF NOT EXISTS idx_items_audience_status
    ON :"schema_name".items (audience, status);

CREATE INDEX IF NOT EXISTS idx_items_listed_at
    ON :"schema_name".items (listed_at DESC);

CREATE INDEX IF NOT EXISTS idx_items_updated_at
    ON :"schema_name".items (updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_item_pricing_list_price
    ON :"schema_name".item_pricing (list_price);

CREATE INDEX IF NOT EXISTS idx_item_pricing_share_to_homepage
    ON :"schema_name".item_pricing (share_to_homepage)
    WHERE share_to_homepage = TRUE;

CREATE INDEX IF NOT EXISTS idx_item_shipping_location
    ON :"schema_name".item_shipping (location);

CREATE INDEX IF NOT EXISTS idx_item_media_item_sort
    ON :"schema_name".item_media (item_id, sort_order);

CREATE INDEX IF NOT EXISTS idx_item_engagement_featured
    ON :"schema_name".item_engagement (featured)
    WHERE featured = TRUE;

CREATE INDEX IF NOT EXISTS idx_users_email_lower
    ON :"schema_name".users (lower(email));

CREATE INDEX IF NOT EXISTS idx_categories_slug
    ON :"schema_name".categories (slug);
