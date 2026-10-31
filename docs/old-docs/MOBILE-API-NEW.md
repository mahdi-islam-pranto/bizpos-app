# bizPOS Mobile API

The reference for building the bizPOS mobile app. Everything a person can do in
the web workspace's main processes — selling, stock, purchase, dues, expenses,
reports, team and store control — is reachable from here, and each person gets
exactly what their role allows.

The API is the web workspace's own data layer: the same controllers, the same
database, and the same permission check on every call. The app cannot do more
than the person could do in a browser, and hiding a button in the app is only a
courtesy. The server refuses anyway.

**Contents**

1. [Basics](#1-basics) — base URL, headers, response and error shape
2. [Signing in and the session](#2-signing-in-and-the-session) — including signing a new shop up
3. [Roles and permissions](#3-roles-and-permissions) — who can do what
4. [Role-wise app map](#4-role-wise-app-map) — which screens each role gets
5. [Main processes, step by step](#5-main-processes-step-by-step)
6. [Endpoint reference](#6-endpoint-reference)
7. [Not in the API yet](#7-not-in-the-api-yet)

---

## 1. Basics

### Base URL

```
https://<your-domain>/api/v1
```

Local development: `http://127.0.0.1:8000/api/v1`.

### Headers on every call

| Header | Value | When |
|---|---|---|
| `Accept` | `application/json` | always |
| `Content-Type` | `application/json` | when sending a body |
| `Authorization` | `Bearer <token>` | every call except `auth/login` and `public/permissions` |
| `X-HTTP-Method-Override` | `PUT`, `PATCH` or `DELETE` | see below |

No cookie and no CSRF token are needed.

### PUT, PATCH and DELETE: always send them as POST

The live host's web server (LiteSpeed) refuses `PUT`, `PATCH` and `DELETE` with
its own HTML 403 page before the request reaches Laravel. **Send these as a
`POST` with the real verb in `X-HTTP-Method-Override`.** Laravel reads the header
before routing, so it works the same everywhere:

```http
POST /api/v1/products/42/prices
Authorization: Bearer 17|Xk2...
X-HTTP-Method-Override: PATCH
Content-Type: application/json

{"purchasePrice": 80, "salePrice": 100, "wholesalePrice": 95}
```

Build this into the app's HTTP client once, for every call. In this document
those endpoints are still written as `PATCH` or `DELETE`, which is their real verb.

A **403 whose body is HTML, not JSON**, came from the web server, not from
bizPOS. Usually the verb was sent without the override.

### Success shape

```json
{
  "data": { ... },
  "meta": { ... }
}
```

`data` is an object or an array. `meta` shows up only on some lists. It holds
pagination and flags such as `mayCreate` and `mayEdit`, which tell the app which
buttons to show on that screen.

Conventions:

- Field names are **camelCase**, both in requests and in responses.
- Every call takes and returns JSON, with one exception: uploading a photo of a
  purchase bill is `multipart/form-data` (see
  [Purchase](#purchase)). Let the HTTP client set the boundary; do not write a
  `Content-Type` header by hand for that one.
- Money is a JSON number in the store's currency (`store.currency`, usually `BDT`).
- Dates are ISO 8601 strings (`2026-09-13T14:05:00+06:00`). Report day buckets
  are `YYYY-MM-DD`.
- IDs are integers.

### Pagination

`GET /sales`, `GET /products`, `GET /catalog` and `GET /admin/catalog` are
paginated. Pass `?page=2&perPage=25` and read `meta.total`, `meta.page` and
`meta.perPage`. Other lists return a fixed recent window (for example the latest
50 purchases or 100 customers) and accept `?q=` to search.

The catalogue runs to thousands of rows for a pharmacy, so paging it is not
optional — `meta.pages` says how many there are.

### Error shape

```json
{
  "error": {
    "message": "Human-readable reason",
    "code": "machine_code"
  }
}
```

| HTTP | `code` | Meaning | What the app should do |
|---|---|---|---|
| 401 | `unauthenticated` | Token missing, wrong, expired or revoked, or the user was deactivated | Delete the stored token and go to the login screen |
| 403 | `forbidden` | This user lacks the permission. `error.permission` names it | Show "not allowed" and hide that action |
| 422 | `validation` | Input failed validation. `error.fields` maps each field to its messages | Show the messages beside the fields |
| 422 | a business code (`insufficient_stock`, `sale`, `shift_open`, `plan_limit`, ...) | A rule refused the action. `message` says why | Show `message` |
| 409 | `already_in_catalog` | Product suggestion duplicates the catalogue | See [Catalogue](#catalogue) |
| 404 | `not_found` | No such record **in the current store**, or no such route | |
| 400 | `bad_request` | No store or branch selected (user belongs to no active store) | Show a "no store" screen |
| 429 | `too_many_requests` | Login tried more than 10 times a minute | Wait and retry |

Example 403:

```json
{
  "error": {
    "message": "Missing permission: report.profit.view",
    "code": "forbidden",
    "permission": "report.profit.view"
  }
}
```

Example 422 validation:

```json
{
  "error": {
    "message": "The lines field is required.",
    "code": "validation",
    "fields": { "lines": ["The lines field is required."] }
  }
}
```

---

## 2. Signing in and the session

### How a token works

- `POST /auth/login` returns a token like `17|Xk2f...`. **Store it securely**
  (Keychain on iOS, EncryptedSharedPreferences or Keystore on Android). The
  server keeps only a hash of it and never shows it again.
- Each token is one device. It lasts **90 days** and then returns 401.
- The token also remembers **which store and branch this device is working
  in**. Every call acts on that store and branch, so no store ID is sent per
  call. Switching on one phone does not move the user's other phones or the
  web browser.
- Every record is fenced to the current store. An ID from another store
  answers 404.

### App start-up flow

```
                ┌───────────────────────────┐
 app opens ───► │ token saved?              │── no ──► Login screen
                └────────────┬──────────────┘
                             │ yes
                             ▼
                     GET /me ──── 401 ──► delete token ► Login screen
                             │ 200
                             ▼
             store == null? ──── yes ──► "No store assigned" screen
                             │ no
                             ▼
      build the menu from data.permissions  (section 4)
      show store and branch pickers when stores/branches > 1
```

### `POST /auth/login`

No token needed. Limited to 10 tries a minute.

```json
{
  "email": "cashier@rahman.test",
  "password": "bizpos123",
  "deviceName": "Samsung A54 — Counter 2"
}
```

`deviceName` is optional and shows in the device list. `201`:

```json
{
  "data": {
    "token": "17|Xk2fQ9...",
    "tokenType": "Bearer",
    "expiresAt": "2026-12-12T10:00:00+06:00",
    "user": { "id": 4, "name": "Karim", "email": "cashier@rahman.test", "isSuperAdmin": false }
  }
}
```

A wrong email or password, or a deactivated account, returns `422 validation`
with `fields.email`.

Right after login, call `GET /me`. The first authenticated call puts the device
in the user's default store and branch.

### `POST /auth/register` — a shop signing itself up

No account needed, and the only endpoint here that creates one. Throttled to
**5 an hour per address**, because five new shops an hour from one phone is not
five new shops.

```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "name": "Rahman Pharmacy",
  "storeTypeId": 1,
  "ownerName": "Abdul Rahman",
  "email": "rahman@shop.com",
  "phone": "01711223344",
  "password": "secret1",
  "address": "Mirpur 10",
  "branchName": "Main Branch",
  "deviceName": "Rahman's phone"
}
```

`201` stands the whole shop up and signs the owner in — the same provisioning
the admin screen does, so the shop has its owner account, main branch, cash and
bKash accounts, a walk-in customer, a VAT rate, a Salary expense type and the
settings the till reads. Nothing to configure before the first sale.

```json
{ "data": {
  "token": "31|Xk2...", "tokenType": "Bearer", "expiresAt": "...",
  "store": { "id": 42, "name": "Rahman Pharmacy", "slug": "rahman-pharmacy",
             "trialEndsAt": "2026-09-28T23:59:59+06:00", "trialDaysLeft": 5 },
  "user": { "id": 108, "name": "Abdul Rahman", "email": "rahman@shop.com" },
  "branch": { "id": 61, "name": "Main Branch" }
} }
```

There is no second step: the token in the reply is a working one, so the app goes
straight to the till. A sign-up that ends at a login screen is a sign-up half the
people abandon.

**The five-day clock.** A shop that signs itself up gets `trialDays` (currently
**5**) and then stops: sign-in is refused until an admin extends it. Nothing is
deleted — the products, sales and figures are all still there for whenever it is
turned back on. `GET /me` carries `store.trial_ends_at` and
`store.trial_days_left` so the app can warn on the last day rather than let the
door shut without notice.

#### `409` — an address the platform already knows

**One account may own several shops.** The schema has said so from the start: a
membership row per shop with a unique pair on it, so one address may be in as
many shops as it likes and never twice in the same one. What it may not do is
get there through this endpoint.

| `code` | When | What the app should do |
|---|---|---|
| `sign_in_to_add_store` | The **email** is already an account | Send them to sign-in, then `POST /stores` |
| `already_registered` | The **phone** belongs to somebody else | Show the message; this needs the platform |

```json
{ "error": {
  "code": "sign_in_to_add_store",
  "message": "This email already has an account. Sign in, then add another store from inside the app.",
  "messageBn": "এই ইমেইলে অ্যাকাউন্ট আছে। সাইন ইন করে অ্যাপ থেকেই আরেকটা দোকান যোগ করুন।",
  "on": "email"
} }
```

**Why a known email is turned away rather than reused.** Attaching the new shop
to that account and handing back a token would mean anybody who knows an address
could type a password of their own and be signed in as its owner. The account has
to prove itself first, which is exactly what signing in is. So the second shop is
opened from inside, where no password travels at all.

Phones are matched on their **last nine digits**, so `01711-223344`,
`+8801711223344` and `01711 223344` are one number rather than three.

### `GET /stores` and `POST /stores` — one account, several shops

Authenticated, and outside every store permission on purpose: opening a shop of
your own is not an action inside somebody else's. The person doing it may be
standing in a store where they are only a cashier — or, on the morning their
trial ended, in no store at all.

`GET /stores` is what a store picker is drawn from:

```json
{ "data": [
    { "id": 42, "name": "Rahman Pharmacy", "slug": "rahman-pharmacy",
      "storeType": "Pharmacy", "isOwner": true, "isCurrent": true,
      "trialEndsAt": "2026-09-28T23:59:59+06:00", "trialDaysLeft": 5 }
  ],
  "meta": { "locked": { "id": 39, "name": "Old Shop" } } }
```

A shop the platform has closed is **not in the list** — `meta.locked` is there so
a screen can say why the list is shorter than the person remembers, rather than
leave them wondering.

`POST /stores` takes `name`, `storeTypeId` and `phone`, and optionally
`address` and `branchName`. It provisions exactly what a public sign-up does — owner role,
branch, accounts, walk-in customer, settings — on the same five-day clock,
because whether a shop carries on is the platform's decision and does not become
cheaper for somebody who already had an account. Two shops with the same name
under one account are refused (`409 duplicate_store`): that is nearly always a
button pressed twice, and nobody notices until both have stock in them.

Then `POST /auth/switch-store` to move into it.

### `GET /public/store-types` — what the sign-up form needs

Open, because the form is: `storeTypes[] {id, name, slug}`,
`plans[] {id, name, price, interval}` and `trialDays`. Asking somebody to sign in
before they can see the list they must choose from is a circle.

### `403` at sign-in: a store that has been closed

Right password, nowhere to go. Returned by `POST /auth/login` when every store
the person can reach is suspended or past a trial nobody extended:

```json
{ "error": {
  "code": "trial_ended",
  "message": "The trial period for this store has ended. Please contact the system admin to continue.",
  "messageBn": "এই দোকানের ট্রায়াল সময় শেষ হয়েছে। চালু রাখতে সিস্টেম অ্যাডমিনের সাথে যোগাযোগ করুন।",
  "store": { "name": "Rahman Pharmacy", "trialEndsAt": "..." }
} }
```

`code` is `trial_ended` or `store_suspended`. Both mean the same thing to the
app — show the message, offer no retry — and they mean different things to the
shopkeeper, which is why they are told apart.

### `GET /me` — who am I, where am I, what may I do

Call it at start-up, after switching store or branch, and whenever the app
comes back to the foreground after a long time. An owner may have changed the
person's role in the meantime.

```json
{
  "data": {
    "user":   { "id": 4, "name": "Karim", "email": "cashier@rahman.test", "locale": "bn", "theme": "daylight", "is_super_admin": false },
    "store":  { "id": 1, "name": "Rahman Pharmacy", "slug": "rahman-pharmacy", "currency": "BDT", "store_type_id": 1, "store_type_name": "Pharmacy" },
    "branch": { "id": 1, "name": "Main Branch", "code": "MAIN" },
    "stores":   [ { "id": 1, "name": "Rahman Pharmacy", "slug": "rahman-pharmacy" } ],
    "branches": [ { "id": 1, "name": "Main Branch", "code": "MAIN" }, { "id": 2, "name": "Mirpur", "code": "MRP" } ],
    "role": { "id": 4, "name": "cashier", "label": "Cashier", "label_bn": "ক্যাশিয়ার" },
    "permissions": [ "pos.sale.create", "pos.sale.print", "pos.sale.hold", "..." ],
    "impersonating": false
  }
}
```

> **Build the app from `permissions`, never from `role.name`.** An owner can
> take a single permission away from one person. The role then still says
> `cashier`, but the list is shorter. The server enforces the list, not the name.

`store` and `branch` are `null` when the user belongs to no active store.
`impersonating` is `true` while a super admin is inside someone's store. Show a
"Support mode" badge.

### `POST /auth/switch-store`

```json
{ "storeId": 3 }
```

`200 {"data": {"storeId": 3}}`. The branch resets to that store's default. Then
call `GET /me` again: permissions differ per store. A store the user cannot
access returns `403`.

### `POST /auth/switch-branch`

```json
{ "branchId": 2 }
```

`200 {"data": {"storeId": 1, "branchId": 2}}`. Stock, sales, shifts and reports
are per branch, so reload the screens.

### `PATCH /me/preferences`

```json
{ "locale": "en", "theme": "midnight" }
```

`locale` is `bn` or `en`. `theme` is `daylight`, `midnight`, `workspace`,
`paper` or `contrast`. Both are optional and saved on the account.

### `GET /auth/devices` and `DELETE /auth/devices/{id}`

Lists this user's signed-in phones: `id`, `name`, `current`, `lastUsedAt`,
`createdAt`, `expiresAt`. Deleting one signs that phone out, which is what to
do with a lost phone.

### `POST /auth/logout`

Signs **this device** out. The token stops working immediately.

### `GET /public/permissions`

No token. Returns the full permission catalogue (with English and Bangla labels)
and the preset roles, for a help or about screen.

---

## 3. Roles and permissions

### The roles

Every store starts with these roles. An owner may assign them, and single
permissions can be taken away from single people, so always read `permissions`
from `/me`.

| Key | Role | বাংলা | Who it is for |
|---|---|---|---|
| `super_admin` | Super Admin | সুপার অ্যাডমিন | Platform staff. Everything in every store, plus the admin endpoints |
| `store_owner` | Store Owner | দোকান মালিক | Everything in their own store |
| `manager` | Manager | ম্যানেজার | Owner minus profit report, role management, deleting products, purchases or customers, voiding invoices and API keys |
| `cashier` | Cashier | ক্যাশিয়ার | Counter: sell, hold, cash drawer, customers, collect dues. Sees only their own invoices, and no costs |
| `stock_keeper` | Stock Keeper | স্টক কিপার | Products, catalogue, stock adjustments, packages, purchases, suppliers, stock report |
| `accountant` | Accountant | হিসাবরক্ষক | Accounts, expenses, all invoices, dues, every report |
| `auditor` | Auditor | নিরীক্ষক | Read-only view of everything (no create, edit, delete or approve) |

### Permission × role matrix (what the API actually checks)

✅ = has it by default. Super Admin has every permission and is left out of the
table.

Abbreviations: **OW** Owner · **MG** Manager · **CA** Cashier · **SK** Stock
Keeper · **AC** Accountant · **AU** Auditor

| Permission | OW | MG | CA | SK | AC | AU |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| **POS** | | | | | | |
| `pos.sale.create` — open POS and sell | ✅ | ✅ | ✅ | | | |
| `pos.sale.change_price` — edit unit price in cart | ✅ | ✅ | | | | |
| `pos.sale.give_discount` — line and order discount | ✅ | ✅ | | | | |
| `pos.sale.hold` — hold and resume carts | ✅ | ✅ | ✅ | | | |
| `pos.shift.manage` — open and close cash drawer | ✅ | ✅ | ✅ | | | |
| `pos.sale.redeem_points` — redeem loyalty points | ✅ | ✅ | ✅ | | | |
| `pos.sale.print` — print receipt | ✅ | ✅ | ✅ | | | |
| **Catalogue** | | | | | | |
| `catalog.product.search` | ✅ | ✅ | ✅ | ✅ | | ✅ |
| `catalog.product.import` — add catalogue product to store | ✅ | ✅ | | ✅ | | |
| `catalog.product.suggest` — suggest a new product | ✅ | ✅ | | ✅ | | |
| `catalog.suggestion.review` — approve own store's suggestions | ✅ | ✅ | | | | |
| **Products and stock** | | | | | | |
| `inventory.product.view` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `inventory.product.update` — change prices | ✅ | ✅ | | ✅ | | |
| `inventory.product.view_cost` — see purchase cost | ✅ | ✅ | | ✅ | ✅ | ✅ |
| `inventory.stock.view` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `inventory.adjust.create` — stock adjustment or damage | ✅ | ✅ | | ✅ | | |
| `inventory.package.view` | ✅ | ✅ | ✅ | ✅ | | ✅ |
| `inventory.package.manage` | ✅ | ✅ | | ✅ | | |
| **Sales** | | | | | | |
| `sales.invoice.view` — own invoices | ✅ | ✅ | ✅ | | | ✅ |
| `sales.invoice.view_all` — everyone's invoices | ✅ | ✅ | | | ✅ | ✅ |
| `sales.return.create` — accept a return | ✅ | ✅ | | | | |
| `sales.payment.collect` — collect a due | ✅ | ✅ | ✅ | | ✅ | |
| **Customers** | | | | | | |
| `customers.customer.view` | ✅ | ✅ | ✅ | | ✅ | ✅ |
| `customers.customer.create` | ✅ | ✅ | ✅ | | | |
| `customers.customer.update` | ✅ | ✅ | | | | |
| `customers.credit.manage` — set credit limit | ✅ | ✅ | | | | |
| `customers.ledger.view` | ✅ | ✅ | | | ✅ | ✅ |
| `customers.points.view` | ✅ | ✅ | ✅ | | ✅ | ✅ |
| `customers.points.adjust` | ✅ | ✅ | | | | |
| **Purchase** | | | | | | |
| `purchase.bill.view` | ✅ | ✅ | | ✅ | ✅ | ✅ |
| `purchase.bill.create` | ✅ | ✅ | | ✅ | | |
| `purchase.supplier.manage` | ✅ | ✅ | | ✅ | | |
| **Accounts** | | | | | | |
| `accounts.account.view` | ✅ | ✅ | | | ✅ | ✅ |
| `accounts.account.manage` — create accounts | ✅ | ✅ | | | ✅ | |
| `accounts.transfer.create` | ✅ | ✅ | | | ✅ | |
| `accounts.expense.create` | ✅ | ✅ | | | ✅ | |
| `accounts.expense.delete` | ✅ | ✅ | | | ✅ | |
| `accounts.category.manage` — expense types | ✅ | ✅ | | | ✅ | |
| **Reports** | | | | | | |
| `report.sales.view` | ✅ | ✅ | | | ✅ | ✅ |
| `report.profit.view` | ✅ | | | | ✅ | ✅ |
| `report.stock.view` | ✅ | ✅ | | ✅ | ✅ | ✅ |
| `report.due.view` | ✅ | ✅ | | | ✅ | ✅ |
| **Settings** | | | | | | |
| `settings.store.view` | ✅ | ✅ | | | | ✅ |
| `settings.store.update` — store info, VAT, loyalty | ✅ | ✅ | | | | |
| `settings.branch.manage` | ✅ | ✅ | | | | |
| `settings.user.manage` — add, suspend team members | ✅ | ✅ | | | | |
| `settings.role.manage` — change a member's role | ✅ | | | | | |
| `settings.activity.view` — activity log | ✅ | ✅ | | | | ✅ |
| **Super admin** (`admin.*`) | only Super Admin | | | | | |

The catalogue has more permissions than the API has endpoints for (void, stock
transfer, VAT report, export and others). See [section 7](#7-not-in-the-api-yet).

### Fields that change with permissions

The same endpoint may return less to a weaker role. Handle `null` or `0`:

| Where | Field | Hidden unless |
|---|---|---|
| `GET /pos/search` | `purchasePrice` is `null` | `inventory.product.view_cost` |
| `GET /products` | `purchasePrice`, `wholesalePrice` are `0` (`meta.showCost` says so) | `inventory.product.view_cost` |
| `GET /products/{id}/history` | `prices` is empty | `inventory.product.view_cost` |
| `GET /customers/search` | `loyaltyPoints` is `null` | `customers.points.view` |
| `GET /reports/sales` | `topProducts[].profit` is `null` (`showProfit: false`) | `report.profit.view` |
| `GET /sales`, `GET /sales/{id}` | only own invoices | `sales.invoice.view_all` |
| `GET /settings` | `activity` is empty | `settings.activity.view` |
| `POST /pos/checkout` | `unitPrice` and `discount` in lines, and `orderDiscount`/`orderDiscountPercent`, are **ignored** | `pos.sale.change_price`, `pos.sale.give_discount` |
| `POST/PATCH /customers` | `creditLimit` is ignored | `customers.credit.manage` |

---

## 4. Role-wise app map

Show a tab or menu item when the user has its **gate permission**. Inside a
screen, use the action permissions (or the `meta.may*` flags the list returns)
to show buttons.

| App screen | Gate permission | Action permissions inside | OW | MG | CA | SK | AC | AU |
|---|---|---|:-:|:-:|:-:|:-:|:-:|:-:|
| **Dashboard** | any of `report.sales.view`, `inventory.stock.view` | — | ✅ | ✅ | ✅* | ✅* | ✅ | ✅ |
| **POS / Sell** | `pos.sale.create` | `pos.sale.hold`, `pos.shift.manage`, `pos.sale.change_price`, `pos.sale.give_discount`, `pos.sale.redeem_points`, `customers.customer.create` | ✅ | ✅ | ✅ | | | |
| **Invoices** | `sales.invoice.view` or `sales.invoice.view_all` | `sales.return.create`, `sales.payment.collect` | ✅ | ✅ | ✅ own | | ✅ | ✅ |
| **Customers** | `customers.customer.view` | `customers.customer.create`/`update`, `customers.ledger.view`, `customers.points.view`/`adjust` | ✅ | ✅ | ✅ | | ✅ | ✅ |
| **Products and stock** | `inventory.product.view` | `inventory.product.create`/`update`/`delete`, `inventory.adjust.create`, `inventory.stock.view` | ✅ | ✅ | ✅ view | ✅ | ✅ view | ✅ view |
| **Packages** | `inventory.package.view` | `inventory.package.manage` | ✅ | ✅ | ✅ view | ✅ | | ✅ view |
| **Catalogue** | `catalog.product.search` | `catalog.product.import`, `catalog.product.suggest` | ✅ | ✅ | ✅ view | ✅ | | ✅ view |
| **Suggestion approvals** | `catalog.suggestion.review` | — | ✅ | ✅ | | | | |
| **Purchase** | `purchase.bill.view` | `purchase.bill.create`, `purchase.supplier.manage` | ✅ | ✅ | | ✅ | ✅ view | ✅ view |
| **Accounts and expenses** | `accounts.account.view` | `accounts.expense.create`/`delete`, `accounts.transfer.create`, `accounts.account.manage`, `accounts.category.manage` | ✅ | ✅ | | | ✅ | ✅ view |
| **Reports** | any `report.*.view` | tabs: sales, profit, stock, dues, each by its own permission | ✅ | ✅ no profit | | ✅ stock | ✅ | ✅ |
| **Team and store settings** | `settings.store.view` | `settings.store.update`, `settings.branch.manage`, `settings.user.manage`, `settings.role.manage`, `settings.activity.view` | ✅ | ✅ no roles | | | | ✅ view |
| **Platform admin** | `admin.store.view` | `admin.store.create`/`update`/`impersonate`, `admin.suggestion.review`, `admin.catalog.manage` | Super Admin only | | | | | |

\* Cashier and stock keeper get a smaller dashboard: `GET /products/stats`
(low stock, expiring) and, for the cashier, their open shift from
`GET /pos/lookups`.

### What each role's app looks like

**Store Owner (দোকান মালিক).** The full app. Dashboard with today's sales,
profit and low stock. Sell, invoices with returns and due collection, customers
with credit and points, products and price changes, stock adjustments,
packages, catalogue with suggestion approvals, purchases, accounts, expenses and
transfers, every report, and team control (add, suspend, change role), branches,
and store settings including VAT and loyalty.

**Manager (ম্যানেজার).** Same as the owner except: no profit report or profit
column, cannot change anyone's role, and no deletes that the API offers today.

**Cashier (ক্যাশিয়ার).** A counter app. Open and close the cash drawer, sell
(scan or search, packages, walk-in or named customer, split payment, redeem
points), hold and resume carts, quick-add a customer by phone, view **own**
invoices and reprint, collect a customer's due. Sees stock quantities but no
costs. Cannot change prices or give discounts: the server ignores those fields.

**Stock Keeper (স্টক কিপার).** An inventory app. Products with cost, price
changes, stock adjustment and damage, stock history, low stock and expiry,
catalogue search and add-to-store, suggest new products, packages, purchase
entry (goods in), suppliers, and the stock report. No sales, no customers, no
money.

**Accountant (হিসাবরক্ষক).** A money app. Accounts and balances, record and
delete expenses (quick expense tiles), expense types, transfers between
accounts, all invoices, due collection, customer ledgers, purchases (view), and
every report including profit.

**Auditor (নিরীক্ষক).** The owner's screens, read-only. Hide every create, edit
and delete button. The server would refuse them anyway.

**Super Admin (সুপার অ্যাডমিন).** Everything above in any store, plus the
platform screen: all stores, create a store with its owner, suspend or
reactivate a store, enter a store for support, and approve product suggestions
into the shared catalogue.

---

## 5. Main processes, step by step

### 5.1 Counter sale (Cashier, Manager, Owner)

```
open drawer ─► load POS ─► scan/search ─► pick customer ─► checkout ─► receipt
 (once/shift)                                                       │
                                                                    ▼
                                                    close drawer at end of shift
```

1. **Open the cash drawer**: `POST /pos/shift/open` `{"openingCash": 2000}`.
   Do this once per shift. `GET /pos/lookups` → `shift` tells whether one is
   already open. A sale made without an open shift still goes through, but is
   not counted in any drawer.
2. **Load the POS**: `GET /pos/lookups` once, when the screen opens. It returns
   payment `accounts` (Cash Drawer, bKash, ...), the first 200 `customers`, this
   user's `held` carts, the open `shift`, `vatInclusive`, `allowCredit` and the
   `loyalty` settings.
3. **Find products**: `GET /pos/search?q=<text or barcode>`. For a scanner, an
   exact barcode match comes first, so add `data[0]` straight to the cart. Show
   `stock`, and warn when `qty > stock`: the server refuses overselling.
   For bundles: `GET /packages/sellable?q=`.

   **Nothing came back?** `POST /products` (§5.4) is the same door the Products
   screen uses, and the till should offer it right there rather than sending a
   cashier to another screen with a customer waiting. The workspace puts a **New
   product** button in front of the search box for whoever holds
   `inventory.product.create`. It asks for name, company, unit, barcode, cost,
   profit %, selling price, **wholesale**, **MRP** and quantity — everything
   that is a price. VAT, a minimum stock level and batch tracking are the only
   things left for later, because none of them changes what the customer pays.

   MRP is worth carrying over if you build your own: it is what the pack is
   printed with, so a selling price above it earns a warning and not a refusal,
   which is the same way the Products screen puts it. Wholesale left blank means
   the selling price stands.

   Two things to carry over if you build the same thing in the app. Selling below
   cost is refused, so check it on the form instead of letting the create succeed
   and the checkout fail. And `openingStock` decides whether the thing can be sold
   at all: created with none, it is a shelf entry with a stock of zero, and adding
   it to the cart will be refused. The workspace re-runs `/pos/search` after
   creating and adds the product from that reply, so it reaches the cart in exactly
   the shape every other product does.
4. **Customer** (optional): `GET /customers/search?q=0171` (2+ characters, phone
   first). Not found: `POST /customers/quick` `{"name": "...", "phone": "..."}`.
   If the phone already exists, it returns that customer with `created: false`.
5. **Checkout**: `POST /pos/checkout`.
6. **Receipt**: `GET /sales/{saleId}` has everything a receipt needs (store,
   branch, items, payments, totals). Print it on a Bluetooth printer in the
   app.
7. **Close the drawer**: `POST /pos/shift/close` `{"countedCash": 15230}`. The
   response gives `expected`, `counted` and `difference`.

   Show `GET /pos/shift/report` on the way in, so the cashier counts against a
   figure they can see rather than being told afterwards that it was short.

**The drawer's report, a day at a time.** A shift is not a day: a shop that opens
the drawer on Monday and never closes it has one shift with a week of takings in
it, so the window is the shift and the rows are days, newest first.

```json
{ "data": {
  "shift": { "id": 31, "openedAt": "..." },
  "openingCash": 2000, "cashTaken": 8450, "expected": 10450,
  "days": [ { "date": "2026-09-23", "invoices": 37, "sold": 9120,
              "cash": 8450, "digital": 500, "dueGiven": 170, "collected": 300 } ],
  "totals": { "invoices": 37, "sold": 9120, "cash": 8450, "digital": 500,
              "dueGiven": 170, "collected": 300 }
} }
```

With no shift open it answers for today instead, with `shift: null` — the screen
that asks for this is also where a drawer gets opened, and a blank panel tells a
cashier nothing about the morning they have already had.

| Field | Meaning |
|---|---|
| `cash`, `digital` | Taken at this counter that day, by how it was paid. Points are excluded: nothing was handed over for them |
| `dueGiven` | Put on the khata that day — what went out unpaid |
| `collected` | Money that arrived after its bill rather than with it, told apart by how it arrived and not by the date, since a bill written this morning and settled this afternoon is still a due being collected |
| `expected` | `openingCash + cashTaken`, the same arithmetic `/pos/shift/close` does, from the same query — the two cannot disagree |

**Counted by when the money arrived, not by which shift wrote the bill.** A due
collected during this shift against last week's invoice is cash in this drawer;
the old reckoning looked at sales belonging to the shift and missed every taka of
it. Both the report and the close now count payments in the shift's window, at
this branch, reached through the invoice they settle — payments carry no branch of
their own.

Cash paid *out* of the drawer (an expense recorded against the cash account) is
still not deducted from `expected`.

**Hold a cart**: `POST /pos/hold` `{"label": "Blue shirt man", "cart": {...any
JSON the app wants...}}`. **Resume**: `POST /pos/hold/{id}/resume` returns the
same `cart` JSON and deletes the hold. **Discard**: `DELETE /pos/hold/{id}`.
The server does not read `cart`; it stores it and gives it back.

### 5.2 Return (Manager, Owner)

1. `GET /sales?q=<invoice no or customer>` → `GET /sales/{id}` for its `items`.
2. `POST /sales/{id}/returns`:
   ```json
   { "items": [ { "saleItemId": 881, "qty": 1 } ], "reason": "Damaged pack" }
   ```
   Stock goes back up and the customer's balance goes down. Returning more than
   is left on a line fails with `422` and "Only N left to return on that line".

### 5.2b The khata: an old debt on today's bill

A shop's ledger does not work invoice by invoice. The customer comes in owing
500, buys 300 more, and is shown one figure: 800. What they hand over comes off
the whole of it, and whatever is left is on the front of the next bill.

1. `GET /customers/search?q=` returns `due` — everything that customer owes,
   the opening balance included. Show it beside the cart.
2. Send `collectPrevious: true` with the checkout, and tender against
   `total + due`.
3. The server fills this bill first, then walks the older debts oldest-first:
   the opening balance, then invoice by invoice through the same door
   `POST /sales/{id}/payments` uses. Nothing is double counted — the old debt
   still belongs to the bills that made it, and `previousDue` on the new invoice
   is a record, not a charge.
4. Whatever is still owed comes back as `outstanding`, and appears on the next
   bill as its `previousDue`. That is the "rest carries forward" part, and it
   needs no bookkeeping from the app.

To write a bill with nothing paid at all — the goods go out, the whole amount
onto the khata — post the checkout with `payments: []` and a `customerId`. No
payment screen is involved.

### 5.3 Collect a due (Cashier, Accountant, Manager, Owner)

1. Who owes: `GET /reports/dues` (needs `report.due.view`), or from a customer:
   `GET /sales?q=<phone>` and filter `due > 0`.
2. `POST /sales/{id}/payments` `{"amount": 500, "method": "bkash", "accountId": 2}`.
   More than the due fails: `422 over_payment`.

### 5.4 Goods in / purchase (Stock Keeper, Manager, Owner)

1. **The party**: `GET /suppliers/search?q=rah` while the user types — it
   matches name, company and phone, and is what the suggestion list under the
   box should show. `GET /purchases` also carries the whole list in
   `meta.suppliers`.
2. Pick products: `GET /purchases/products?q=`. A product not in the store yet:
   add it from the catalogue first (5.6).
3. `POST /purchases`:
   ```json
   {
     "supplierId": 3,
     "items": [
       { "storeProductId": 42, "qty": 100, "unitCost": 78.5, "batchNo": "B2291", "expiryDate": "2027-06-30" }
     ],
     "discountPercent": 5,
     "paidAmount": 5000,
     "accountId": 1,
     "note": "Invoice #7781"
   }
   ```
   Stock rises, the rest is owed to the supplier, and `paidAmount` leaves
   `accountId`.

   **A party the shop has not saved yet** goes up as `supplierName` instead of
   `supplierId`, and is saved with the bill — so the next bill from the same
   man is a pick off the list. A name that already exists, spelt the same apart
   from case and spacing, joins that party rather than creating a second one.
   It needs `purchase.supplier.manage`; without it, send a `supplierId` and
   the reply is `403 supplier_create_denied`.

   **`discountPercent`** (0–100) is a rate on the whole bill. The server works
   out the taka and returns both: `subtotal`, `discount`, `total`. Send
   `discount` instead to give the figure directly; when both arrive the rate
   wins. The reply carries `supplierId`, whichever way the party arrived.
4. **The bill as a photograph** — what a shopkeeper actually has when the paper
   is still with the supplier, usually a WhatsApp forward. Once the purchase
   exists, `POST /purchases/{id}/photos` as `multipart/form-data` with one or
   more `photos[]` parts. JPEG, PNG, WebP or HEIC, 8 MB each, five per bill.
   `meta.accepted` says how many went up, `meta.remaining` how much room is
   left. `GET /purchases` returns them per bill as `photos[] {id, url, name}`.
   Remove one with `DELETE /purchases/{id}/photos/{photoId}`
   (`purchase.bill.update`).

   Save the bill first and upload after: a purchase is stock and money, and a
   dropped upload should not cost the shop that. A failed upload is worth
   telling the user about and offering again — the bill is already correct.

### 5.5 Changing a product: prices, and whether it sells at all

- Count correction or damage: `POST /products/{id}/adjust`
  `{"qty": -3, "reason": "Broken in transit", "isDamage": true}`. `qty` is
  signed: `+` adds, `-` removes, and it cannot be 0.
- History: `GET /products/{id}/history`.
- Alerts: `GET /products/stats` (low stock, expiring in 90 days, stock value).

#### One edit, prices included

`PATCH /products/{id}` takes the details **and** the prices. There used to be two
calls and, in the workspace, two buttons on every row — one for the name and one
for the price — and nobody could say why correcting a spelling and correcting a
price were two separate errands. They are one form now, and one request:

```json
{ "name": "Napa 500mg", "mrp": 12,
  "purchasePrice": 8.5, "salePrice": 10, "wholesalePrice": 9.5, "profitPercent": 17.65 }
```

The prices arrive **as a set**: send one and all three are required. The selling
price must be at least the cost, which is the one rule this shop does not bend on,
and the check cannot be made with the cost missing. `profitPercent` is the rate the
shop stated, or `null` where it simply named a price.

Changing a price files the old one with an `effective_to`, so profit on an invoice
from six months ago is still worked out against what the thing cost six months ago.
The reply's `repriced` says whether a new price period was opened; saving a form
without touching a price does not open one.

`PATCH /products/{id}/prices` still exists and does only the prices. Either is fine;
the merged one is a single round trip.

#### Stopping a product without deleting it

```
PATCH /products/{id}   {"isActive": false}
```

A line the shop has stopped carrying is not a mistake to be deleted. `isActive:
false` keeps the product, its stock and every invoice it ever appeared on, and
stops the till offering it: `GET /pos/search` returns active products only. It is
still on `GET /products`, where the workspace strikes it through, and
`isActive: true` puts it back.

Send it on its own. No prices beside it, or the all-or-nothing rule above applies
to a request that has no business naming a price.

Three states, and they are not the same thing:

| | on `/pos/search` | on `/products` | stock kept | history kept |
|---|---|---|---|---|
| active | yes | yes | yes | yes |
| `isActive: false` | × | yes, struck through | yes | yes |
| `DELETE /products/{id}` | × | only with `?trashed=1` | yes | yes |

Deleting is a soft delete and `POST /products/{id}/restore` undoes it. Use it for a
product that should not have been created; use `isActive` for one the shop has
simply stopped selling.

### 5.6 Adding a product (Stock Keeper, Manager, Owner)

Products come from the shared catalogue. A store does not type them in freely.

```
search catalogue ──found──► adopt (add to my store with my prices)
      │
   not found
      ▼
check name ──"exists"──► adopt that one instead
      │ new / variant
      ▼
suggest ──(submitter holds catalog.suggestion.review)──► product created now
      │ otherwise
      ▼
owner/manager approves in Suggestions ──► product created in this store
      ▼
super admin approves ──► added to the shared catalogue for every store
```

1. `GET /catalog?q=napa`. The list is always the store's own store type. If
   `alreadyInStore` is set, it holds this store's product ID.
   `GET /catalog?missing=1` is the other way round — what this kind of shop
   sells that this shop does not, which is the list to shop from. Either way
   `meta.missingCount` is the size of that gap, and it ignores `q`.
2. Found: `POST /catalog/{id}/adopt`
   `{"purchasePrice": 1.0, "salePrice": 1.2, "mrp": 1.5, "openingStock": 200, "minimumStock": 20}`.
   Leave `openingStock` out here and the product arrives with **1** on the
   shelf — adopting is the shop saying it already carries the thing. Typing a
   product in (`POST /products`) is the other case and defaults to **0**.

   **`mrp`** is the price printed on the pack. The form should offer the row's
   `defaultMrp` so the shopkeeper only corrects it. Left out, the catalogue's
   `defaultMrp` is kept; if the catalogue has none either, the selling price
   stands in — a slip showing a saving of the whole price would be a lie. The
   counter's "saved off MRP" line and an invoice's `mrpSaving` are worked out
   from this, so a shop that skips it simply shows no saving.
3. Not found: `GET /catalog/check?name=Monas 50&brand=ACI` while the user
   types. `verdict` is `exists`, `variant`, `other_brand`, `similar` or `new`.
4. `POST /catalog/suggestions` with name, prices and so on. An exact duplicate
   returns `409 already_in_catalog` with `error.match` and `alreadyInStore`.
   To go ahead anyway, resend with `"confirmedNew": true`. If the response has
   `endorsed: true`, the product is already on sale (`storeProductId`) and
   shows on the store’s own `GET /catalog` marked `pending`.
5. Owner or manager: `GET /catalog/suggestions`, then
   `POST /catalog/suggestions/{id}/review` `{"approve": true}` (with optional
   corrected fields) or `{"approve": false, "note": "..."}`.

### 5.7 Expenses and money (Accountant, Manager, Owner)

- Screen: `GET /accounts` returns accounts with balances, recent expenses,
  transactions, categories, `quick` tiles, and today's and this month's expense
  totals.
- One-tap expense from a quick tile: `POST /expenses` `{"categoryId": 5}`. The
  amount comes from the type's `defaultAmount`, and the account defaults to the
  cash drawer.
- Normal: `POST /expenses` `{"categoryId": 5, "amount": 350, "accountId": 1, "note": "Tea"}`
  or `{"categoryName": "Van rent", "amount": 1200}`, which creates the type.
  `date` (`YYYY-MM-DD`) records money that left on an earlier day.
- **Salary**: an expense type with `isSalary: true` — every store has one
  called Salary — asks for two more facts, and the form should show them only
  for such a type:
  `POST /expenses` `{"categoryId": 9, "amount": 12000, "employeeName": "Karim Uddin", "salaryMonth": "2026-08"}`.
  `employeeName` is a name, not a user id: a shop hand with no login still
  gets paid. It is required for a salary type (`422 employee_required`) and
  ignored elsewhere. `salaryMonth` is the month it covers, which is not the
  day it was paid — August's salary handed over in September is the normal
  case. `GET /accounts` returns `employees[]` (every name paid before, for
  the suggestion list) and `monthSalary`; each expense row carries
  `employeeName`, `salaryMonth` and `isSalary`.
- A quick tile cannot post a salary in one tap — there is nobody's name on a
  button — so open the form with the type already chosen instead.
- Mistake: `DELETE /expenses/{id}`. The money goes back into the account.
- Bank deposit: `POST /accounts/transfer` `{"fromAccountId": 1, "toAccountId": 3, "amount": 20000}`.

### 5.8 Owner's dashboard and reports

**`GET /dashboard?range=7d` is the whole screen in one call.** Every figure in
it exists somewhere else — sales has the invoices, accounts has the expenses,
products has the stock — and what none of them has is each other. An owner asking
"how did this week go" is asking one question whose answer is spread over six
pages.

Ranges: `today`, `yesterday`, `7d`, `15d`, `1m`, `2m`, or
`custom&from=&to=`. A window is **62 days at most**; a longer custom one is
trimmed and `range.capped` says so. Needs `report.sales.view`.

| Section | What it answers |
|---|---|
| `headline` | `revenue, invoices, averageSale, discountGiven, dueRaised, returned, expenses, grossProfit, netProfit` — profit only with `report.profit.view` |
| `capital` | Where the money is standing **right now**, not between dates: `stock` at cost, `receivable`, `inAccounts`, `invested`, `payable`, `net`, and each account's balance |
| `daily` | One row per day: `sales`, `invoices`, `expenses` — the trend line |
| `payments` | How the bills written in this window were settled, by method |
| `collections` | Money that **arrived** in this window, whatever it settled: `total`, `onSales`, `onDues`, `onPreviousDue`, `byMethod`. Not the same question as `payments` |
| `topProducts` | Best ten by revenue, with profit where allowed |
| `movers` | This window against the one of the same length before it, per product: `rising`, `falling`, and `restock` — see below |
| `staff` | Per cashier: `invoices, revenue, discount, dueRaised, averageSale, profit` |
| `orders` | The invoices themselves, latest 30 |
| `dues` | `receivableTotal`, `payableTotal`, top 20 `customers` and `suppliers` |
| `expenses` | `total`, `byCategory[]` (type-wise), and the latest 50 rows |
| `purchases` | `total`, `due`, `count`, and the latest 30 bills with `paid` and `due` |
| `stock` | `value` at cost, `units`, `outOfStock`, `low[]`, `expiring[]` |
| `shifts` | The last 15 drawers: `openingCash`, `expected`, `counted`, `difference`, `sold` |

A section the caller may not see comes back **`null` rather than missing**, so
the app can say "you do not have this" instead of quietly showing a shorter
dashboard that looks complete. `meta` carries `mayProfit, mayStock, mayDues,
mayMoney, mayInvoices, mayPurchase`.

#### `movers`: what to buy, and what to stop buying

A product's sales mean nothing on their own and everything next to what they
were, so this compares the window with the one of the same length immediately
before it (`movers.previous` gives those dates).

| List | Use it for |
|---|---|
| `rising` | Climbing more than 10%, or `new` — what to keep on the shelf |
| `falling` | Down more than 10%, or `stopped` — money sitting still |
| `restock` | Selling, and the shelf runs out inside 7 days at that rate. The only list with a deadline on it. `null` without stock permission |

Each row carries `qty`, `wasQty`, `revenue`, `wasRevenue`, `changePercent`
(null when there is no earlier figure to compare against — new, not infinitely
up), `verdict` (`rising`, `new`, `steady`, `falling`, `stopped`), `perDay`,
`onHand` and `daysCover`.

`perDay` and `daysCover` are what turn "selling well" into "order more on
Thursday", which is the only form of this answer anybody can act on.

#### Building a dashboard from the report endpoints instead

| Tile | Call | Field |
|---|---|---|
| Today's sales | `GET /reports/sales?days=1` | `daily[0].total`, `daily[0].count` |
| Today's payments by method | same | `byMethod` |
| Profit, last 30 days | `GET /reports/profit?days=30` | `grossProfit`, `netProfit`, `margin` |
| Sales chart | `GET /reports/sales?days=30` | `daily[]` |
| Top products | same | `topProducts` |
| Sales by staff | same | `byUser` |
| Low stock, expiring | `GET /products/stats` | `lowCount`, `low`, `expiringCount`, `expiring` |
| Money owed to the shop | `GET /reports/dues` | sum of `due` |
| Today's expenses | `GET /accounts` | `todayExpense` |

Sales and stock reports, and profit's revenue and cost, are for the **current
branch**. For another branch, switch branch first.

### 5.8b One shop, one database

Worth reading if you are building against this, though the short version is that
**nothing here changes**. The app asks for `/products` and gets that store's
products whichever database answered; which one did is the server's business.

#### What is central and what is not

| Central, always | The shop's own, once it has moved |
|---|---|
| `users`, `stores`, `plans`, `store_types` | the shelf: `store_products`, prices, stock, batches |
| `store_users`, `store_user_branches`, `branches` | the till: `sales`, `sale_items`, payments, returns, shifts |
| the shared catalogue: `global_products`, `brands`, `units` | buying: `purchases`, `suppliers`, their ledgers |
| `product_suggestions`, `subscriptions`, `activity_logs` | `customers` and their ledgers, `accounts`, `expenses`, `taxes` |
| roles and permissions | the shop's settings, print templates, workspace tabs |

`config/tenancy.php` is the authoritative list and the only one. Two questions
decide the side: **is it read before a shop has been chosen** — signing in,
listing your shops, picking a branch — and **does the platform read it across
every shop at once**. Either yes keeps a table central. Everything else, the
shop's own trading, moves.

Membership is the clearest case. `store_users` says which shop a request is for,
so it cannot live inside the thing it grants access to, or the server would have
to know which database to open in order to find out which database to open.

#### A new shop is born in its own database

There is nothing to migrate about a shop that does not exist yet, so a shop created
from now on is not started centrally and moved later. Provisioning does it in three
steps: the shop's identity centrally and atomically, then its own database and the
tables in it, then the cash drawer and the walk-in customer written straight into
that database as its first rows.

`POST /admin/stores` says which happened, in `dbName`, `dbCreated`, `dbMigrated`,
`dbProblem` and `dbDetail`. It cannot fail over this: if the server will not make
the database — no `CREATE` grant, a driver with no second database — the shop
is left on the central tables, works exactly as every shop did before the split,
and says why.

If a new shop did not get one, do not guess:

```
php artisan tenancy:status
```

It is read-only and asks the five things it is ever going to be: whether the driver
can hold a database per shop, whether the migrations have run, whether the MySQL
user may `CREATE DATABASE`, whether `tenancy.new_stores_own_database` is on, and
what each existing shop actually looks like — database named, database present,
how many of its tables exist, and where it is being served from.

```
php artisan tenancy:status --store=7
```

adds the question "I created a product and it is not on the list, where did it go?"
It counts that shop's rows on **both** sides, table by table. Rows in its own
database and none central is working as intended; rows central while the shop is
served from its own are invisible to it; rows in neither means the write failed.

#### What a shop's database is called

The central database, then the shop's own name. A platform whose `DB_DATABASE` is
`bizpos_laravel` gives Rahman Pharmacy `bizpos_laravel_rahman_pharmacy`, so the
shops sort next to the central database in any list and each one says whose it is.

The id is appended only when it has to be: two shops with the same name, or a name
with nothing usable left once it is reduced to the characters a database name may
contain — which is what a wholly Bangla name comes to, and that is not unusual
here, so it falls back to `..._store_47` rather than failing.

Set `TENANCY_DATABASE_PREFIX` only for a shared host that insists on a prefix of
its own on every database a user owns.

The name is worked out **once**, when the shop is created, and stored in
`stores.db_name`. Nothing recomputes it, and that is what makes naming a database
after a changeable thing safe: rename the shop next year and its database keeps the
name it was born with, still pointing at the right data. A shop that has already
moved is never renamed by anything — its rows are in there under that name, and
MySQL has no `RENAME DATABASE`.

#### The shops that were here first

`stores.db_migrated_at` is the switch, and it is per shop. Null means central, byte
for byte the behaviour this platform has always had. A date means that shop is
served from its own database. Both kinds are served side by side, indefinitely:

```
php artisan stores:move --all        # every shop still on the central tables
php artisan stores:move 7 --dry-run  # or one at a time: what would be copied
php artisan stores:move 7
php artisan stores:move 7 --rollback
php artisan stores:databases         # only makes the databases, copies nothing
```

`--all` still does one shop at a time and stops at the first that does not add up.
Nothing is destroyed by then and the shops already moved stay moved, so the fix is
to deal with that one shop and run it again — it skips what is done. A shop that
has not moved has its database name brought in line first, which is what lets the
shops recorded as `bizpos_store_3`, from before names were the shops' own, become
`bizpos_laravel_karim_store` for nothing.

The mover stops at the first thing that does not add up, and **sets
`db_migrated_at` last**. Before that it makes the tables (from the central ones,
with the foreign keys that stay inside a shop), checks the two schemas agree,
copies the rows with their ids, and counts every table on both sides. A mismatch
anywhere means the shop is not switched over and nothing was destroyed.

Nothing is deleted centrally. Those rows go inert the moment the switch flips, and
they stay so that `--rollback` is a column going back to null rather than a
restore from last night's backup. The one thing rollback cannot recover is trading
that happened while the shop was split — that is in the shop's database and the
central tables never saw it, so rollback is for the hour after a move, not the
week after.

#### After every migrate

A migration is still written once, centrally. Carrying it out to the shops that
have moved is one more step, and it belongs in the deploy script:

```
php artisan migrate
php artisan stores:schema           # add new columns and keys to every moved shop
php artisan stores:schema --check   # or just report what differs
```

It only ever adds — tables, columns, intra-shop foreign keys. A column whose type
changed, or one that went away, is named and left for a person, because doing
either of those to two hundred databases unattended is how data is lost.

#### The two things the split really costs

**Cross-shop counts.** "How many sales has the platform taken" has no single table
to count any more. `StoreRollup` gathers it — one grouped query for the shops still
central, one cached visit each to the shops that have moved. Figures like this on
platform screens may be up to five minutes stale, by design.

**`store_catalog_links`.** A central, three-column index of which shop stocks which
catalogue product. It exists because the two questions the catalogue is *for* used
to be answered with a subquery across the boundary: "which catalogue products am I
not stocking" (the **Not in my store** tab) and "how many shops stock this one"
(the platform's catalogue list). `EXISTS` does not cross databases, and fanning a
count out over two hundred schemas to draw twenty-five rows is an outage, not a
query.

It is an index, never the truth — `store_products` remains that. The shelf keeps it
up to date as products are saved and deleted, and `php artisan stores:reindex`
rebuilds it from the shelves if it ever drifts, which it can: once a shop has moved,
the shelf write and the index write are two transactions rather than one. Nothing
reads the index to answer a question about one shop's own shelf, so a missing row
understates a platform count and breaks nothing. Worth a nightly schedule.

#### Joins that cross

A shop's database and the central one are two schemas on one server, reached on one
connection, so MySQL joins them quite happily as long as the name is qualified.
Six places do, all for the same reason — a cashier's name from `users` beside the
takings they rang up, a branch name beside a batch. They go through
`Tenancy::central()`, which returns the bare table name while a shop is central and
`` `db`.`table` `` once it has moved, and which refuses any table not listed in
`tenancy.joinable_central`.

What a shop's database does **not** have is a foreign key pointing at a central
table. `store_products.global_product_id` is a plain column there; a constraint
cannot cross schemas. Intra-shop keys — `sale_items.sale_id` and the rest — are
read out of the central schema and put back on, cascade rules and all, so a shop's
database keeps every guarantee it can still keep.

#### If the host cannot do it

A MySQL user without `CREATE DATABASE`, or a `sqlite` connection, is not an error.
The shop is provisioned exactly as before, `POST /admin/stores` reports it in
`dbProblem` (`create_failed`), and the platform carries on centrally — which is
where everything still is, and where it all works.

**On a server you control**, one grant is the whole fix:

```sql
GRANT ALL PRIVILEGES ON `bizpos\_laravel\_%`.* TO 'youruser'@'localhost';
GRANT CREATE ON *.* TO 'youruser'@'localhost';
```

**On cPanel** — which is most shared hosting — no grant will ever fix it. A cPanel
MySQL user is not permitted to run `CREATE DATABASE` at all, by design: databases
are made through cPanel, under the account prefix, and the user is then attached to
them. So the databases are made by hand, once per shop:

1. `php artisan stores:databases` — it will fail to create anything, and print the
   name each shop wants.
2. Make those databases in **cPanel → MySQL Databases**.
3. Add the app's MySQL user to each one, with **ALL PRIVILEGES**. Existing is not
   the same as usable, and the two look identical until the first write.
4. `php artisan stores:move --all`.

Set `TENANCY_DATABASE_PREFIX` to your cPanel account prefix and the names printed in
step 1 are already the ones cPanel will let you create, so nothing has to be
reconciled. Where a name still comes out different — cPanel caps the length —
point the shop at what you actually made:

```
php artisan stores:databases --store=7 --name=acct_shop7
```

That records the name and nothing else, after checking the database is there **and**
that this user can write to it. Moving the data is still `stores:move`.

Worth being plain about the trade: on cPanel, one database per shop means a manual
step for every new shop. A platform signing up shops from the app will want either
a VPS, where provisioning does it unattended, or to leave
`TENANCY_NEW_STORES_OWN_DATABASE=false` and run everything centrally — which is a
perfectly good answer for a few dozen shops, and the one this application was built
to work under.

#### One consequence for anybody reading the code

`->withoutGlobalScope('store')` used to mean "every shop on the platform". For a
shop that has moved it now means "every row in that shop's database", which is that
one shop. Platform code that genuinely wants every shop walks the stores —
`Tenancy::forStore()` and `StoreRollup` are how.

And every model whose table is listed under `tenant` must carry either
`BelongsToStore` or, for a child table with no `store_id` of its own,
`OnShopConnection`. A model with neither answers "the default connection" and so
reads and writes centrally while the rest of its shop is elsewhere — silently, and
in both directions: twelve child models once had neither, so `SaleItem::create()`
wrote to the central database while its sale went to the shop's, and Eloquent's own
`newRelatedInstance()` was papering over it by handing central models like `Brand`
the `tenant` connection, which asked a shop's database for the shared brands table.
`node tests/tenancy.mjs` checks that none has been missed, because neither half
shows up as an error anywhere near its cause.

### 5.9 Team control (Owner, Manager)

- `GET /settings` returns `members`, `roles`, `branches`, store `settings`,
  `loyalty`, and the `meta.may*` flags.
- Add staff: `POST /settings/members`
  `{"name": "Rafi", "email": "rafi@shop.com", "password": "secret1", "roleId": 4, "branchId": 1}`.
  The plan's user limit applies (`422 plan_limit`).
- Suspend or reactivate: `PATCH /settings/members/{storeUserId}/status`
  `{"active": false}`. Use `storeUserId`, not the user `id`. A suspended person
  gets 400 or "no store" on their next call.
- Change role (owner): `PATCH /settings/members/{userId}/role` `{"roleId": 3}`.
  Here it is the user `id`.
- Who changed what: `GET /settings/activity?days=7&subject=StoreProduct`.

### 5.10 Platform control (Super Admin)

- `GET /admin/overview` returns all stores with counts, store types, plans,
  pending suggestions and totals.
- Create a store: `POST /admin/stores`. It creates the owner account, the main
  branch, cash and bKash accounts, a walk-in customer and default settings — and
  the shop's own database, with its tables, and it is served from there straight
  away — `dbName`, `dbCreated`, `dbMigrated`, `dbProblem`, `dbDetail` say what
  happened. See §5.8b, and `php artisan tenancy:status` if it did not.

  **`phone` is required**, at this door and at every other one a shop is created
  at: the public sign-up, and an owner opening a second shop from inside. It is how
  the platform reaches a shop it has to talk to about its own trial, and how the
  same shop signing up twice is recognised as one shop. `PATCH /admin/stores/{id}`
  will not accept an empty one either — a field every door demands cannot be
  cleared on the next screen.

  Shops created before this was required may still have an empty number, and the
  column stays nullable so nothing existing breaks. They are filled in as they are
  next edited; to find them:

  ```sql
  SELECT id, name FROM stores WHERE phone IS NULL OR phone = '';
  ```
- Suspend: `PATCH /admin/stores/{id}/status` `{"status": "suspended"}`. Nobody
  can sign in to a suspended store; nothing in it is deleted.
- **Let a self-signed-up shop carry on**: `POST /admin/stores/{id}/extend`
  `{"days": 30}` pushes the clock out — from the current end date when it has
  not passed, from today when it has, so an extension never shortens anything.
  `{"unlimited": true}` takes the clock off for a shop that has started paying.
  Either way the store is switched back on unless you pass `activate: false`,
  because "continue this shop" is one decision and making an admin remember two
  calls for it is how a shop ends up with a future date and a locked door.
  Returns `{id, status, trialEndsAt, trialDaysLeft, locked}`.
- `GET /admin/overview` rows carry `trialEndsAt`, `trialDaysLeft` and `locked`,
  so the shops about to stop are visible without opening each one. They also
  carry `storeTypeId`, `planId`, `phone`, `email`, `address`, `city`,
  `currency` and `timezone`, which is what an edit form fills itself from —
  plus `dbName`, `dbReady` and `dbMigratedAt` — whether the server has made the
  shop's database, and whether the shop is actually being served from it. A shop
  with a database and no `dbMigratedAt` is the normal state before it is moved.
- **Correct any shop's details**: `PATCH /admin/stores/{id}`, every field
  optional. A shop's own owner can edit most of this in Settings, but only for
  the shop they are inside.

  Three things are deliberately not editable. The **slug** and **`db_name`** are
  how a shop is identified for as long as it exists, and a rename must not move
  either — a shop called something else next year must still point at its own
  data. The **trial** has its own action, because letting a shop carry on is a
  decision rather than a detail.

  Changing `storeTypeId` changes which shared catalogue the shop reads, so the
  reply says `storeTypeChanged: true` when it did. It is allowed rather than
  refused — the platform is often fixing a shop that was set up as the wrong kind
  on its first day — but a shop turned from pharmacy to grocery keeps products it
  can no longer find in the catalogue.
- Support: `POST /admin/stores/{id}/impersonate` moves **this device** into that
  store (logged). Then call `GET /me`. To leave, `POST /auth/switch-store` back.
- Shared catalogue: `POST /admin/suggestions/{id}/review` `{"approve": true}`.

---

## 6. Endpoint reference

Every path is relative to `/api/v1`. **Perm** is the permission the server
checks. `—` means any signed-in user.

### Auth and session

| Method | Path | Perm | Body / query | Returns |
|---|---|---|---|---|
| POST | `/auth/login` | none | `email`, `password`, `deviceName?` | `token`, `tokenType`, `expiresAt`, `user`, `stores[]`; `403 trial_ended` / `store_suspended` |
| POST | `/auth/register` | none | `name`, `storeTypeId`, `ownerName`, `email`, `phone`, `password`, `address?`, `branchName?`, `deviceName?` | `201` with a working `token`, the new `store` and its trial; `409 already_registered`. Throttled 5/hour |
| GET | `/public/store-types` | none | | `storeTypes[]`, `plans[]`, `trialDays` |
| GET | `/stores` | — | | the shops this account may work in, `meta.locked` |
| POST | `/stores` | — | `name`, `storeTypeId`, `phone`; `address?`, `branchName?` | `201` the new store and its trial; `409 duplicate_store` |
| POST | `/auth/logout` | — | | `ok` |
| GET | `/auth/devices` | — | | list of devices |
| DELETE | `/auth/devices/{id}` | — | | `ok` |
| POST | `/auth/switch-store` | — | `storeId` | `storeId` |
| POST | `/auth/switch-branch` | — | `branchId` | `storeId`, `branchId` |
| GET | `/me` | — | | see [section 2](#get-me--who-am-i-where-am-i-what-may-i-do) |
| PATCH | `/me/preferences` | — | `locale?`, `theme?` | `locale`, `theme` |
| GET | `/public/permissions` | none | | `modules`, `roles` |
| GET | `/palette?q=` | — | `q` (2+ characters) | global search across products, invoices and customers, filtered by permission |

### POS

#### `GET /pos/lookups` — `pos.sale.create`

```json
{
  "data": {
    "accounts":  [ { "id": 1, "name": "Cash Drawer", "type": "cash", "isDefault": true } ],
    "customers": [ { "id": 1, "name": "Walk-in Customer", "phone": null, "isWalkIn": true, "creditLimit": 0 } ],
    "held":      [ { "id": 9, "label": "Blue shirt", "createdAt": "..." } ],
    "shift":     { "id": 31, "openingCash": 2000, "openedAt": "..." },
    "vatInclusive": false,
    "allowCredit": true,
    "loyalty": {
      "loyalty_enabled": true, "loyalty_earn_per": 100, "loyalty_earn_points": 1,
      "loyalty_value_per": 1, "loyalty_min_redeem": 50, "loyalty_max_redeem_pct": 50,
      "loyalty_round": "down", "mayRedeem": true
    }
  }
}
```

`shift` is `null` when no drawer is open.

#### `GET /pos/search?q=&limit=30` — `pos.sale.create`

Active products of the store, with this branch's stock. `q` matches the name,
the barcode, the store's own SKU, the company that makes it and the generic
name — the same five ways in everywhere a product is searched for, so typing a
company name brings up that company's products. An exact barcode still sorts
first, because a scanner should never make a cashier choose.

```json
{ "data": [ {
  "id": 42, "name": "Napa 500mg", "barcode": "8941100500015", "unit": "pc", "brand": "Beximco",
  "salePrice": 1.2, "purchasePrice": null, "wholesalePrice": 1.1, "vatPercent": 0,
  "minimumStock": 20, "trackBatch": false, "stock": 4209
} ] }
```

#### `POST /pos/checkout` — `pos.sale.create`

```json
{
  "customerId": 12,
  "lines": [
    { "storeProductId": 42, "qty": 10 },
    { "storeProductId": 57, "qty": 1, "unitPrice": 95, "discount": 5 },
    { "packageId": 3, "qty": 1 }
  ],
  "payments": [
    { "method": "cash",  "amount": 100, "accountId": 1 },
    { "method": "bkash", "amount": 50,  "accountId": 2, "reference": "TXN8FK2" }
  ],
  "orderDiscountPercent": 10,
  "redeemPoints": 50,
  "note": "Delivered"
}
```

| Field | Rule |
|---|---|
| `lines[]` | Required, 1 or more. Each has **either** `storeProductId` **or** `packageId`, plus `qty > 0` |
| `lines[].unitPrice` | Used only with `pos.sale.change_price`, otherwise the store price is charged |
| `lines[].discount`, `orderDiscount`, `orderDiscountPercent` | Used only with `pos.sale.give_discount` |
| `orderDiscountPercent` | 0–100, and **this is what the till sends**. A discount on the bill is a rate: "ten percent off" survives the basket changing under it, a flat figure does not. The server works the taka out off the goods total **after** the line discounts, so what the cashier was shown and what is stored cannot drift. Kept on the invoice as `discountPercent` |
| `orderDiscount` | A flat figure, for an import or a bill settled by hand. When both are sent the rate wins, and a sale made this way records no `discountPercent` |
| `payments[].method` | `cash`, `card`, `bkash`, `nagad`, `rocket` or `bank`. **Do not send `credit` or `points`.** To leave a due, pay less; to use points, send `redeemPoints` |
| `payments[].accountId` | Send it (from `lookups.accounts`) so the money lands in that account's balance |
| `customerId` | Required when anything is left due, or points are redeemed or earned. Walk-in customers cannot buy on credit |
| `redeemPoints` | Needs `pos.sale.redeem_points` and a named customer. The server caps it at what is allowed (minimum points, maximum % of bill) |
| `collectPrevious` | `true` when the counter is asking for the customer's old debt along with today's goods. Anything tendered past this bill's own total then settles the older debts, oldest first; without it, the same over-tender is change |

**How much came with it is the only question.** There is no payment "mode" to
choose: the amount tendered already says what kind of sale this is.

| The counter does | What goes up | What comes back |
|---|---|---|
| Takes the lot | `payments` totalling the bill | `due: 0`, `paymentStatus: "paid"` |
| Takes part of it | `payments` totalling less, plus `customerId` | `due` is the rest, `paymentStatus: "partial"` |
| Takes nothing | `payments: []`, plus `customerId` | `due` is the whole bill, `paymentStatus: "unpaid"` |

Anything left owing needs a named customer; a sale paid in full needs none.

**Tender beyond the bill is split by the server, not the client.** A payment
row is never written for more than the invoice came to: the excess settles the
older debts when `collectPrevious` is set, and is change otherwise. So send the
figure the cashier typed and let the server decide what it was for — which also
means a shift's cash total is what stayed in the drawer, not what passed
through it.

The invoice records what the customer owed before it as `previousDue`, and the
reply carries `outstanding`: everything they owe now that this bill and any
payment have both landed. That second figure is what the next bill will print as
its previous due.

The server works out prices, VAT and totals. **Never trust the app's own
total**: show the `total` from the response. `201`:

```json
{ "data": { "saleId": 5521, "invoiceNo": "INV-005521", "total": 139.5, "paid": 139.5, "due": 0,
            "paymentStatus": "paid", "pointsEarned": 1, "pointsRedeemed": 50 } }
```

`paymentStatus` is `paid`, `partial` or `unpaid`. Refusals are `422` with code
`insufficient_stock` ("Not enough stock for Napa 500mg (4 left)") or `sale`
(for example "A due amount needs a named customer", "Credit sales are turned off
for this store", "Walk-in customers cannot buy on credit", a credit limit
exceeded, "Points need a named customer").

**Nothing goes out below what it cost.** A sale is refused with `sale` when a
line's price, after its own discount, is under the product's `purchasePrice`
("Napa 500mg cannot be sold below what it cost"), or when the bill discount
takes the whole basket under the cost of its goods ("That discount takes the
bill below what the goods cost"). All three ways of getting there are
covered — a price typed over the shelf price, a line discount and a bill
discount — so the app should disable its own pay button rather than let a
cashier take money and then be refused.

A bundle is judged as a bundle: its price is split across its products, and one
of them being under its own cost is the ordinary shape of a bundle, so what has
to cover the costs is the sum. A product with no cost recorded is skipped, since
there is nothing to compare it against. The messages name no figures, because a
cashier may hold `pos.sale.create` without `inventory.product.view_cost`.

#### Held carts — `pos.sale.hold`

| Method | Path | Body | Returns |
|---|---|---|---|
| POST | `/pos/hold` | `label` (max 80), `cart` (any JSON object) | `201 {id}` |
| POST | `/pos/hold/{id}/resume` | | the `cart` JSON. The hold is deleted |
| DELETE | `/pos/hold/{id}` | | `ok` |

Holds are per user and per branch.

#### Cash drawer — `pos.shift.manage`

| Method | Path | Body | Returns / errors |
|---|---|---|---|
| GET | `/pos/shift/report` | | `shift, openingCash, cashTaken, expected, days[], totals` — see below |
| POST | `/pos/shift/open` | `openingCash` | `201 ok`; `422 shift_open` if one is open |
| POST | `/pos/shift/close` | `countedCash`, `note?` | `expected`, `counted`, `difference`; `422 no_shift` |

### Sales

#### `GET /sales` — `sales.invoice.view` (own) or `sales.invoice.view_all`

Query: `q` (invoice no, customer name or phone), `days` (e.g. `1` = today,
`7`; `0` or absent = all), `page`, `perPage`. Current branch.

```json
{
  "data": [ { "id": 5521, "invoiceNo": "INV-005521", "saleDate": "...",
              "subtotal": 155.0, "discount": 15.5, "discountPercent": 10, "discountRate": 10, "vat": 0,
              "total": 139.5, "paid": 139.5, "due": 0, "previousDue": 500.0,
              "paymentStatus": "paid", "status": "completed", "customer": "Rahim", "seller": "Karim",
              "branch": "Main Branch", "itemCount": 3 } ],
  "meta": { "total": 1778, "page": 1, "perPage": 25,
            "summary": { "count": 1778, "goods": 986000, "discount": 61154.5, "vat": 0,
                         "total": 912345.5, "paid": 899845.5, "due": 12500 },
            "seeAll": true, "mayReturn": true, "mayCollect": true }
}
```

`status` is `completed`, `returned` or `void`.

`previousDue` is what the customer owed when the bill was written — the khata
the bill was written into, not part of its total.

The row carries the whole arithmetic of the bill, so a list can be read without
opening every invoice: `subtotal` is the goods before anything came off them,
`discount` is everything that did — the rate the cashier gave on the bill plus
whatever came off individual lines, together — and `total` is what was charged.

**Two different discount figures, and they are not interchangeable:**

| Field | What it is |
|---|---|
| `discountPercent` | The rate the cashier actually gave on the whole bill, or `null`. Null is **not** zero: it means nobody set a rate, and any discount on the bill came off the lines |
| `discountRate` | What `discount` comes to as a share of `subtotal`, however it was given. Always a number, always comparable across invoices |

Show `discountPercent` plainly when it is there, since it is what the shop
agreed to. Where it is null, `discountRate` is derived rather than given, so
mark it as approximate ("≈12%") rather than presenting it as a rate somebody
set. `GET /sales/{id}` splits the same total the other way, into
`lineDiscount` and `orderDiscount`, and adds `mrpSaving` — what the customer
saved against the printed prices, which is never part of `discount`.

#### `GET /sales/{id}` — same permission

The full invoice for detail and receipt screens: `subtotal`, `discount`, `vat`,
`total`, `paid`, `due`, `status`, `paymentStatus`, `note`, `customer {name,
phone}`, `seller`, `branch {name, address, phone}`, `store {name, phone,
address, currency}`, `items[] {id, name, unit, qty, unitPrice, mrp, mrpDiscount,
mrpDiscountPercent, discount, discountPercent, vat, total}` and `payments[] {method, amount, account,
reference}`. Use `items[].id` as `saleItemId` for returns.

**Discounts come back split**, because a customer reading a slip wants to know
which saving came off what:

| Field | What it is |
|---|---|
| `items[].mrp` | The printed price, as it read on the day of sale |
| `items[].mrpDiscount` | What the customer saved against it — **already inside the selling price, never taken off the bill** |
| `items[].mrpDiscountPercent` | That saving as a rate off the MRP. 500 sold at 300 is 40%, not 67% |
| `mrpSaving` | Those savings added up, for the "YOU SAVED" line on the slip |
| `items[].discount` | Taka off that line, given at the till |
| `items[].discountPercent` | The same thing as a rate, derived from the line's own gross (price × qty) |
| `lineDiscount` | Those line discounts added up |
| `orderDiscount` | What came off the bill as a whole — `discount` minus `lineDiscount` |
| `discountPercent` | The rate the cashier gave on the bill, or `null` if they gave a figure |
| `discount` | The two together; the one number the accounts use |

Print the line rate beside the item and the bill rate beside its taka figure.
An invoice from before this split carries `discount` only.

#### `POST /sales/{id}/returns` — `sales.return.create`

`items[] {saleItemId, qty}`, `reason?` → `201 {id, returnNo, total}`.

#### `POST /sales/{id}/payments` — `sales.payment.collect`

`amount > 0`, `method?` (`cash`, `card`, `bkash`, `nagad`, `rocket`, `bank`;
default `cash`), `accountId?` → `ok`. Too much gives `422 over_payment`.
A void invoice is refused: there is nothing left to collect on it.

#### `POST /sales/{id}/void` — `pos.sale.void`

`reason` (3–255, **required**) → `{id, invoiceNo, status: "void", restored}`.

A return is goods coming back and the invoice stands. This is the other thing:
the sale should not have happened. Everything it did is undone in one
transaction — stock back on the shelf and into its own batch, serial numbers
back to `in_stock`, the money out of the account it was banked in with a
reversing entry, the customer's debt credited, points earned taken back and
points spent returned. `restored` is how many units went back.

The row stays, with `status: "void"`, and drops out of every revenue figure —
those count completed invoices only. Lines already returned are left alone:
their stock came back when they were returned. Cancelling twice is `422`.
`GET /sales/{id}` carries `meta.mayVoid`, which is true only for a completed
invoice when the caller holds the permission.

### Customers

| Method | Path | Perm | Body / query | Returns |
|---|---|---|---|---|
| GET | `/customers?q=` | `customers.customer.view` | `q` on name or phone | up to 100: `id, name, phone, email, address, creditLimit, loyaltyPoints, isWalkIn, group, saleCount, openingBalance, invoiceDue, due, addedBy, changedBy`; `meta.mayEdit, mayCreate, maySeeLedger, mayManageCredit` |
| GET | `/customers/search?q=` | `customers.customer.view` | `q` (2+ characters) | up to 8: `id, name, phone, isWalkIn, creditLimit, loyaltyPoints, due` |
| POST | `/customers/quick` | `customers.customer.create` | `name`, `phone` | `id, name, phone, created` (`201` new, `200` existing phone) |
| POST | `/customers` | `customers.customer.create` | `name`, `phone?`, `email?`, `address?`, `creditLimit?`, `openingBalance?` | `201 {id, openingBalance}` |
| PATCH | `/customers/{id}` | `customers.customer.update` | same as above | `{id, openingBalance}` |
| GET | `/customers/{id}/ledger` | `customers.ledger.view` | | last 100: `id, refType, debit, credit, balance, note, date` |
| GET | `/customers/{id}/points` | `customers.points.view` | | `balance, worth, config, ledger[]` |
| POST | `/customers/{id}/points` | `customers.points.adjust` | `points` (signed, not 0), `note` | `{balance}`; `422 negative` |

**`openingBalance` is what the customer already owed** before this shop's
invoices started here — the figure carried over from the old notebook. A shop
moving onto the system does not start with a clean slate, and half the
neighbourhood already owes it something.

It is a real due from the moment it is typed:

- `due` on the list is `openingBalance + invoiceDue`, because "what does this
  person owe" is one question. `invoiceDue` is the part with invoices behind it,
  for an app that wants to show the split — the web list prints the previous
  portion under the total, since whoever goes to collect it should know part of
  it has no invoice.
- It opens the customer's ledger as a `refType: "opening"` debit, so the running
  balance reads as one story from the first row.
- It counts against `creditLimit`. A limit that ignored it would not be a limit.
- It puts the customer on `GET /reports/dues` even with no invoice at all.

Both `openingBalance` and `creditLimit` need `customers.credit.manage`; without
it, both are ignored rather than refused, so a clerk who may add customers but
not set credit simply cannot move either figure. Changing the opening balance
later is allowed and writes a `refType: "opening_correction"` line for the
difference — a debit when it goes up, a credit when it comes down — rather than
rewriting what the ledger already said.

**Collecting it is not built yet.** `POST /sales/{id}/payments` settles an
invoice, and an opening due has none; taking money against it needs an action of
its own.

### Products and stock

#### `GET /products` — `inventory.product.view`

Query: `q` (name, barcode, SKU, company/brand, generic name), `lowOnly=1`, `trashed=1`, `page`,
`perPage`.

```json
{
  "data": [ { "id": 42, "name": "Napa 500mg", "barcode": "...", "purchasePrice": 1.0, "salePrice": 1.2,
              "profitPercent": 20, "profitRate": 20, "wholesalePrice": 1.1, "mrp": 1.2,
              "minimumStock": 20, "vatPercent": 0, "isActive": true,
              "unit": "pc", "brand": "Beximco", "category": "Analgesic", "sku": null, "trackBatch": true,
              "stock": 4209, "deletedAt": null, "addedBy": "Owner", "changedBy": null } ],
  "meta": { "total": 311, "page": 1, "perPage": 25, "showCost": true, "trashedCount": 2 }
}
```

`lowOnly` filters the current page only. `trashed=1` lists the deleted ones
instead of the live ones; `meta.trashedCount` says how many there are either way.

| Method | Path | Perm | Body | Returns |
|---|---|---|---|---|
| GET | `/products/stats` | `inventory.stock.view` | | `total, active, lowCount, low[10], expiringCount, expiring[10], stockValue, canSeeCost` |
| GET | `/products/lookups` | `inventory.product.view` | | `brands[]` — the company names this shop already deals in — and `units[] {short, label, labelBn}`, common ones first. What the Company and Unit boxes on the product form offer, so neither is blank paper |
| GET | `/products/{id}/history` | `inventory.stock.view` | | `movements[40] {type, qtyIn, qtyOut, balanceAfter, movedAt, note, user}`, `prices[20]` |
| POST | `/products` | `inventory.product.create` | see below | `201 {id, name, catalogueId}` |
| PATCH | `/products/{id}` | `inventory.product.update` | any of `name, brand, sku, barcode, unit, mrp, vatPercent, minimumStock, trackBatch, isActive`; and the prices, which arrive together: `purchasePrice`, `salePrice` (≥ purchasePrice), `wholesalePrice`, `profitPercent?` | `{id, name, repriced}` |
| DELETE | `/products/{id}` | `inventory.product.delete` | | `{ok, stockWritten}` |
| POST | `/products/{id}/restore` | `inventory.product.delete` | | `{ok, id, name}` |
| PATCH | `/products/{id}/prices` | `inventory.product.update` | `purchasePrice`, `salePrice` (≥ purchasePrice), `wholesalePrice` (all required), `profitPercent?` (null to clear the stated rate) | `ok, changed`. Prices only; `PATCH /products/{id}` takes the same four alongside everything else |
| POST | `/products/{id}/adjust` | `inventory.adjust.create` | `qty` (signed, not 0), `reason`, `isDamage?` | `201 ok` |

Create body: `name`, `purchasePrice` (≥ 0.01) and `salePrice` (≥ purchasePrice)
are required. Optional: `genericName`, `brand`, `sku`, `barcode`, `unit`,
`wholesalePrice`, `mrp`, `vatPercent`, `minimumStock`, `openingStock`,
`trackBatch`, `profitPercent`. `openingStock` defaults to **0**: a shop writes a product down
the day it decides to carry it, often before the first carton arrives, and a
quantity nobody typed is a quantity nobody counted. Send what is in hand to
open with stock.

`brand` is the company. It is a plain string either way, so a name nobody has
saved yet simply works — `GET /products/lookups` is what makes the box offer
the ones already saved rather than leaving it blank paper. `unit` is the same:
a `short` off that list, or any word, and an unknown one becomes this store's
own unit.

**`profitPercent` is the markup the shop put on its cost**, and it is stored
on the product. A shop prices by saying "cost plus five percent", and that is a
decision, not just arithmetic: when the supplier's cost moves from 80 to 90, a
shop on a stated rate wants 94.50 worked out for it, and a shop that simply
named 84 wants to be asked. So the form fills the selling price in from the rate
and sends **both** — `salePrice` remains the authority on the money, and
`profitPercent` records why it is that price.

`null` means no rate was stated, which is **not** a rate of zero. Every
product priced before this field existed is null, and so is any product whose
price was typed directly. Two fields come back, exactly as `GET /sales` does
for discounts:

| Field | What it is |
|---|---|
| `profitPercent` | The rate the shop stated, or `null`. Show it plainly; feed it back when changing prices so a cost change carries the selling price with it |
| `profitRate` | `(salePrice − purchasePrice) / purchasePrice × 100`, always computed. Mark it as approximate when `profitPercent` is null, rather than presenting a derived figure as a decision |

Both are null when the caller may not see cost (`inventory.product.view_cost`),
since a markup is a cost by another name.

The rate is written to the price history too, so `GET /products/{id}/history`
answers "what were we making on this in Ramadan" the same way it answers "what
were we charging".

`catalogueId` in the reply is the shared catalogue entry this product belongs
under. If the catalogue already had it the shop's product simply points at that
row; if it did not, a `pending` entry is created and every shop of the same kind
is offered it on their **Not in my store** list from that moment.

**Deleting is a soft delete.** The product leaves the list, the till, the
catalogue's "already in your store" reckoning and every stock figure, and
`stockWritten` says how much was on the shelf when it went. Past sales,
purchases and receipts still name it, and `POST /products/{id}/restore` puts it
back exactly as it was. A package holding a deleted product reads as
`buildable: 0` until the product comes back.

`PATCH /products/{id}` does not change prices — that is
`/products/{id}/prices`, which files the old price in history so profit on past
invoices stays correct.

**A selling price below the cost is refused everywhere**, with a `422`: typing
a product in, changing its prices, adopting a catalogue line, endorsing a
suggestion, and on the shared catalogue's own defaults — where it matters most,
since every shop that adopts the line starts from that pair. Disable the save
button on the form as well, so nobody has to press it to find out.

### Packages (bundles)

| Method | Path | Perm | Body / query | Returns |
|---|---|---|---|---|
| GET | `/packages?q=&sellableOnly=1` | `inventory.package.view` | | list of package objects; `meta.mayManage` |
| GET | `/packages/sellable?q=` | `inventory.package.view` | | packages on sale now that can be built from this branch's stock |
| GET | `/packages/products?q=` | `inventory.package.manage` | | picker: `id, name, unit, salePrice, stock` |
| POST | `/packages` | `inventory.package.manage` | see below | `201` package |
| PATCH | `/packages/{id}` | `inventory.package.manage` | same as above (items are replaced) | package |
| PATCH | `/packages/{id}/active` | `inventory.package.manage` | `isActive` | `id, availability` |
| DELETE | `/packages/{id}` | `inventory.package.manage` | | `ok` |

Body: `name`, `price`, `items[] {storeProductId, qty}` (required), plus
`description?`, `barcode?`, `vatPercent?`, `startsAt?`, `endsAt?` (after
`startsAt`) and `isActive?`.

Package object: `id, name, description, barcode, price, vatPercent, startsAt,
endsAt, isActive, availability, sellable, buildable, componentTotal, saving,
items[] {storeProductId, name, unit, qty, salePrice}`. `availability` is `live`,
`scheduled`, `expired` or `inactive`. `buildable` is how many can be made from
this branch's stock.

### Catalogue

| Method | Path | Perm | Body / query | Returns |
|---|---|---|---|---|
| GET | `/catalog?q=&mine=1&missing=1&page=&perPage=` | `catalog.product.search` | `mine=1` → only what this store already stocks; `missing=1` → only what it does not yet; neither → both | paged (30 a page, `perPage` 10–100), always the store’s own store type: `id, name, genericName, barcode, brand, unit, category, defaultPurchasePrice, defaultSalePrice, defaultMrp, vatPercent, alreadyInStore, pending`; `meta.total`, `meta.page`, `meta.pages`, `meta.mineCount`, `meta.missingCount`. `pending: true` means a shop put it up and the platform has not vouched for it yet — every store of this type still sees it and may add it |
| POST | `/catalog/{id}/adopt` | `catalog.product.import` | `purchasePrice`, `salePrice`, `wholesalePrice?`, `profitPercent?`, `mrp?`, `localName?`, `openingStock?`, `minimumStock?` | `201 {id, created: true}`, or `200 {id, created: false}` if already in store |
| GET | `/catalog/check?name=&barcode=&brand=` | `catalog.product.suggest` | | `parsed, verdict, exact, alreadyInStore, matches[]` |
| GET | `/catalog/lookups` | `catalog.product.suggest` | | `units[] {short, label, labelBn}` (common ones first) and `brands[]` names — what the new-product form offers. Units are the shared ones plus this store’s own; brands are this store’s only |
| POST | `/catalog/suggestions` | `catalog.product.suggest` | see below | `201 {id, endorsed, storeProductId, name, relatedProducts}`; `409 already_in_catalog` |
| GET | `/catalog/suggestions` | `catalog.suggestion.review` | | `id, status, payload, economics, askedBy, askedAt, endorsedBy, endorsedAt, storeProduct, reviewNote`; `meta.pending` |
| POST | `/catalog/suggestions/{id}/review` | `catalog.suggestion.review` | `approve`, plus optional `name, genericName, barcode, purchasePrice, salePrice, profitPercent, mrp, vatPercent, minimumStock, openingStock, note` | approve: `201 {endorsed: true, storeProductId, name}`; reject: `{endorsed: false}` |

Suggestion body: `name`, `purchasePrice` (≥ 0.01) and `salePrice` (≥
purchasePrice) are required. Optional: `genericName`, `brand`, `barcode`,
`unit` (a `short` from `/catalog/lookups`), `profitPercent`, `mrp`,
`vatPercent`, `minimumStock`, `openingStock`, `reason`, `note` and
`confirmedNew`.

`profitPercent` rides in the suggestion's payload through the review and onto
the product, so a shop that priced by markup still has that rate recorded once
the product is on its shelf.

`brand` and `unit` are words, not ids. A unit already in the shared list is
reused; anything else becomes a row belonging to this store, and only this
store is offered it next time. The same goes for a brand, so one shop's
supplier list never turns up in another's.

`barcode` is optional and not unique: leave it out, or repeat one another
product already carries. Leave `openingStock` out and the product arrives with
**1** on the shelf, which is what a shop adding something it is holding means;
send `0` for none. The same default applies to `/catalog/{id}/adopt`.

Endorsing also writes a catalogue entry with `status: pending`, linked to the
store product, so the shop sees its own new product in `GET /catalog` straight
away. The platform approving the suggestion turns that same entry public
rather than creating a second one.

Suggestion `status`: `pending` → `endorsed` (on sale in this store) →
`approved` (in the shared catalogue), or `rejected`.

### Purchase

| Method | Path | Perm | Body / query | Returns |
|---|---|---|---|---|
| GET | `/purchases?q=` | `purchase.bill.view` | `q` on ref no or supplier | latest 50: `id, refNo, purchaseDate, subtotal, discount, discountPercent, total, paid, due, paymentStatus, status, supplier, branch, itemCount, note, photos[]`; `meta.suppliers[], summary, maxPhotos, mayCreate, mayPay, mayManageSuppliers, mayEditBill` |
| GET | `/purchases/products?q=` | `purchase.bill.create` | | `id, name, purchasePrice, trackBatch, unit` |
| GET | `/suppliers/search?q=` | `purchase.bill.view` | `q` on name, company or phone | 15: `id, name, company, phone` |
| POST | `/purchases` | `purchase.bill.create` | see [5.4](#54-goods-in--purchase-stock-keeper-manager-owner) | `201 {id, refNo, subtotal, discount, total, due, supplierId}` |
| POST | `/purchases/{id}/photos` | `purchase.bill.create` | **multipart**, `photos[]` × 1–5 | `201 [{id, url, name}]`; `meta.accepted, offered, remaining`; `422 photo_limit` |
| DELETE | `/purchases/{id}/photos/{photoId}` | `purchase.bill.update` | | `{deleted}` |
| POST | `/suppliers` | `purchase.supplier.manage` | `name`, `company?`, `phone?`, `address?` | `201 {id}` |
| PATCH | `/suppliers/{id}` | `purchase.supplier.manage` | same as above | `{id}` |

`discountPercent` is null on a bill where nobody gave a rate, which is not the
same fact as zero percent — `discount` is the taka either way.

### Accounts and expenses

| Method | Path | Perm | Body | Returns |
|---|---|---|---|---|
| GET | `/accounts` | `accounts.account.view` | | `accounts[], expenses[80], transactions[40], categories[], quick[], employees[], monthExpense, todayExpense, monthSalary`; `meta.mayManage, mayExpense, mayDeleteExpense, mayManageCategories, mayTransfer` |
| POST | `/accounts` | `accounts.account.manage` | `name`, `type` (`cash`, `bank`, `mfs`), `openingBalance?` | `201 {id}` |
| POST | `/accounts/transfer` | `accounts.transfer.create` | `fromAccountId`, `toAccountId` (different), `amount`, `note?` | `ok` |
| POST | `/expenses` | `accounts.expense.create` | `categoryId?` or `categoryName?`, `amount?`, `accountId?`, `note?`, `date?`, `employeeName?`, `salaryMonth?` (`YYYY-MM`) | `201 {ok, id, amount, isSalary}`; `422 amount_required`, `422 employee_required` |
| DELETE | `/expenses/{id}` | `accounts.expense.delete` | | `deleted` |
| POST | `/expense-categories` | `accounts.category.manage` | `name`, `icon?` (emoji), `defaultAmount?`, `isQuick?`, `isSalary?`, `isActive?`, `sortOrder?` | `201 {id}`; `422 duplicate` |
| PATCH | `/expense-categories/{id}` | `accounts.category.manage` | same as above — send every flag, since an omitted `isQuick` or `isSalary` reads as `false` | `{id}` |
| DELETE | `/expense-categories/{id}` | `accounts.category.manage` | | `{deleted, retired, usedCount?}`. A type with expenses is retired, not deleted |

`POST /expenses` and `POST /accounts/transfer` need nothing from
`accounts.account.view`, but their screens load from `GET /accounts`. A custom
role with only `expense.create` needs its own simple form.

### Reports

| Method | Path | Perm | Query | Returns |
|---|---|---|---|---|
| GET | `/dashboard` | `report.sales.view` | `range` (`today`, `yesterday`, `7d`, `15d`, `1m`, `2m`, `custom` + `from`/`to`) | the whole owner's screen in one call — see [5.8](#58-owners-dashboard-and-reports) |
| GET | `/reports/sales` | `report.sales.view` | `days` (default 30) | `daily[] {date, total, count}`, `topProducts[15] {id, name, qty, revenue, profit}`, `byUser[] {name, total, count}`, `byMethod[] {method, total}`, `showProfit` |
| GET | `/reports/profit` | `report.profit.view` | `days` (default 30) | `revenue, cost, returnTotal, grossProfit, expenses, netProfit, margin` (%) |
| GET | `/reports/stock` | `report.stock.view` | | `stockValue, totalUnits, low[], expiring[], dead[20]` (no sale in 90 days) |
| GET | `/reports/dues` | `report.due.view` | | up to 100: `id, name, phone, due, creditLimit, ageDays` |

Sales, stock, and profit's `revenue` and `cost` are for the current branch.
Profit's `returnTotal` and `expenses`, and the dues report, cover the whole store.

### Workspace

| Method | Path | Perm | Body | Returns |
|---|---|---|---|---|
| GET | `/workspace/tabs` | — | | `{ tabs, active }` — whatever the client last saved, or `null` |
| PUT | `/workspace/tabs` | — | `tabs` (array, max 20), `active?` | `ok` |

Which screens a person had open, per user and per store, so a browser reopens
where they left off. The server does not read the contents: it stores the JSON
and gives it back. A mobile app with its own navigation can ignore both.

### Settings and team

| Method | Path | Perm | Body / query | Returns |
|---|---|---|---|---|
| GET | `/settings` | `settings.store.view` | | `store, branches[], members[], roles[], settings{}, activity[], permissionModules, loyalty`; `meta.mayUpdateStore, mayManageBranch, mayManageUser, mayManageRole, maySeeActivity` |
| PATCH | `/settings/store` | `settings.store.update` | `name` required; `phone?, email?, address?, city?, vatMode?` (`inclusive`, `exclusive`), `receiptPaper?` (`58mm`, `80mm`, `A4`), `invoicePrefix?`, `allowCreditSale?`, `loyalty?{loyalty_enabled, loyalty_earn_per, loyalty_earn_points, loyalty_value_per, loyalty_min_redeem, loyalty_max_redeem_pct, loyalty_round}` | `ok` |
| POST | `/settings/branches` | `settings.branch.manage` | `name`, `code`, `phone?`, `address?` | `201 {id}`; `422 plan_limit` |
| PATCH | `/settings/branches/{id}` | `settings.branch.manage` | same as above | `{id}` |
| POST | `/settings/members` | `settings.user.manage` | `name`, `email`, `password` (min 6), `roleId`, `branchId?` | `201 {userId, reusedExistingAccount}`; `422 plan_limit / duplicate / bad_role` |
| PATCH | `/settings/members/{storeUserId}/status` | `settings.user.manage` | `active` | `ok`; `422 self` |
| PATCH | `/settings/members/{userId}/role` | `settings.role.manage` | `roleId` | `ok`; `422 self`, `403 forbidden_role` |
| GET | `/settings/roles/{id}` | `settings.role.manage` | | `id, name, label, isLocked, permissions[]` |
| GET | `/settings/activity` | `settings.activity.view` | `q?, subject?, event?, userId?, days?` (1–365, default 30) | up to 200: `id, event, subjectType, subjectId, subjectLabel, changes[] {field, from, to}, createdAt, user, ip`; `meta.subjects, events, days` |

`members[]` item: `storeUserId, status (active|suspended), id, name, email,
phone, lastLoginAt, roleName`.

### Super admin

All need the matching `admin.*` permission, which only Super Admin holds.

| Method | Path | Perm | Body | Returns |
|---|---|---|---|---|
| GET | `/admin/overview` | `admin.store.view` | | `stores[], storeTypes[], plans[], suggestions[], totals` |
| POST | `/admin/stores` | `admin.store.create` | `name`, `storeTypeId`, `ownerName`, `ownerEmail`, `ownerPassword`, `phone`; `planId?, address?, branchName?` | `201 {storeId, ownerEmail, reusedExistingAccount, dbName, dbCreated, dbMigrated, dbProblem, dbDetail}` |
| PATCH | `/admin/stores/{id}/status` | `admin.store.update` | `status` (`active`, `suspended`) | `ok` |
| PATCH | `/admin/stores/{id}` | `admin.store.update` | any of `name, storeTypeId, planId, phone, email, address, city, currency, timezone, status` | `{id, name, slug, status, locked, dbName, storeTypeChanged}` |
| POST | `/admin/stores/{id}/extend` | `admin.store.update` | `days` (1–3650) or `unlimited`, `activate?` (default true) | `{id, status, trialEndsAt, trialDaysLeft, locked}`; `422 nothing_to_do` |
| POST | `/admin/stores/{id}/impersonate` | `admin.store.impersonate` | | `storeId, branchId`. This device is now in that store |
| POST | `/admin/suggestions/{id}/review` | `admin.suggestion.review` | `approve`, `note?`, and optional corrected fields | `201 {created: true, globalProductId}` or `{created: false}` |

#### The shared product catalogue

One product table stands behind every store. A shop of a given kind is offered
every entry filed under that kind, on its **Not in my store** list, and adds
what it sells with its own prices — which is how somebody opening a pharmacy has
a stocked till the same afternoon. These endpoints are how the platform keeps
that table right.

| Method | Path | Perm | Body / query | Returns |
|---|---|---|---|---|
| GET | `/admin/catalog` | `admin.catalog.manage` | `q`, `storeType`, `status`, `trashed=1`, `page`, `perPage` | paged entries: `id, name, genericName, brand, unit, category, categoryId, storeType, storeTypeId, sku, barcode, purchasePrice, salePrice, mrp, vatPercent, status, inStores, deletedAt`; `meta.total, page, perPage, trashedCount, pendingCount, storeTypes[]` |
| GET | `/admin/catalog/lookups?storeType=` | `admin.catalog.manage` | | `brands[]`, `units[] {short, label}`, `categories[] {id, name}` — the shared ones, never a single shop's |
| POST | `/admin/catalog` | `admin.catalog.manage` | `storeTypeId`, `name` required; `genericName?, brand?, unit?, categoryId?, sku?, barcode?, description?, purchasePrice?, salePrice?, mrp?, vatPercent?, status?` | `201` entry |
| PATCH | `/admin/catalog/{id}` | `admin.catalog.manage` | any of the above | entry |
| DELETE | `/admin/catalog/{id}` | `admin.catalog.manage` | | `{ok, storesAffected}` |
| POST | `/admin/catalog/{id}/restore` | `admin.catalog.manage` | | entry |

`inStores` counts the shops that have taken the entry onto their shelf, across
every store — worth reading before changing a name three hundred shops are
looking at. Their own product names and prices are never touched by an edit
here.

Deleting is a soft delete: the entry leaves every catalogue page, every **Not in
my store** list and the duplicate check, while shops already selling it keep
their product and its history. `status` is `draft`, `pending`, `approved` or
`rejected`; `approved` and `pending` are the two a shop is shown, and a pending
one carries an "unverified" flag rather than being hidden.

---

## 7. Not in the API yet

These permissions exist in the role matrix, but **there is no endpoint for them
yet**, in the web workspace or here. Leave them out of the first app release, or
ask for the endpoint first:

| Process | Permission |
|---|---|
| Send stock to another branch or receive it | `inventory.transfer.create` / `approve` |
| Approve stock adjustments (they apply immediately today) | `inventory.adjust.approve` |
| Edit or delete a purchase, pay a supplier's due, return goods to a supplier | `purchase.bill.update` / `delete`, `purchase.payment.create`, `purchase.return.create` |
| Delete a customer | `customers.customer.delete` |
| Daily closing | `accounts.closing.manage` |
| VAT report, export of any list or report | `report.vat.view`, `report.export`, `*.export` |
| Edit which permissions a role has, or deny one permission to one person | `settings.role.manage` (only reading and assigning roles exists) |
| Assign a member to specific branches | `settings.user.manage` |
| Print templates, API keys | `settings.template.manage`, `settings.apikey.manage` |
| Plans | `admin.plan.manage` |
| Push notifications (low stock, big sale) | — |

---

## Appendix: trying it with curl

```bash
BASE=http://127.0.0.1:8000/api/v1

TOKEN=$(curl -s -X POST $BASE/auth/login \
  -H 'Accept: application/json' -H 'Content-Type: application/json' \
  -d '{"email":"owner@rahman.test","password":"bizpos123","deviceName":"curl"}' \
  | sed -E 's/.*"token":"([^"]+)".*/\1/')

curl -s $BASE/me -H 'Accept: application/json' -H "Authorization: Bearer $TOKEN"

# A PATCH, the way the app must send it
curl -s -X POST $BASE/me/preferences \
  -H 'Accept: application/json' -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $TOKEN" -H 'X-HTTP-Method-Override: PATCH' \
  -d '{"locale":"en"}'
```

Demo accounts (seeded data, password `bizpos123`): `super@bizpos.test`,
`owner@rahman.test`, `manager@rahman.test`, `cashier@rahman.test`,
`stock@rahman.test`, `accounts@rahman.test`.

**Server side:** the token table comes from a migration. On the live server run
`php artisan migrate --force` once after deploying, or every call answers 500.
