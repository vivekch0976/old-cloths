-- Normalized tables based on sell-form components.
-- Objects are created only in :"schema_name".

CREATE TABLE IF NOT EXISTS :"schema_name".users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    country TEXT NOT NULL,
    phone_code VARCHAR(5) NOT NULL CHECK (phone_code ~ '^\+[0-9]{1,4}$'),
    phone_number VARCHAR(32) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS :"schema_name".categories (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    slug TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Core listing identity and ownership.
CREATE TABLE IF NOT EXISTS :"schema_name".items (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES :"schema_name".users (id) ON DELETE RESTRICT,
    category_id BIGINT NOT NULL REFERENCES :"schema_name".categories (id) ON DELETE RESTRICT,
    slug TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL CHECK (char_length(title) BETWEEN 3 AND 120),
    audience TEXT NOT NULL CHECK (audience IN ('women', 'men', 'unisex', 'kids')),
    brand TEXT NOT NULL,
    size TEXT NOT NULL,
    color TEXT NOT NULL,
    material TEXT NOT NULL,
    condition_label TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'live' CHECK (status IN ('live', 'draft', 'sold', 'archived')),
    listed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    sold_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Content and item presentation details.
CREATE TABLE IF NOT EXISTS :"schema_name".item_descriptions (
    item_id BIGINT PRIMARY KEY REFERENCES :"schema_name".items (id) ON DELETE CASCADE,
    tag TEXT NOT NULL,
    short_description TEXT NOT NULL,
    long_description TEXT,
    wear TEXT,
    measurements TEXT,
    flaws TEXT,
    photo_class TEXT NOT NULL DEFAULT 'photo-navy',
    updated_label TEXT NOT NULL DEFAULT 'Just listed',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Pricing and seller preferences from sell form.
CREATE TABLE IF NOT EXISTS :"schema_name".item_pricing (
    item_id BIGINT PRIMARY KEY REFERENCES :"schema_name".items (id) ON DELETE CASCADE,
    list_price INTEGER NOT NULL CHECK (list_price > 0),
    original_price INTEGER CHECK (original_price > 0),
    currency_code CHAR(3) NOT NULL DEFAULT 'USD',
    payout_method TEXT NOT NULL,
    accept_offers BOOLEAN NOT NULL DEFAULT FALSE,
    allow_bundle_discounts BOOLEAN NOT NULL DEFAULT FALSE,
    boost_listing BOOLEAN NOT NULL DEFAULT FALSE,
    share_to_homepage BOOLEAN NOT NULL DEFAULT FALSE,
    platform_fee_percent NUMERIC(5,2) NOT NULL DEFAULT 10.00 CHECK (platform_fee_percent >= 0 AND platform_fee_percent <= 100),
    earning_estimate INTEGER NOT NULL DEFAULT 0 CHECK (earning_estimate >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_original_vs_list_price
        CHECK (original_price IS NULL OR original_price >= list_price)
);

-- Shipping and return policy fields.
CREATE TABLE IF NOT EXISTS :"schema_name".item_shipping (
    item_id BIGINT PRIMARY KEY REFERENCES :"schema_name".items (id) ON DELETE CASCADE,
    location TEXT NOT NULL,
    shipping_time TEXT NOT NULL,
    shipping_cost TEXT NOT NULL,
    returns_policy TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Photos/media uploaded for each item.
CREATE TABLE IF NOT EXISTS :"schema_name".item_media (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    item_id BIGINT NOT NULL REFERENCES :"schema_name".items (id) ON DELETE CASCADE,
    media_type TEXT NOT NULL DEFAULT 'image' CHECK (media_type IN ('image', 'video')),
    storage_provider TEXT,
    storage_key TEXT,
    public_url TEXT,
    mime_type TEXT,
    file_size_bytes BIGINT CHECK (file_size_bytes >= 0),
    width_px INTEGER CHECK (width_px >= 0),
    height_px INTEGER CHECK (height_px >= 0),
    duration_seconds INTEGER CHECK (duration_seconds >= 0),
    sort_order INTEGER NOT NULL DEFAULT 1 CHECK (sort_order > 0),
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_item_media_order UNIQUE (item_id, sort_order),
    CONSTRAINT chk_media_source_present CHECK (
        COALESCE(NULLIF(storage_key, ''), NULLIF(public_url, '')) IS NOT NULL
    )
);

-- Marketplace metrics kept separately from core item fields.
CREATE TABLE IF NOT EXISTS :"schema_name".item_engagement (
    item_id BIGINT PRIMARY KEY REFERENCES :"schema_name".items (id) ON DELETE CASCADE,
    featured BOOLEAN NOT NULL DEFAULT FALSE,
    saved_count INTEGER NOT NULL DEFAULT 0 CHECK (saved_count >= 0),
    watchers INTEGER NOT NULL DEFAULT 0 CHECK (watchers >= 0),
    price_drops INTEGER NOT NULL DEFAULT 0 CHECK (price_drops >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_item_media_primary_one_per_item
    ON :"schema_name".item_media (item_id)
    WHERE is_primary = TRUE;

CREATE OR REPLACE FUNCTION :"schema_name".set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_users_set_updated_at ON :"schema_name".users;
CREATE TRIGGER trg_users_set_updated_at
BEFORE UPDATE ON :"schema_name".users
FOR EACH ROW
EXECUTE FUNCTION :"schema_name".set_updated_at();

DROP TRIGGER IF EXISTS trg_categories_set_updated_at ON :"schema_name".categories;
CREATE TRIGGER trg_categories_set_updated_at
BEFORE UPDATE ON :"schema_name".categories
FOR EACH ROW
EXECUTE FUNCTION :"schema_name".set_updated_at();

DROP TRIGGER IF EXISTS trg_items_set_updated_at ON :"schema_name".items;
CREATE TRIGGER trg_items_set_updated_at
BEFORE UPDATE ON :"schema_name".items
FOR EACH ROW
EXECUTE FUNCTION :"schema_name".set_updated_at();

DROP TRIGGER IF EXISTS trg_item_descriptions_set_updated_at ON :"schema_name".item_descriptions;
CREATE TRIGGER trg_item_descriptions_set_updated_at
BEFORE UPDATE ON :"schema_name".item_descriptions
FOR EACH ROW
EXECUTE FUNCTION :"schema_name".set_updated_at();

DROP TRIGGER IF EXISTS trg_item_pricing_set_updated_at ON :"schema_name".item_pricing;
CREATE TRIGGER trg_item_pricing_set_updated_at
BEFORE UPDATE ON :"schema_name".item_pricing
FOR EACH ROW
EXECUTE FUNCTION :"schema_name".set_updated_at();

DROP TRIGGER IF EXISTS trg_item_shipping_set_updated_at ON :"schema_name".item_shipping;
CREATE TRIGGER trg_item_shipping_set_updated_at
BEFORE UPDATE ON :"schema_name".item_shipping
FOR EACH ROW
EXECUTE FUNCTION :"schema_name".set_updated_at();

DROP TRIGGER IF EXISTS trg_item_media_set_updated_at ON :"schema_name".item_media;
CREATE TRIGGER trg_item_media_set_updated_at
BEFORE UPDATE ON :"schema_name".item_media
FOR EACH ROW
EXECUTE FUNCTION :"schema_name".set_updated_at();

DROP TRIGGER IF EXISTS trg_item_engagement_set_updated_at ON :"schema_name".item_engagement;
CREATE TRIGGER trg_item_engagement_set_updated_at
BEFORE UPDATE ON :"schema_name".item_engagement
FOR EACH ROW
EXECUTE FUNCTION :"schema_name".set_updated_at();
