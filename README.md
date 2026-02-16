<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%20%7C%20Android-blue?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Backend-Node.js%20%2B%20Express-green?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Database-PostgreSQL-336791?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Frontend-React%20Native-61DAFB?style=for-the-badge" />
</p>

<h1 align="center">🧵 Textil</h1>

<p align="center">
  <strong>Multi-tenant management system for textile companies</strong><br>
  Production · Orders · Sales · Inventory · Costs · Finance
</p>

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────┐
│                   React Native App                   │
│              (iOS + Android via Expo)                 │
├──────────────────────────────────────────────────────┤
│                 Node.js + Express API                │
│            Custom Auth (bcrypt + JWT)                 │
├──────────────────────────────────────────────────────┤
│                    PostgreSQL                        │
│         Multi-tenant (empresa_id isolation)           │
└──────────────────────────────────────────────────────┘
```

### Multi-Tenant Design

Every table includes an `empresa_id` column, ensuring **complete data isolation** between companies. A root user has system-wide access to manage all companies and approvals.

### Authentication

Fully custom — no external auth providers. Users are stored in the `usuarios` table with `password_hash` (bcrypt). Sessions are managed via JWT tokens.

### Permissions

Each company creates its own roles from a **master list of 25 permissions** across 13 categories. Company admins assign roles to their users, controlling access to every module.

---

## 📦 Modules

| # | Module | Description |
|:-:|--------|-------------|
| 1 | **Companies & Users** | Company registration, user management, roles & permissions |
| 2 | **Catalogs** | Agents, clients, suppliers, departments, lines, brands, colors, sizes, units, models, items, fabric types, fabrics, fabric pricing, contractors, services |
| 3 | **Client Orders** | Customer orders with line items, status tracking, and movement history |
| 4 | **Purchase Orders** | Supplier orders and raw material purchases with details |
| 5 | **Production** | Production tracking, receipt management, contractor payments, digital signatures |
| 6 | **Purchase Receipts** | Goods received notes with detail lines and payment tracking |
| 7 | **Sales** | Client sales with invoicing, signatures, shipment tracking, and collections |
| 8 | **Exits & Returns** | Material exits and merchandise returns with full audit trail |
| 9 | **Costing** | General costing (fabrics + supplies) and denim-specific costing |
| 10 | **Finance** | Dispersions, loans, commissions, royalties, bank/cash movements, invoices |
| 11 | **Assets & Printing** | Company assets, print center with signatures, design & pattern control |

---

## 🗄️ Database

**~50 tables** organized in 10 sequential migration files:

```
migrations/
├── 001_base_sistema.sql        → Companies, users, permissions, roles
├── 002_catalogos.sql           → All 16 catalog tables
├── 003_ordenes.sql             → Client orders, purchase orders, supply purchases
├── 004_produccion.sql          → Production, receipts, payments
├── 005_recibos_compras.sql     → Purchase receipts with details & payments
├── 006_ventas.sql              → Sales, details, movements, collections
├── 007_salidas_reingresos.sql  → Material exits & returns
├── 008_costos.sql              → General & denim costing
├── 009_financiero.sql          → Full financial module (14 tables)
├── 010_activos_impresion.sql   → Assets, printing, design control
└── README.md                   → Migration guide
```

All tables use **UUIDs** as primary keys and include `created_at` / `updated_at` timestamps with automatic triggers.

> **Adding changes:** Create a new file (e.g., `011_new_field.sql`) with `ALTER TABLE` statements. Never modify already-executed files.

---

## 🖥️ Catalog Upload Tool

A simple web interface for bulk-loading catalog data via **CSV or Excel** files.

**Supports 14 catalogs:** Agents, Clients, Suppliers, Departments, Lines, Brands, Colors, Sizes, Units, Models, Items, Fabric Types, Contractors, Services.

**How it works:**
1. Select or create a company
2. Choose the catalog to populate
3. Upload a CSV or Excel file
4. Preview inserted data and statistics

```
public/
├── index.html    → Upload interface
├── styles.css    → Styling
└── app.js        → Client-side logic

server.js         → Express API (port 5000)
```

---

## 📁 Project Structure

```
.
├── migrations/          → SQL migration files (10 files, ~50 tables)
├── public/              → Web interface for catalog uploads
├── legacy/              → Original SwiftUI code (reference only)
│   └── Textil/          → 176 Swift files (models, views, services)
├── server.js            → Express server connected to Supabase
├── PLAN_IMPLEMENTACION.md  → Implementation plan (11 phases, 124 hours)
├── GUIA_DISENO.md       → Design guidelines extracted from SwiftUI
└── README.md            → This file
```

---

## 🎨 Design

The app follows the design patterns from the original SwiftUI implementation. Full guidelines are documented in [`GUIA_DISENO.md`](GUIA_DISENO.md), covering:

- **Color palette** — Light gray backgrounds, white cards, iOS system colors
- **Typography** — SF-style hierarchy (large title, headline, caption)
- **Components** — FormSection, list cards, catalog sections, quick-access grid
- **Screen patterns** — Login, catalog lists, forms, tab bar, dashboard
- **Behaviors** — Modal for creation, push for editing, role-based visibility

---

## 🗺️ Implementation Roadmap

| Phase | Focus | Hours |
|:-----:|-------|:-----:|
| 1 | Project setup, auth, navigation | 16 |
| 2 | Catalogs (CRUD for all 16 tables) | 8 |
| 3 | Costing (General + Denim) | 12 |
| 4 | Production & Receipts | 12 |
| 5 | Client Orders | 10 |
| 6 | Purchases & Services | 10 |
| 7 | Inventory & Movements | 12 |
| 8 | Sales & Exports | 10 |
| 9 | Services & Requests | 8 |
| 10 | Reports | 8 |
| 11 | Signatures, Publishing & Final Delivery | 6 |
| | **Total** | **124** |

See [`PLAN_IMPLEMENTACION.md`](PLAN_IMPLEMENTACION.md) for the full breakdown.

---

## ⚙️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile App | React Native + Expo |
| Backend API | Node.js + Express |
| Database | PostgreSQL (Supabase) |
| Authentication | Custom (bcrypt + JWT) |
| File Uploads | Multer + csv-parse + xlsx |

---

<p align="center">
  <sub>Built for the textile industry — production, sales, and everything in between.</sub>
</p>
