# VintageLoop - Current Work Documentation

VintageLoop is a resale web app for old clothes.  
The current implementation includes a Vue-based frontend, a FastAPI backend, JSON-backed storage for runtime data, and PostgreSQL initialization scripts for migration to database-backed storage.

## Current Scope

### Frontend
- Vue SPA served from `pages/index.html` and `assets/js/app.js`
- Routes:
  - Home (`/`)
  - Women (`/women`)
  - Men (`/men`)
  - Item Details (`/item/:slug`)
  - Sell (`/sell`)
  - My Closet (`/closet`)
- Popup-based authentication UI:
  - Login modal
  - Create account modal
  - Country and phone-code inputs included during registration
- Shared styling in `assets/css/styles.css`
- Favicon configured (`assets/favicon.svg`)

### Backend
- FastAPI app in `backend/app/main.py`
- Serves static files and API from one process
- Core API endpoints:
  - `GET /api/home`
  - `GET /api/collections/{audience}`
  - `GET /api/items`
  - `GET /api/items/{slug}`
  - `POST /api/items`
  - `GET /api/closet`
  - `POST /api/auth/register`
  - `POST /api/auth/login`
- Password hashing implemented with PBKDF2-HMAC (SHA-256)
- Current runtime persistence uses `backend/data/store.json`

### Database Initialization (PostgreSQL)
SQL scripts are in `backend/sql/`:
- `00_bootstrap_role_and_db.sql`
- `01_schema_and_security.sql`
- `02_tables.sql`
- `03_indexes.sql`
- `04_seed_data.sql` (intentionally no inserts)

Current schema design is normalized:
- `app.users`
- `app.categories`
- `app.items` (associated to `users` and `categories`)

## Project Structure

```text
assets/
  css/styles.css
  js/app.js
  js/vendor/
  favicon.svg
backend/
  app/main.py
  data/store.json
  sql/
pages/
  index.html
  women.html
  men.html
  sell.html
  closet.html
requirements/
  requirements.txt
index.html
```

## How To Run

## 1. Create environment and install dependencies
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements/requirements.txt
```

## 2. Start backend server
```bash
python -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000 --reload
```

If port `8000` is already in use:
```bash
python -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8001 --reload
```

## 3. Open in browser
- App: `http://127.0.0.1:8000/` (or `8001`)
- API docs: `http://127.0.0.1:8000/docs` (or `8001`)

## SQL Script Runner

Config-driven SQL runner:
- Script: `backend/sql/run_sql.sh`
- Config template: `backend/sql/db.conf.example`

Usage:
```bash
cp backend/sql/db.conf.example backend/sql/db.conf
# edit values in backend/sql/db.conf

backend/sql/run_sql.sh 01_schema_and_security.sql 02_tables.sql 03_indexes.sql
```

## Current Constraints / Next Steps

- Item and auth data are currently persisted in `store.json`; not yet connected to PostgreSQL for live API read/write.
- No JWT/session management yet (login currently validates credentials and returns user info only).
- File/image upload is present in UI but not connected to backend storage.
- Add migrations and database repository layer before production deployment.

## Git Branch

Active delivery branch for this work: `develop`.
