from __future__ import annotations

import json
import hashlib
import hmac
import re
import secrets
from pathlib import Path
from statistics import mean
from typing import Any

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field
from backend.app.public_reference import COUNTRY_TO_DIAL_CODE, REGISTRATION_COUNTRIES

BASE_DIR = Path(__file__).resolve().parents[2]
STORE_PATH = BASE_DIR / "backend" / "data" / "store.json"
PAGES_DIR = BASE_DIR / "pages"
ASSETS_DIR = BASE_DIR / "assets"

FEE_PERCENT = 10


class ListingCreate(BaseModel):
    title: str = Field(min_length=3, max_length=120)
    category: str = Field(min_length=2, max_length=40)
    brand: str = Field(min_length=1, max_length=80)
    size: str = Field(min_length=1, max_length=20)
    audience: str = Field(pattern="^(women|men|unisex|kids)$")
    color: str = Field(min_length=1, max_length=60)
    material: str = Field(min_length=1, max_length=60)
    price: int = Field(ge=1, le=10000)
    original_price: int | None = Field(default=None, ge=1, le=10000)
    condition: str = Field(min_length=2, max_length=80)
    wear: str | None = Field(default=None, max_length=120)
    measurements: str | None = Field(default=None, max_length=160)
    flaws: str | None = Field(default=None, max_length=160)
    description: str = Field(min_length=12, max_length=1200)
    location: str = Field(min_length=2, max_length=80)
    shipping_time: str = Field(min_length=2, max_length=40)
    shipping_cost: str = Field(min_length=2, max_length=40)
    returns_policy: str = Field(min_length=2, max_length=60)
    seller_name: str = Field(min_length=2, max_length=80)
    seller_email: str = Field(min_length=5, max_length=160)
    seller_phone: str | None = Field(default=None, max_length=40)
    payment: str = Field(min_length=2, max_length=40)
    accept_offers: bool = False
    allow_bundle_discounts: bool = False
    boost_listing: bool = False
    share_to_homepage: bool = False


class RegisterCreate(BaseModel):
    full_name: str = Field(min_length=2, max_length=120)
    email: str = Field(min_length=5, max_length=160)
    password: str = Field(min_length=8, max_length=120)
    country: str = Field(min_length=2, max_length=120)
    phone_code: str = Field(pattern=r"^\+\d{1,4}$")
    phone_number: str = Field(min_length=4, max_length=32)


class LoginCreate(BaseModel):
    email: str = Field(min_length=5, max_length=160)
    password: str = Field(min_length=8, max_length=120)


def load_store() -> dict[str, Any]:
    with STORE_PATH.open("r", encoding="utf-8") as store_file:
        return json.load(store_file)


def save_store(store: dict[str, Any]) -> None:
    with STORE_PATH.open("w", encoding="utf-8") as store_file:
        json.dump(store, store_file, indent=2)
        store_file.write("\n")


def normalize_email(value: str) -> str:
    return value.strip().lower()


def normalize_country(value: str) -> str:
    return " ".join(value.split()).strip()


def hash_password(password: str, salt_hex: str | None = None) -> str:
    salt = bytes.fromhex(salt_hex) if salt_hex else secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 120_000)
    return f"{salt.hex()}:{digest.hex()}"


def verify_password(password: str, stored_hash: str) -> bool:
    try:
        salt_hex, digest_hex = stored_hash.split(":", 1)
    except ValueError:
        return False
    calculated = hash_password(password, salt_hex).split(":", 1)[1]
    return hmac.compare_digest(calculated, digest_hex)


def normalize_audience(value: str) -> str:
    lowered = value.strip().lower()
    if lowered in {"women", "men"}:
        return lowered
    return "women" if lowered == "kids" else "men"


