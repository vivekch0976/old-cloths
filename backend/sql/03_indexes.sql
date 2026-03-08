-- Query-oriented indexes for normalized tables.

CREATE INDEX IF NOT EXISTS idx_items_audience_status
    ON app.items (audience, status);

CREATE INDEX IF NOT EXISTS idx_items_status
    ON app.items (status);

CREATE INDEX IF NOT EXISTS idx_items_featured
    ON app.items (featured)
    WHERE featured = TRUE;

CREATE INDEX IF NOT EXISTS idx_items_price
    ON app.items (price);

CREATE INDEX IF NOT EXISTS idx_items_updated_at
    ON app.items (updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_items_user_status
    ON app.items (user_id, status);

CREATE INDEX IF NOT EXISTS idx_items_category_status
    ON app.items (category_id, status);

CREATE INDEX IF NOT EXISTS idx_users_email
    ON app.users (email);

CREATE INDEX IF NOT EXISTS idx_categories_slug
    ON app.categories (slug);
