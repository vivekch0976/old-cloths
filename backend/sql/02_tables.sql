-- Core normalized tables for the old-clothes application.
-- No INSERT statements are included in this SQL set.

CREATE TABLE IF NOT EXISTS app.users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    country TEXT NOT NULL,
    phone_code VARCHAR(5) NOT NULL,
    phone_number VARCHAR(32) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app.categories (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    slug TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app.items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES app.users (id) ON DELETE CASCADE,
    category_id BIGINT NOT NULL REFERENCES app.categories (id) ON DELETE RESTRICT,
    slug TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    audience TEXT NOT NULL CHECK (audience IN ('women', 'men', 'unisex', 'kids')),
    tag TEXT NOT NULL,
    brand TEXT NOT NULL,
    size TEXT NOT NULL,
    color TEXT NOT NULL,
    material TEXT NOT NULL,
    condition TEXT NOT NULL,
    wear TEXT,
    measurements TEXT,
    flaws TEXT,
    description TEXT NOT NULL,
    long_description TEXT,
    price INTEGER NOT NULL CHECK (price >= 0),
    original_price INTEGER CHECK (original_price >= 0),
    shipping_time TEXT NOT NULL,
    shipping_cost TEXT NOT NULL,
    returns_policy TEXT NOT NULL,
    payment TEXT NOT NULL,
    location TEXT NOT NULL,
    photo_class TEXT NOT NULL DEFAULT 'photo-navy',
    status TEXT NOT NULL CHECK (status IN ('live', 'draft', 'sold')),
    featured BOOLEAN NOT NULL DEFAULT FALSE,
    saved_count INTEGER NOT NULL DEFAULT 0 CHECK (saved_count >= 0),
    watchers INTEGER NOT NULL DEFAULT 0 CHECK (watchers >= 0),
    price_drops INTEGER NOT NULL DEFAULT 0 CHECK (price_drops >= 0),
    earning INTEGER NOT NULL DEFAULT 0 CHECK (earning >= 0),
    updated_label TEXT NOT NULL DEFAULT 'Just listed',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION app.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_items_set_updated_at ON app.items;
CREATE TRIGGER trg_items_set_updated_at
BEFORE UPDATE ON app.items
FOR EACH ROW
EXECUTE FUNCTION app.set_updated_at();

DROP TRIGGER IF EXISTS trg_users_set_updated_at ON app.users;
CREATE TRIGGER trg_users_set_updated_at
BEFORE UPDATE ON app.users
FOR EACH ROW
EXECUTE FUNCTION app.set_updated_at();

DROP TRIGGER IF EXISTS trg_categories_set_updated_at ON app.categories;
CREATE TRIGGER trg_categories_set_updated_at
BEFORE UPDATE ON app.categories
FOR EACH ROW
EXECUTE FUNCTION app.set_updated_at();