def slugify(title: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")
    return slug or "listing"


def unique_slug(items: list[dict[str, Any]], base_slug: str) -> str:
    taken = {item["slug"] for item in items}
    if base_slug not in taken:
        return base_slug

    counter = 2
    while f"{base_slug}-{counter}" in taken:
        counter += 1
    return f"{base_slug}-{counter}"


def category_to_photo_class(category: str) -> str:
    mapping = {
        "jacket": "photo-denim",
        "dress": "photo-rust",
        "shirt": "photo-cream",
        "pants": "photo-olive",
        "sweater": "photo-cream",
        "bag": "photo-leather",
        "blazer": "photo-navy",
        "coat": "photo-charcoal",
        "shoes": "photo-charcoal",
    }
    return mapping.get(category.lower(), "photo-navy")


def format_price(value: int) -> str:
    return f"${value}"


def public_item(item: dict[str, Any]) -> dict[str, Any]:
    return {
        "slug": item["slug"],
        "title": item["title"],
        "audience": item["audience"],
        "category": item["category"],
        "tag": item["tag"],
        "price": format_price(item["price"]),
        "price_value": item["price"],
        "description": f"Size {item['size']} · {item['condition']}",
        "meta": [item["location"], item["badge"]],
        "photoClass": item["photo_class"],
        "savedCount": item["saved_count"],
        "watchers": item["watchers"],
        "status": item["status"],
    }


def detail_item(item: dict[str, Any]) -> dict[str, Any]:
    return {
        "slug": item["slug"],
        "title": item["title"],
        "audience": item["audience"],
        "category": item["category"],
        "tag": item["tag"],
        "price": format_price(item["price"]),
        "originalPrice": format_price(item["original_price"]) if item.get("original_price") else None,
        "size": item["size"],
        "condition": item["condition"],
        "location": item["location"],
        "badge": item["badge"],
        "photoClass": item["photo_class"],
        "brand": item["brand"],
        "material": item["material"],
        "color": item["color"],
        "shippingTime": item["shipping_time"],
        "shippingCost": item["shipping_cost"],
        "returnsPolicy": item["returns_policy"],
        "description": item["description"],
        "longDescription": item["long_description"],
        "measurements": item["measurements"],
        "flaws": item["flaws"],
        "savedCount": item["saved_count"],
        "watchers": item["watchers"],
        "status": item["status"],
        "updatedLabel": item["updated_label"],
        "backRoute": f"/{item['audience']}",
        "highlights": [
            f"{item['shipping_time']} ship-out",
            item["shipping_cost"],
            item["returns_policy"],
        ],
    }


def closet_item(item: dict[str, Any]) -> dict[str, Any]:
    if item["status"] == "draft":
        details = f"Size {item['size']} · Draft saved without final measurements"
    elif item["status"] == "sold":
        details = f"Size {item['size']} · Sold for {format_price(item['price'])} · Payout initiated"
    else:
        details = f"Size {item['size']} · {format_price(item['price'])} · {item['saved_count']} saves this week"

    return {
        "slug": item["slug"],
        "tag": item["tag"],
        "title": item["title"],
        "status": item["status"],
        "statusLabel": item["status"].capitalize(),
        "details": details,
        "meta": [item["location"], item["updated_label"], item["badge"]],
        "photoClass": item["photo_class"],
        "earning": item["earning"],
    }


def build_home_payload(items: list[dict[str, Any]]) -> dict[str, Any]:
    live_items = [item for item in items if item["status"] == "live"]
    featured = next((item for item in live_items if item.get("featured")), live_items[0])
    shipping_hours = [
        24 if item["shipping_time"] == "24 hrs" else 48 if item["shipping_time"] == "2 days" else 72
        for item in live_items
    ]

    return {
        "stats": [
            {"value": str(len(live_items)), "label": "Live closet listings"},
            {"value": f"{round(mean(shipping_hours))} hrs", "label": "Average ship-out time"},
            {"value": f"{FEE_PERCENT}%", "label": "Flat selling fee"},
        ],
        "featuredItem": detail_item(featured),
        "items": [public_item(item) for item in live_items],
    }


def build_collection_payload(items: list[dict[str, Any]], audience: str) -> dict[str, Any]:
    filtered = [item for item in items if item["status"] == "live" and item["audience"] == audience]
    under_25 = sum(1 for item in filtered if item["price"] < 25)
    total_saves = sum(item["saved_count"] for item in filtered)
    price_drops = sum(item["price_drops"] for item in filtered)
    jackets = sum(1 for item in filtered if item["category"].lower() in {"jacket", "coat", "blazer"})

    if audience == "women":
        return {
            "eyebrow": "Women's closet",
            "title": "Dedicated picks for women.",
            "description": "Browse dresses, handbags, knitwear, and standout layering pieces collected into one page so shoppers can filter faster.",
            "pills": [
                f"{len(filtered)} live listings",
                "Most saved: dresses",
                f"Free shipping on {sum(1 for item in filtered if item['shipping_cost'] == 'Free shipping')} items",
            ],
            "summaryTitle": "Women's listings are moving quickly.",
            "summary": [
                {"value": str(len(filtered)), "label": "live arrivals"},
                {"value": str(under_25), "label": "pieces under $25"},
                {"value": str(total_saves), "label": "buyer saves today"},
                {"value": "24h", "label": "average ship time"},
            ],
            "sectionEyebrow": "Women",
            "sectionTitle": "Curated women's listings.",
            "sectionCopy": "Everything on this page is tagged for women's sizing and styling.",
            "footerTitle": "Want to add your piece here?",
            "footerText": "Create a women's listing and it can appear directly in this collection.",
            "items": [public_item(item) for item in filtered],
        }

    return {
        "eyebrow": "Men's closet",
        "title": "Dedicated picks for men.",
        "description": "Shop jackets, trousers, workwear, and everyday staples grouped into a focused men's page with the most active resale pieces.",
        "pills": [
            f"{len(filtered)} live listings",
            f"{jackets} outerwear pieces",
            f"{price_drops} price drops active",
        ],
        "summaryTitle": "Men's essentials are being saved fast.",
        "summary": [
            {"value": str(jackets), "label": "new jackets"},
            {"value": str(sum(item["watchers"] for item in filtered)), "label": "buyers watching"},
            {"value": str(price_drops), "label": "price drops today"},
            {"value": "2 days", "label": "average sale cycle"},
        ],
        "sectionEyebrow": "Men",
        "sectionTitle": "Curated men's listings.",
        "sectionCopy": "Every item below is tagged for men's or unisex styling and fit.",
        "footerTitle": "Have men's pieces to list?",
        "footerText": "Publish them from the sell page and route them into this collection.",
        "items": [public_item(item) for item in filtered],
    }


def build_closet_payload(store: dict[str, Any]) -> dict[str, Any]:
    items = store["items"]
    return {
        "items": [closet_item(item) for item in items if item["status"] in {"live", "draft", "sold"}],
        "tasks": store["closet_tasks"],
    }


app = FastAPI(title="VintageLoop API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/assets", StaticFiles(directory=ASSETS_DIR), name="assets")
app.mount("/pages", StaticFiles(directory=PAGES_DIR), name="pages")


@app.get("/")
def root() -> FileResponse:
    return FileResponse(BASE_DIR / "index.html")


@app.get("/index.html")
def root_index() -> FileResponse:
    return FileResponse(BASE_DIR / "index.html")


@app.get("/favicon.ico")
def favicon() -> FileResponse:
    return FileResponse(ASSETS_DIR / "favicon.svg", media_type="image/svg+xml")


@app.get("/api/home")
def get_home() -> dict[str, Any]:
    store = load_store()
    return build_home_payload(store["items"])


@app.get("/api/collections/{audience}")
def get_collection(audience: str) -> dict[str, Any]:
    normalized = normalize_audience(audience)
    store = load_store()
    return build_collection_payload(store["items"], normalized)


@app.get("/api/items")
def get_items(
    audience: str | None = Query(default=None),
    status: str = Query(default="live"),
) -> list[dict[str, Any]]:
    store = load_store()
    items = store["items"]
    if audience:
        items = [item for item in items if item["audience"] == normalize_audience(audience)]
    if status:
        items = [item for item in items if item["status"] == status]
    return [public_item(item) for item in items]


@app.get("/api/items/{slug}")
def get_item(slug: str) -> dict[str, Any]:
    store = load_store()
    item = next((entry for entry in store["items"] if entry["slug"] == slug), None)
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    return detail_item(item)


@app.get("/api/closet")
def get_closet() -> dict[str, Any]:
    store = load_store()
    return build_closet_payload(store)


@app.get("/api/public/register-meta")
def get_register_meta() -> dict[str, Any]:
    phone_codes = sorted({entry["dial_code"] for entry in REGISTRATION_COUNTRIES}, key=lambda code: int(code[1:]))
    return {"countries": REGISTRATION_COUNTRIES, "phone_codes": phone_codes}


@app.post("/api/items", status_code=201)
def create_item(listing: ListingCreate) -> dict[str, Any]:
    store = load_store()
    items = store["items"]
    slug = unique_slug(items, slugify(listing.title))
    audience = normalize_audience(listing.audience)

    item = {
        "slug": slug,
        "title": listing.title,
        "audience": audience,
        "category": listing.category,
        "tag": listing.category,
        "price": listing.price,
        "original_price": listing.original_price,
        "size": listing.size,
        "condition": listing.condition,
        "location": listing.location,
        "badge": listing.shipping_cost,
        "photo_class": category_to_photo_class(listing.category),
        "featured": False,
        "saved_count": 0,
        "watchers": 0,
        "price_drops": 0,
        "shipping_time": listing.shipping_time,
        "shipping_cost": listing.shipping_cost,
        "color": listing.color,
        "material": listing.material,
        "brand": listing.brand,
        "description": listing.description[:140],
        "long_description": listing.description,
        "measurements": listing.measurements or "Pending",
        "flaws": listing.flaws or "No visible flaws reported",
        "seller_name": listing.seller_name,
        "seller_email": listing.seller_email,
        "seller_phone": listing.seller_phone or "",
        "payment": listing.payment,
        "returns_policy": listing.returns_policy,
        "status": "live",
        "updated_label": "Just listed",
        "earning": listing.price,
    }

    items.insert(0, item)
    save_store(store)
    return detail_item(item)


@app.post("/api/auth/register", status_code=201)
def register_user(payload: RegisterCreate) -> dict[str, Any]:
    store = load_store()
    users = store.setdefault("users", [])
    email = normalize_email(payload.email)

    if any(normalize_email(user.get("email", "")) == email for user in users):
        raise HTTPException(status_code=409, detail="Email is already registered")

    country = normalize_country(payload.country)
    expected_code = COUNTRY_TO_DIAL_CODE.get(country.lower())
    if not expected_code:
        raise HTTPException(status_code=422, detail="Unsupported country")
    if payload.phone_code != expected_code:
        raise HTTPException(
            status_code=422,
            detail=f"Phone code must match selected country ({expected_code})",
        )

    user = {
        "id": len(users) + 1,
        "full_name": payload.full_name.strip(),
        "email": email,
        "password_hash": hash_password(payload.password),
        "country": country,
        "phone_code": payload.phone_code,
        "phone_number": payload.phone_number.strip(),
    }
    users.append(user)
    save_store(store)
    return {
        "id": user["id"],
        "full_name": user["full_name"],
        "email": user["email"],
        "country": user["country"],
    }


@app.post("/api/auth/login")
def login_user(payload: LoginCreate) -> dict[str, Any]:
    store = load_store()
    users = store.get("users", [])
    email = normalize_email(payload.email)
    user = next((entry for entry in users if normalize_email(entry.get("email", "")) == email), None)

    if not user or not verify_password(payload.password, user.get("password_hash", "")):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    return {
        "message": "Login successful",
        "user": {
            "id": user["id"],
            "full_name": user["full_name"],
            "email": user["email"],
            "country": user["country"],
        },
    }
