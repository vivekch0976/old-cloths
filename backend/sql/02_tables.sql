-- Normalized tables aligned with the current VintageLoop sell-flow and auth models.
-- All objects are created inside :"schema_name" only.
-- Mirrors the field definitions in backend/app/main.py (ListingCreate, RegisterCreate).

-- Shared trigger function to keep updated_at current on every row change.
CREATE OR REPLACE FUNCTION :"schema_name".set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- ─── users ────────────────────────────────────────────────────────────────────
-- Stores seller/account records created by the registration flow.
-- Maps to: RegisterCreate (full_name, email, password, country, phone_code, phone_number)

CREATE TABLE IF NOT EXISTS :"schema_name".users (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name     TEXT        NOT NULL CHECK (char_length(full_name) BETWEEN 2 AND 120),
    email         TEXT        NOT NULL UNIQUE CHECK (char_length(email) BETWEEN 5 AND 160),
    password_hash TEXT        NOT NULL,
    country       TEXT        NOT NULL CHECK (char_length(country) BETWEEN 2 AND 120),
    phone_code    VARCHAR(5)  NOT NULL CHECK (phone_code ~ '^\+[0-9]{1,4}$'),
    phone_number  VARCHAR(32) NOT NULL CHECK (char_length(phone_number) BETWEEN 4 AND 32),
    is_active     BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS trg_users_set_updated_at ON :"schema_name".users;
CREATE TRIGGER trg_users_set_updated_at
BEFORE UPDATE ON :"schema_name".users
FOR EACH ROW EXECUTE FUNCTION :"schema_name".set_updated_at();

-- ─── categories ───────────────────────────────────────────────────────────────
-- Master list of item categories (e.g. jacket, dress, bag).
-- Maps to: ListingCreate.category

CREATE TABLE IF NOT EXISTS :"schema_name".categories (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    slug        TEXT        NOT NULL UNIQUE,
    name        TEXT        NOT NULL UNIQUE,
    description TEXT,
    is_active   BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS trg_categories_set_updated_at ON :"schema_name".categories;
CREATE TRIGGER trg_categories_set_updated_at
BEFORE UPDATE ON :"schema_name".categories
FOR EACH ROW EXECUTE FUNCTION :"schema_name".set_updated_at();

-- ─── items ────────────────────────────────────────────────────────────────────
-- Core listing identity and ownership.
-- Maps to: ListingCreate (title, category, brand, size, audience, color, material, condition)

CREATE TABLE IF NOT EXISTS :"schema_name".items (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id         BIGINT      NOT NULL REFERENCES :"schema_name".users (id) ON DELETE RESTRICT,
    category_id     BIGINT      NOT NULL REFERENCES :"schema_name".categories (id) ON DELETE RESTRICT,
    slug            TEXT        NOT NULL UNIQUE,
    title           TEXT        NOT NULL CHECK (char_length(title) BETWEEN 3 AND 120),
    audience        TEXT        NOT NULL CHECK (audience IN ('women', 'men', 'unisex', 'kids')),
    brand           TEXT        NOT NULL CHECK (char_length(brand) BETWEEN 1 AND 80),
    size            TEXT        NOT NULL CHECK (char_length(size) BETWEEN 1 AND 20),
    color           TEXT        NOT NULL CHECK (char_length(color) BETWEEN 1 AND 60),
    material        TEXT        NOT NULL CHECK (char_length(material) BETWEEN 1 AND 60),
    condition_label TEXT        NOT NULL CHECK (char_length(condition_label) BETWEEN 2 AND 80),
    status          TEXT        NOT NULL DEFAULT 'live'
                        CHECK (status IN ('live', 'draft', 'sold', 'archived')),
    listed_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    sold_at         TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS trg_items_set_updated_at ON :"schema_name".items;
CREATE TRIGGER trg_items_set_updated_at
BEFORE UPDATE ON :"schema_name".items
FOR EACH ROW EXECUTE FUNCTION :"schema_name".set_updated_at();

-- ─── item_descriptions ────────────────────────────────────────────────────────
-- Description text, presentation metadata, and fit/condition details (1-to-1 with items).
-- Maps to: ListingCreate (description, wear, measurements, flaws)
--          Computed fields: tag, short_description, photo_class, updated_label

CREATE TABLE IF NOT EXISTS :"schema_name".item_descriptions (
    item_id           BIGINT      PRIMARY KEY
                          REFERENCES :"schema_name".items (id) ON DELETE CASCADE,
    tag               TEXT        NOT NULL,
    short_description TEXT        NOT NULL CHECK (char_length(short_description) <= 140),
    long_description  TEXT        CHECK (char_length(long_description) <= 1200),
    wear              TEXT        CHECK (char_length(wear) <= 120),
    measurements      TEXT        CHECK (char_length(measurements) <= 160),
    flaws             TEXT        CHECK (char_length(flaws) <= 160),
    photo_class       TEXT        NOT NULL DEFAULT 'photo-navy',
    updated_label     TEXT        NOT NULL DEFAULT 'Just listed',
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS trg_item_descriptions_set_updated_at ON :"schema_name".item_descriptions;
CREATE TRIGGER trg_item_descriptions_set_updated_at
BEFORE UPDATE ON :"schema_name".item_descriptions
FOR EACH ROW EXECUTE FUNCTION :"schema_name".set_updated_at();

-- ─── item_pricing ─────────────────────────────────────────────────────────────
-- Pricing, payout, and seller preferences (1-to-1 with items).
-- Maps to: ListingCreate (price, original_price, payment, accept_offers,
--          allow_bundle_discounts, boost_listing, share_to_homepage)

CREATE TABLE IF NOT EXISTS :"schema_name".item_pricing (
    item_id                BIGINT       PRIMARY KEY
                               REFERENCES :"schema_name".items (id) ON DELETE CASCADE,
    list_price             INTEGER      NOT NULL CHECK (list_price BETWEEN 1 AND 10000),
    original_price         INTEGER      CHECK (original_price BETWEEN 1 AND 10000),
    currency_code          CHAR(3)      NOT NULL DEFAULT 'USD',
    payout_method          TEXT         NOT NULL CHECK (char_length(payout_method) BETWEEN 2 AND 40),
    accept_offers          BOOLEAN      NOT NULL DEFAULT FALSE,
    allow_bundle_discounts BOOLEAN      NOT NULL DEFAULT FALSE,
    boost_listing          BOOLEAN      NOT NULL DEFAULT FALSE,
    share_to_homepage      BOOLEAN      NOT NULL DEFAULT FALSE,
    -- Default matches FEE_PERCENT = 10 in backend/app/main.py.
    platform_fee_percent   NUMERIC(5,2) NOT NULL DEFAULT 10.00
                               CHECK (platform_fee_percent BETWEEN 0 AND 100),
    earning_estimate       INTEGER      NOT NULL DEFAULT 0 CHECK (earning_estimate >= 0),
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_original_vs_list_price
        CHECK (original_price IS NULL OR original_price >= list_price)
);

DROP TRIGGER IF EXISTS trg_item_pricing_set_updated_at ON :"schema_name".item_pricing;
CREATE TRIGGER trg_item_pricing_set_updated_at
BEFORE UPDATE ON :"schema_name".item_pricing
FOR EACH ROW EXECUTE FUNCTION :"schema_name".set_updated_at();

-- ─── item_shipping ────────────────────────────────────────────────────────────
-- Shipping and return policy details (1-to-1 with items).
-- Maps to: ListingCreate (location, shipping_time, shipping_cost, returns_policy)

CREATE TABLE IF NOT EXISTS :"schema_name".item_shipping (
    item_id        BIGINT      PRIMARY KEY
                       REFERENCES :"schema_name".items (id) ON DELETE CASCADE,
    location       TEXT        NOT NULL CHECK (char_length(location) BETWEEN 2 AND 80),
    shipping_time  TEXT        NOT NULL CHECK (char_length(shipping_time) BETWEEN 2 AND 40),
    shipping_cost  TEXT        NOT NULL CHECK (char_length(shipping_cost) BETWEEN 2 AND 40),
    returns_policy TEXT        NOT NULL CHECK (char_length(returns_policy) BETWEEN 2 AND 60),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS trg_item_shipping_set_updated_at ON :"schema_name".item_shipping;
CREATE TRIGGER trg_item_shipping_set_updated_at
BEFORE UPDATE ON :"schema_name".item_shipping
FOR EACH ROW EXECUTE FUNCTION :"schema_name".set_updated_at();

-- ─── item_media ───────────────────────────────────────────────────────────────
-- Photos and videos attached to a listing (1-to-many with items).
-- sell.html supports photo upload; this table stores each media asset.

CREATE TABLE IF NOT EXISTS :"schema_name".item_media (
    id               BIGINT      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    item_id          BIGINT      NOT NULL
                         REFERENCES :"schema_name".items (id) ON DELETE CASCADE,
    media_type       TEXT        NOT NULL DEFAULT 'image'
                         CHECK (media_type IN ('image', 'video')),
    storage_provider TEXT,
    storage_key      TEXT,
    public_url       TEXT,
    mime_type        TEXT,
    file_size_bytes  BIGINT      CHECK (file_size_bytes >= 0),
    width_px         INTEGER     CHECK (width_px >= 0),
    height_px        INTEGER     CHECK (height_px >= 0),
    duration_seconds INTEGER     CHECK (duration_seconds >= 0),
    sort_order       INTEGER     NOT NULL DEFAULT 1 CHECK (sort_order > 0),
    is_primary       BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_item_media_order UNIQUE (item_id, sort_order),
    CONSTRAINT chk_media_source_present
        CHECK (COALESCE(NULLIF(storage_key, ''), NULLIF(public_url, '')) IS NOT NULL)
);

-- Enforce at most one primary media asset per item.
CREATE UNIQUE INDEX IF NOT EXISTS uq_item_media_primary_one_per_item
    ON :"schema_name".item_media (item_id)
    WHERE is_primary = TRUE;

DROP TRIGGER IF EXISTS trg_item_media_set_updated_at ON :"schema_name".item_media;
CREATE TRIGGER trg_item_media_set_updated_at
BEFORE UPDATE ON :"schema_name".item_media
FOR EACH ROW EXECUTE FUNCTION :"schema_name".set_updated_at();

-- ─── item_engagement ──────────────────────────────────────────────────────────
-- Marketplace metrics kept separate from core item fields (1-to-1 with items).
-- Maps to: public_item() response fields (savedCount, watchers, featured, price_drops)

CREATE TABLE IF NOT EXISTS :"schema_name".item_engagement (
    item_id     BIGINT      PRIMARY KEY
                    REFERENCES :"schema_name".items (id) ON DELETE CASCADE,
    featured    BOOLEAN     NOT NULL DEFAULT FALSE,
    saved_count INTEGER     NOT NULL DEFAULT 0 CHECK (saved_count >= 0),
    watchers    INTEGER     NOT NULL DEFAULT 0 CHECK (watchers >= 0),
    price_drops INTEGER     NOT NULL DEFAULT 0 CHECK (price_drops >= 0),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS trg_item_engagement_set_updated_at ON :"schema_name".item_engagement;
CREATE TRIGGER trg_item_engagement_set_updated_at
BEFORE UPDATE ON :"schema_name".item_engagement
FOR EACH ROW EXECUTE FUNCTION :"schema_name".set_updated_at();
