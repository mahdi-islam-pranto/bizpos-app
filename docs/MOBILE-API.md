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
2. [Signing in and the session](#2-signing-in-and-the-session)
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

| Header                     | Value                            | When                                                       |
| -------------------------- | -------------------------------- | ---------------------------------------------------------- |
| `Accept`                 | `application/json`             | always                                                     |
| `Content-Type`           | `application/json`             | when sending a body                                        |
| `Authorization`          | `Bearer <token>`               | every call except`auth/login` and `public/permissions` |
| `X-HTTP-Method-Override` | `PUT`, `PATCH` or `DELETE` | see below                                                  |

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
- Money is a JSON number in the store's currency (`store.currency`, usually `BDT`).
- Dates are ISO 8601 strings (`2026-09-13T14:05:00+06:00`). Report day buckets
  are `YYYY-MM-DD`.
- IDs are integers.

### Pagination

Only `GET /sales` and `GET /products` are paginated. Pass `?page=2&perPage=25`
and read `meta.total`, `meta.page` and `meta.perPage`. Other lists return a
fixed recent window (for example the latest 50 purchases or 100 customers) and
accept `?q=` to search.

### Error shape

```json
{
  "error": {
    "message": "Human-readable reason",
    "code": "machine_code"
  }
}
```

| HTTP | `code`                                                                                | Meaning                                                                  | What the app should do                             |
| ---- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ | -------------------------------------------------- |
| 401  | `unauthenticated`                                                                     | Token missing, wrong, expired or revoked, or the user was deactivated    | Delete the stored token and go to the login screen |
| 403  | `forbidden`                                                                           | This user lacks the permission.`error.permission` names it             | Show "not allowed" and hide that action            |
| 422  | `validation`                                                                          | Input failed validation.`error.fields` maps each field to its messages | Show the messages beside the fields                |
| 422  | a business code (`insufficient_stock`, `sale`, `shift_open`, `plan_limit`, ...) | A rule refused the action.`message` says why                           | Show`message`                                    |
| 409  | `already_in_catalog`                                                                  | Product suggestion duplicates the catalogue                              | See[Catalogue](#catalogue)                          |
| 404  | `not_found`                                                                           | No such record**in the current store**, or no such route           |                                                    |
| 400  | `bad_request`                                                                         | No store or branch selected (user belongs to no active store)            | Show a "no store" screen                           |
| 429  | `too_many_requests`                                                                   | Login tried more than 10 times a minute                                  | Wait and retry                                     |

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

| Key              | Role         | বাংলা                  | Who it is for                                                                                                        |
| ---------------- | ------------ | --------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `super_admin`  | Super Admin  | সুপার অ্যাডমিন | Platform staff. Everything in every store, plus the admin endpoints                                                  |
| `store_owner`  | Store Owner  | দোকান মালিক       | Everything in their own store                                                                                        |
| `manager`      | Manager      | ম্যানেজার          | Owner minus profit report, role management, deleting products, purchases or customers, voiding invoices and API keys |
| `cashier`      | Cashier      | ক্যাশিয়ার        | Counter: sell, hold, cash drawer, customers, collect dues. Sees only their own invoices, and no costs                |
| `stock_keeper` | Stock Keeper | স্টক কিপার         | Products, catalogue, stock adjustments, packages, purchases, suppliers, stock report                                 |
| `accountant`   | Accountant   | হিসাবরক্ষক        | Accounts, expenses, all invoices, dues, every report                                                                 |
| `auditor`      | Auditor      | নিরীক্ষক            | Read-only view of everything (no create, edit, delete or approve)                                                    |

### Permission × role matrix (what the API actually checks)

✅ = has it by default. Super Admin has every permission and is left out of the
table.

Abbreviations: **OW** Owner · **MG** Manager · **CA** Cashier · **SK** Stock
Keeper · **AC** Accountant · **AU** Auditor

| Permission                                                       |        OW        | MG | CA | SK | AC | AU |
| ---------------------------------------------------------------- | :--------------: | :-: | :-: | :-: | :-: | :-: |
| **POS**                                                    |                  |    |    |    |    |    |
| `pos.sale.create` — open POS and sell                         |        ✅        | ✅ | ✅ |    |    |    |
| `pos.sale.change_price` — edit unit price in cart             |        ✅        | ✅ |    |    |    |    |
| `pos.sale.give_discount` — line and order discount            |        ✅        | ✅ |    |    |    |    |
| `pos.sale.hold` — hold and resume carts                       |        ✅        | ✅ | ✅ |    |    |    |
| `pos.shift.manage` — open and close cash drawer               |        ✅        | ✅ | ✅ |    |    |    |
| `pos.sale.redeem_points` — redeem loyalty points              |        ✅        | ✅ | ✅ |    |    |    |
| `pos.sale.print` — print receipt                              |        ✅        | ✅ | ✅ |    |    |    |
| **Catalogue**                                              |                  |    |    |    |    |    |
| `catalog.product.search`                                       |        ✅        | ✅ | ✅ | ✅ |    | ✅ |
| `catalog.product.import` — add catalogue product to store     |        ✅        | ✅ |    | ✅ |    |    |
| `catalog.product.suggest` — suggest a new product             |        ✅        | ✅ |    | ✅ |    |    |
| `catalog.suggestion.review` — approve own store's suggestions |        ✅        | ✅ |    |    |    |    |
| **Products and stock**                                     |                  |    |    |    |    |    |
| `inventory.product.view`                                       |        ✅        | ✅ | ✅ | ✅ | ✅ | ✅ |
| `inventory.product.update` — change prices                    |        ✅        | ✅ |    | ✅ |    |    |
| `inventory.product.view_cost` — see purchase cost             |        ✅        | ✅ |    | ✅ | ✅ | ✅ |
| `inventory.stock.view`                                         |        ✅        | ✅ | ✅ | ✅ | ✅ | ✅ |
| `inventory.adjust.create` — stock adjustment or damage        |        ✅        | ✅ |    | ✅ |    |    |
| `inventory.package.view`                                       |        ✅        | ✅ | ✅ | ✅ |    | ✅ |
| `inventory.package.manage`                                     |        ✅        | ✅ |    | ✅ |    |    |
| **Sales**                                                  |                  |    |    |    |    |    |
| `sales.invoice.view` — own invoices                           |        ✅        | ✅ | ✅ |    |    | ✅ |
| `sales.invoice.view_all` — everyone's invoices                |        ✅        | ✅ |    |    | ✅ | ✅ |
| `sales.return.create` — accept a return                       |        ✅        | ✅ |    |    |    |    |
| `sales.payment.collect` — collect a due                       |        ✅        | ✅ | ✅ |    | ✅ |    |
| **Customers**                                              |                  |    |    |    |    |    |
| `customers.customer.view`                                      |        ✅        | ✅ | ✅ |    | ✅ | ✅ |
| `customers.customer.create`                                    |        ✅        | ✅ | ✅ |    |    |    |
| `customers.customer.update`                                    |        ✅        | ✅ |    |    |    |    |
| `customers.credit.manage` — set credit limit                  |        ✅        | ✅ |    |    |    |    |
| `customers.ledger.view`                                        |        ✅        | ✅ |    |    | ✅ | ✅ |
| `customers.points.view`                                        |        ✅        | ✅ | ✅ |    | ✅ | ✅ |
| `customers.points.adjust`                                      |        ✅        | ✅ |    |    |    |    |
| **Purchase**                                               |                  |    |    |    |    |    |
| `purchase.bill.view`                                           |        ✅        | ✅ |    | ✅ | ✅ | ✅ |
| `purchase.bill.create`                                         |        ✅        | ✅ |    | ✅ |    |    |
| `purchase.supplier.manage`                                     |        ✅        | ✅ |    | ✅ |    |    |
| **Accounts**                                               |                  |    |    |    |    |    |
| `accounts.account.view`                                        |        ✅        | ✅ |    |    | ✅ | ✅ |
| `accounts.account.manage` — create accounts                   |        ✅        | ✅ |    |    | ✅ |    |
| `accounts.transfer.create`                                     |        ✅        | ✅ |    |    | ✅ |    |
| `accounts.expense.create`                                      |        ✅        | ✅ |    |    | ✅ |    |
| `accounts.expense.delete`                                      |        ✅        | ✅ |    |    | ✅ |    |
| `accounts.category.manage` — expense types                    |        ✅        | ✅ |    |    | ✅ |    |
| **Reports**                                                |                  |    |    |    |    |    |
| `report.sales.view`                                            |        ✅        | ✅ |    |    | ✅ | ✅ |
| `report.profit.view`                                           |        ✅        |    |    |    | ✅ | ✅ |
| `report.stock.view`                                            |        ✅        | ✅ |    | ✅ | ✅ | ✅ |
| `report.due.view`                                              |        ✅        | ✅ |    |    | ✅ | ✅ |
| **Settings**                                               |                  |    |    |    |    |    |
| `settings.store.view`                                          |        ✅        | ✅ |    |    |    | ✅ |
| `settings.store.update` — store info, VAT, loyalty            |        ✅        | ✅ |    |    |    |    |
| `settings.branch.manage`                                       |        ✅        | ✅ |    |    |    |    |
| `settings.user.manage` — add, suspend team members            |        ✅        | ✅ |    |    |    |    |
| `settings.role.manage` — change a member's role               |        ✅        |    |    |    |    |    |
| `settings.activity.view` — activity log                       |        ✅        | ✅ |    |    |    | ✅ |
| **Super admin** (`admin.*`)                              | only Super Admin |    |    |    |    |    |

The catalogue has more permissions than the API has endpoints for (void, stock
transfer, VAT report, export and others). See [section 7](#7-not-in-the-api-yet).

### Fields that change with permissions

The same endpoint may return less to a weaker role. Handle `null` or `0`:

| Where                               | Field                                                                                 | Hidden unless                                         |
| ----------------------------------- | ------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| `GET /pos/search`                 | `purchasePrice` is `null`                                                         | `inventory.product.view_cost`                       |
| `GET /products`                   | `purchasePrice`, `wholesalePrice` are `0` (`meta.showCost` says so)           | `inventory.product.view_cost`                       |
| `GET /products/{id}/history`      | `prices` is empty                                                                   | `inventory.product.view_cost`                       |
| `GET /customers/search`           | `loyaltyPoints` is `null`                                                         | `customers.points.view`                             |
| `GET /reports/sales`              | `topProducts[].profit` is `null` (`showProfit: false`)                          | `report.profit.view`                                |
| `GET /sales`, `GET /sales/{id}` | only own invoices                                                                     | `sales.invoice.view_all`                            |
| `GET /settings`                   | `activity` is empty                                                                 | `settings.activity.view`                            |
| `POST /pos/checkout`              | `unitPrice` and `discount` in lines, and `orderDiscount`, are **ignored** | `pos.sale.change_price`, `pos.sale.give_discount` |
| `POST/PATCH /customers`           | `creditLimit` is ignored                                                            | `customers.credit.manage`                           |

---

## 4. Role-wise app map

Show a tab or menu item when the user has its **gate permission**. Inside a
screen, use the action permissions (or the `meta.may*` flags the list returns)
to show buttons.

| App screen                        | Gate permission                                       | Action permissions inside                                                                                                                                 |        OW        |      MG      |   CA   |    SK    |   AC   |   AU   |
| --------------------------------- | ----------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | :--------------: | :----------: | :-----: | :------: | :-----: | :-----: |
| **Dashboard**               | any of`report.sales.view`, `inventory.stock.view` | —                                                                                                                                                        |        ✅        |      ✅      |   ✅*   |   ✅*   |   ✅   |   ✅   |
| **POS / Sell**              | `pos.sale.create`                                   | `pos.sale.hold`, `pos.shift.manage`, `pos.sale.change_price`, `pos.sale.give_discount`, `pos.sale.redeem_points`, `customers.customer.create` |        ✅        |      ✅      |   ✅   |          |        |        |
| **Invoices**                | `sales.invoice.view` or `sales.invoice.view_all`  | `sales.return.create`, `sales.payment.collect`                                                                                                        |        ✅        |      ✅      | ✅ own |          |   ✅   |   ✅   |
| **Customers**               | `customers.customer.view`                           | `customers.customer.create`/`update`, `customers.ledger.view`, `customers.points.view`/`adjust`                                                 |        ✅        |      ✅      |   ✅   |          |   ✅   |   ✅   |
| **Products and stock**      | `inventory.product.view`                            | `inventory.product.update`, `inventory.adjust.create`, `inventory.stock.view`                                                                       |        ✅        |      ✅      | ✅ view |    ✅    | ✅ view | ✅ view |
| **Packages**                | `inventory.package.view`                            | `inventory.package.manage`                                                                                                                              |        ✅        |      ✅      | ✅ view |    ✅    |        | ✅ view |
| **Catalogue**               | `catalog.product.search`                            | `catalog.product.import`, `catalog.product.suggest`                                                                                                   |        ✅        |      ✅      | ✅ view |    ✅    |        | ✅ view |
| **Suggestion approvals**    | `catalog.suggestion.review`                         | —                                                                                                                                                        |        ✅        |      ✅      |        |          |        |        |
| **Purchase**                | `purchase.bill.view`                                | `purchase.bill.create`, `purchase.supplier.manage`                                                                                                    |        ✅        |      ✅      |        |    ✅    | ✅ view | ✅ view |
| **Accounts and expenses**   | `accounts.account.view`                             | `accounts.expense.create`/`delete`, `accounts.transfer.create`, `accounts.account.manage`, `accounts.category.manage`                           |        ✅        |      ✅      |        |          |   ✅   | ✅ view |
| **Reports**                 | any`report.*.view`                                  | tabs: sales, profit, stock, dues, each by its own permission                                                                                              |        ✅        | ✅ no profit |        | ✅ stock |   ✅   |   ✅   |
| **Team and store settings** | `settings.store.view`                               | `settings.store.update`, `settings.branch.manage`, `settings.user.manage`, `settings.role.manage`, `settings.activity.view`                     |        ✅        | ✅ no roles |        |          |        | ✅ view |
| **Platform admin**          | `admin.store.view`                                  | `admin.store.create`/`update`/`impersonate`, `admin.suggestion.review`                                                                            | Super Admin only |              |        |          |        |        |

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
4. **Customer** (optional): `GET /customers/search?q=0171` (2+ characters, phone
   first). Not found: `POST /customers/quick` `{"name": "...", "phone": "..."}`.
   If the phone already exists, it returns that customer with `created: false`.
5. **Checkout**: `POST /pos/checkout`.
6. **Receipt**: `GET /sales/{saleId}` has everything a receipt needs (store,
   branch, items, payments, totals). Print it on a Bluetooth printer in the
   app.
7. **Close the drawer**: `POST /pos/shift/close` `{"countedCash": 15230}`. The
   response gives `expected`, `counted` and `difference`.

**Hold a cart**: `POST /pos/hold` `{"label": "Blue shirt man", "cart": {...any JSON the app wants...}}`. **Resume**: `POST /pos/hold/{id}/resume` returns the
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

### 5.3 Collect a due (Cashier, Accountant, Manager, Owner)

1. Who owes: `GET /reports/dues` (needs `report.due.view`), or from a customer:
   `GET /sales?q=<phone>` and filter `due > 0`.
2. `POST /sales/{id}/payments` `{"amount": 500, "method": "bkash", "accountId": 2}`.
   More than the due fails: `422 over_payment`.

### 5.4 Goods in / purchase (Stock Keeper, Manager, Owner)

1. `GET /purchases` → `meta.suppliers`. New supplier: `POST /suppliers`.
2. Pick products: `GET /purchases/products?q=`. A product not in the store yet:
   add it from the catalogue first (5.6).
3. `POST /purchases`:

   ```json
   {
     "supplierId": 3,
     "items": [
       { "storeProductId": 42, "qty": 100, "unitCost": 78.5, "batchNo": "B2291", "expiryDate": "2027-06-30" }
     ],
     "paidAmount": 5000,
     "accountId": 1,
     "note": "Invoice #7781"
   }
   ```

   Stock rises, the rest is owed to the supplier, and `paidAmount` leaves
   `accountId`.

### 5.5 Stock adjustment and price change (Stock Keeper, Manager, Owner)

- Count correction or damage: `POST /products/{id}/adjust`
  `{"qty": -3, "reason": "Broken in transit", "isDamage": true}`. `qty` is
  signed: `+` adds, `-` removes, and it cannot be 0.
- Price change: `PATCH /products/{id}/prices` with all three prices. The old
  price is kept in history.
- History: `GET /products/{id}/history`.
- Alerts: `GET /products/stats` (low stock, expiring in 90 days, stock value).

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

1. `GET /catalog?q=napa` (the store's own type; `&allTypes=1` for all). If
   `alreadyInStore` is set, it holds this store's product ID.
2. Found: `POST /catalog/{id}/adopt`
   `{"purchasePrice": 1.0, "salePrice": 1.2, "openingStock": 200, "minimumStock": 20}`.
3. Not found: `GET /catalog/check?name=Monas 50&brand=ACI` while the user
   types. `verdict` is `exists`, `variant`, `other_brand`, `similar` or `new`.
4. `POST /catalog/suggestions` with name, prices and so on. An exact duplicate
   returns `409 already_in_catalog` with `error.match` and `alreadyInStore`.
   To go ahead anyway, resend with `"confirmedNew": true`. If the response has
   `endorsed: true`, the product is already on sale (`storeProductId`).
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
- Mistake: `DELETE /expenses/{id}`. The money goes back into the account.
- Bank deposit: `POST /accounts/transfer` `{"fromAccountId": 1, "toAccountId": 3, "amount": 20000}`.

### 5.8 Owner's dashboard and reports

A dashboard is a few calls in parallel:

| Tile                       | Call                            | Field                                                  |
| -------------------------- | ------------------------------- | ------------------------------------------------------ |
| Today's sales              | `GET /reports/sales?days=1`   | `daily[0].total`, `daily[0].count`                 |
| Today's payments by method | same                            | `byMethod`                                           |
| Profit, last 30 days       | `GET /reports/profit?days=30` | `grossProfit`, `netProfit`, `margin`             |
| Sales chart                | `GET /reports/sales?days=30`  | `daily[]`                                            |
| Top products               | same                            | `topProducts`                                        |
| Sales by staff             | same                            | `byUser`                                             |
| Low stock, expiring        | `GET /products/stats`         | `lowCount`, `low`, `expiringCount`, `expiring` |
| Money owed to the shop     | `GET /reports/dues`           | sum of`due`                                          |
| Today's expenses           | `GET /accounts`               | `todayExpense`                                       |

Sales and stock reports, and profit's revenue and cost, are for the **current
branch**. For another branch, switch branch first.

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
  branch, cash and bKash accounts, a walk-in customer and default settings.
- Suspend: `PATCH /admin/stores/{id}/status` `{"status": "suspended"}`.
- Support: `POST /admin/stores/{id}/impersonate` moves **this device** into that
  store (logged). Then call `GET /me`. To leave, `POST /auth/switch-store` back.
- Shared catalogue: `POST /admin/suggestions/{id}/review` `{"approve": true}`.

---

## 6. Endpoint reference

Every path is relative to `/api/v1`. **Perm** is the permission the server
checks. `—` means any signed-in user.

### Auth and session

| Method | Path                    | Perm | Body / query                             | Returns                                                                       |
| ------ | ----------------------- | ---- | ---------------------------------------- | ----------------------------------------------------------------------------- |
| POST   | `/auth/login`         | none | `email`, `password`, `deviceName?` | `token`, `tokenType`, `expiresAt`, `user`                             |
| POST   | `/auth/logout`        | —   |                                          | `ok`                                                                        |
| GET    | `/auth/devices`       | —   |                                          | list of devices                                                               |
| DELETE | `/auth/devices/{id}`  | —   |                                          | `ok`                                                                        |
| POST   | `/auth/switch-store`  | —   | `storeId`                              | `storeId`                                                                   |
| POST   | `/auth/switch-branch` | —   | `branchId`                             | `storeId`, `branchId`                                                     |
| GET    | `/me`                 | —   |                                          | see[section 2](#get-me--who-am-i-where-am-i-what-may-i-do)                     |
| PATCH  | `/me/preferences`     | —   | `locale?`, `theme?`                  | `locale`, `theme`                                                         |
| GET    | `/public/permissions` | none |                                          | `modules`, `roles`                                                        |
| GET    | `/palette?q=`         | —   | `q` (2+ characters)                    | global search across products, invoices and customers, filtered by permission |

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

Active products of the store, with this branch's stock.

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
  "orderDiscount": 10,
  "redeemPoints": 50,
  "note": "Delivered"
}
```

| Field                                   | Rule                                                                                                                                                                             |
| --------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lines[]`                             | Required, 1 or more. Each has**either** `storeProductId` **or** `packageId`, plus `qty > 0`                                                                    |
| `lines[].unitPrice`                   | Used only with`pos.sale.change_price`, otherwise the store price is charged                                                                                                    |
| `lines[].discount`, `orderDiscount` | Used only with`pos.sale.give_discount`                                                                                                                                         |
| `payments[].method`                   | `cash`, `card`, `bkash`, `nagad`, `rocket` or `bank`. **Do not send `credit` or `points`.** To leave a due, pay less; to use points, send `redeemPoints` |
| `payments[].accountId`                | Send it (from`lookups.accounts`) so the money lands in that account's balance                                                                                                  |
| `customerId`                          | Required when anything is left due, or points are redeemed or earned. Walk-in customers cannot buy on credit                                                                     |
| `redeemPoints`                        | Needs`pos.sale.redeem_points` and a named customer. The server caps it at what is allowed (minimum points, maximum % of bill)                                                  |

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

#### Held carts — `pos.sale.hold`

| Method | Path                      | Body                                           | Returns                               |
| ------ | ------------------------- | ---------------------------------------------- | ------------------------------------- |
| POST   | `/pos/hold`             | `label` (max 80), `cart` (any JSON object) | `201 {id}`                          |
| POST   | `/pos/hold/{id}/resume` |                                                | the`cart` JSON. The hold is deleted |
| DELETE | `/pos/hold/{id}`        |                                                | `ok`                                |

Holds are per user and per branch.

#### Cash drawer — `pos.shift.manage`

| Method | Path                 | Body                       | Returns / errors                                            |
| ------ | -------------------- | -------------------------- | ----------------------------------------------------------- |
| POST   | `/pos/shift/open`  | `openingCash`            | `201 ok`; `422 shift_open` if one is open               |
| POST   | `/pos/shift/close` | `countedCash`, `note?` | `expected`, `counted`, `difference`; `422 no_shift` |

### Sales

#### `GET /sales` — `sales.invoice.view` (own) or `sales.invoice.view_all`

Query: `q` (invoice no, customer name or phone), `days` (e.g. `1` = today,
`7`; `0` or absent = all), `page`, `perPage`. Current branch.

```json
{
  "data": [ { "id": 5521, "invoiceNo": "INV-005521", "saleDate": "...", "total": 139.5, "paid": 139.5, "due": 0,
              "paymentStatus": "paid", "status": "completed", "customer": "Rahim", "seller": "Karim",
              "branch": "Main Branch", "itemCount": 3 } ],
  "meta": { "total": 1778, "page": 1, "perPage": 25,
            "summary": { "count": 1778, "total": 912345.5, "due": 12500 },
            "seeAll": true, "mayReturn": true, "mayCollect": true }
}
```

`status` is `completed`, `returned` or `void`.

#### `GET /sales/{id}` — same permission

The full invoice for detail and receipt screens: `subtotal`, `discount`, `vat`,
`total`, `paid`, `due`, `status`, `paymentStatus`, `note`, `customer {name, phone}`, `seller`, `branch {name, address, phone}`, `store {name, phone, address, currency}`, `items[] {id, name, unit, qty, unitPrice, discount, vat, total}` and `payments[] {method, amount, account, reference}`. Use `items[].id`
as `saleItemId` for returns.

#### `POST /sales/{id}/returns` — `sales.return.create`

`items[] {saleItemId, qty}`, `reason?` → `201 {id, returnNo, total}`.

#### `POST /sales/{id}/payments` — `sales.payment.collect`

`amount > 0`, `method?` (`cash`, `card`, `bkash`, `nagad`, `rocket`, `bank`;
default `cash`), `accountId?` → `ok`. Too much gives `422 over_payment`.

### Customers

| Method | Path                       | Perm                          | Body / query                                                     | Returns                                                                                                                                                                                    |
| ------ | -------------------------- | ----------------------------- | ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| GET    | `/customers?q=`          | `customers.customer.view`   | `q` on name or phone                                           | up to 100:`id, name, phone, email, address, creditLimit, loyaltyPoints, isWalkIn, group, saleCount, due, addedBy, changedBy`; `meta.mayEdit, mayCreate, maySeeLedger, mayManageCredit` |
| GET    | `/customers/search?q=`   | `customers.customer.view`   | `q` (2+ characters)                                            | up to 8:`id, name, phone, isWalkIn, creditLimit, loyaltyPoints, due`                                                                                                                     |
| POST   | `/customers/quick`       | `customers.customer.create` | `name`, `phone`                                              | `id, name, phone, created` (`201` new, `200` existing phone)                                                                                                                         |
| POST   | `/customers`             | `customers.customer.create` | `name`, `phone?`, `email?`, `address?`, `creditLimit?` | `201 {id}`                                                                                                                                                                               |
| PATCH  | `/customers/{id}`        | `customers.customer.update` | same as above                                                    | `{id}`                                                                                                                                                                                   |
| GET    | `/customers/{id}/ledger` | `customers.ledger.view`     |                                                                  | last 100:`id, refType, debit, credit, balance, note, date`                                                                                                                               |
| GET    | `/customers/{id}/points` | `customers.points.view`     |                                                                  | `balance, worth, config, ledger[]`                                                                                                                                                       |
| POST   | `/customers/{id}/points` | `customers.points.adjust`   | `points` (signed, not 0), `note`                             | `{balance}`; `422 negative`                                                                                                                                                            |

### Products and stock

#### `GET /products` — `inventory.product.view`

Query: `q` (name, barcode, SKU, generic name), `lowOnly=1`, `page`, `perPage`.

```json
{
  "data": [ { "id": 42, "name": "Napa 500mg", "barcode": "...", "purchasePrice": 1.0, "salePrice": 1.2,
              "wholesalePrice": 1.1, "minimumStock": 20, "vatPercent": 0, "isActive": true, "unit": "pc",
              "brand": "Beximco", "category": "Analgesic", "stock": 4209, "addedBy": "Owner", "changedBy": null } ],
  "meta": { "total": 311, "page": 1, "perPage": 25, "showCost": true }
}
```

`lowOnly` filters the current page only.

| Method | Path                       | Perm                         | Body                                                                | Returns                                                                                    |
| ------ | -------------------------- | ---------------------------- | ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| GET    | `/products/stats`        | `inventory.stock.view`     |                                                                     | `total, active, lowCount, low[10], expiringCount, expiring[10], stockValue, canSeeCost`  |
| GET    | `/products/{id}/history` | `inventory.stock.view`     |                                                                     | `movements[40] {type, qtyIn, qtyOut, balanceAfter, movedAt, note, user}`, `prices[20]` |
| PATCH  | `/products/{id}/prices`  | `inventory.product.update` | `purchasePrice`, `salePrice`, `wholesalePrice` (all required) | `ok, changed`                                                                            |
| POST   | `/products/{id}/adjust`  | `inventory.adjust.create`  | `qty` (signed, not 0), `reason`, `isDamage?`                  | `201 ok`                                                                                 |

### Packages (bundles)

| Method | Path                            | Perm                         | Body / query                       | Returns                                                         |
| ------ | ------------------------------- | ---------------------------- | ---------------------------------- | --------------------------------------------------------------- |
| GET    | `/packages?q=&sellableOnly=1` | `inventory.package.view`   |                                    | list of package objects;`meta.mayManage`                      |
| GET    | `/packages/sellable?q=`       | `inventory.package.view`   |                                    | packages on sale now that can be built from this branch's stock |
| GET    | `/packages/products?q=`       | `inventory.package.manage` |                                    | picker:`id, name, unit, salePrice, stock`                     |
| POST   | `/packages`                   | `inventory.package.manage` | see below                          | `201` package                                                 |
| PATCH  | `/packages/{id}`              | `inventory.package.manage` | same as above (items are replaced) | package                                                         |
| PATCH  | `/packages/{id}/active`       | `inventory.package.manage` | `isActive`                       | `id, availability`                                            |
| DELETE | `/packages/{id}`              | `inventory.package.manage` |                                    | `ok`                                                          |

Body: `name`, `price`, `items[] {storeProductId, qty}` (required), plus
`description?`, `barcode?`, `vatPercent?`, `startsAt?`, `endsAt?` (after
`startsAt`) and `isActive?`.

Package object: `id, name, description, barcode, price, vatPercent, startsAt, endsAt, isActive, availability, sellable, buildable, componentTotal, saving, items[] {storeProductId, name, unit, qty, salePrice}`. `availability` is `live`,
`scheduled`, `expired` or `inactive`. `buildable` is how many can be made from
this branch's stock.

### Catalogue

| Method | Path                                     | Perm                          | Body / query                                                                                                                           | Returns                                                                                                                                |
| ------ | ---------------------------------------- | ----------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| GET    | `/catalog?q=&allTypes=1`               | `catalog.product.search`    |                                                                                                                                        | up to 30:`id, name, genericName, barcode, brand, unit, category, defaultPurchasePrice, defaultSalePrice, vatPercent, alreadyInStore` |
| POST   | `/catalog/{id}/adopt`                  | `catalog.product.import`    | `purchasePrice`, `salePrice`, `wholesalePrice?`, `localName?`, `openingStock?`, `minimumStock?`                            | `201 {id, created: true}`, or `200 {id, created: false}` if already in store                                                       |
| GET    | `/catalog/check?name=&barcode=&brand=` | `catalog.product.suggest`   |                                                                                                                                        | `parsed, verdict, exact, alreadyInStore, matches[]`                                                                                  |
| POST   | `/catalog/suggestions`                 | `catalog.product.suggest`   | see below                                                                                                                              | `201 {id, endorsed, storeProductId, name, relatedProducts}`; `409 already_in_catalog`                                              |
| GET    | `/catalog/suggestions`                 | `catalog.suggestion.review` |                                                                                                                                        | `id, status, payload, economics, askedBy, askedAt, endorsedBy, endorsedAt, storeProduct, reviewNote`; `meta.pending`               |
| POST   | `/catalog/suggestions/{id}/review`     | `catalog.suggestion.review` | `approve`, plus optional `name, genericName, barcode, purchasePrice, salePrice, mrp, vatPercent, minimumStock, openingStock, note` | approve:`201 {endorsed: true, storeProductId, name}`; reject: `{endorsed: false}`                                                  |

Suggestion body: `name`, `purchasePrice` (≥ 0.01) and `salePrice` (≥
purchasePrice) are required. Optional: `genericName`, `brand`, `barcode`,
`unit`, `mrp`, `vatPercent`, `minimumStock`, `openingStock`, `reason`, `note`
and `confirmedNew`.

Suggestion `status`: `pending` → `endorsed` (on sale in this store) →
`approved` (in the shared catalogue), or `rejected`.

### Purchase

| Method | Path                       | Perm                         | Body / query                                               | Returns                                                                                                                                                                           |
| ------ | -------------------------- | ---------------------------- | ---------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| GET    | `/purchases?q=`          | `purchase.bill.view`       | `q` on ref no or supplier                                | latest 50:`id, refNo, purchaseDate, total, paid, due, paymentStatus, status, supplier, branch, itemCount`; `meta.suppliers[], summary, mayCreate, mayPay, mayManageSuppliers` |
| GET    | `/purchases/products?q=` | `purchase.bill.create`     |                                                            | `id, name, purchasePrice, trackBatch, unit`                                                                                                                                     |
| POST   | `/purchases`             | `purchase.bill.create`     | see[5.4](#54-goods-in--purchase-stock-keeper-manager-owner) | `201 {id, refNo, total}`                                                                                                                                                        |
| POST   | `/suppliers`             | `purchase.supplier.manage` | `name`, `company?`, `phone?`, `address?`           | `201 {id}`                                                                                                                                                                      |
| PATCH  | `/suppliers/{id}`        | `purchase.supplier.manage` | same as above                                              | `{id}`                                                                                                                                                                          |

### Accounts and expenses

| Method | Path                         | Perm                         | Body                                                                                         | Returns                                                                                                                                                                               |
| ------ | ---------------------------- | ---------------------------- | -------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| GET    | `/accounts`                | `accounts.account.view`    |                                                                                              | `accounts[], expenses[80], transactions[40], categories[], quick[], monthExpense, todayExpense`; `meta.mayManage, mayExpense, mayDeleteExpense, mayManageCategories, mayTransfer` |
| POST   | `/accounts`                | `accounts.account.manage`  | `name`, `type` (`cash`, `bank`, `mfs`), `openingBalance?`                        | `201 {id}`                                                                                                                                                                          |
| POST   | `/accounts/transfer`       | `accounts.transfer.create` | `fromAccountId`, `toAccountId` (different), `amount`, `note?`                        | `ok`                                                                                                                                                                                |
| POST   | `/expenses`                | `accounts.expense.create`  | `categoryId?` or `categoryName?`, `amount?`, `accountId?`, `note?`, `date?`      | `201 {ok, id, amount}`; `422 amount_required`                                                                                                                                     |
| DELETE | `/expenses/{id}`           | `accounts.expense.delete`  |                                                                                              | `deleted`                                                                                                                                                                           |
| POST   | `/expense-categories`      | `accounts.category.manage` | `name`, `icon?` (emoji), `defaultAmount?`, `isQuick?`, `isActive?`, `sortOrder?` | `201 {id}`; `422 duplicate`                                                                                                                                                       |
| PATCH  | `/expense-categories/{id}` | `accounts.category.manage` | same as above                                                                                | `{id}`                                                                                                                                                                              |
| DELETE | `/expense-categories/{id}` | `accounts.category.manage` |                                                                                              | `{deleted, retired, usedCount?}`. A type with expenses is retired, not deleted                                                                                                      |

`POST /expenses` and `POST /accounts/transfer` need nothing from
`accounts.account.view`, but their screens load from `GET /accounts`. A custom
role with only `expense.create` needs its own simple form.

### Reports

| Method | Path                | Perm                   | Query                 | Returns                                                                                                                                                                   |
| ------ | ------------------- | ---------------------- | --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| GET    | `/reports/sales`  | `report.sales.view`  | `days` (default 30) | `daily[] {date, total, count}`, `topProducts[15] {id, name, qty, revenue, profit}`, `byUser[] {name, total, count}`, `byMethod[] {method, total}`, `showProfit` |
| GET    | `/reports/profit` | `report.profit.view` | `days` (default 30) | `revenue, cost, returnTotal, grossProfit, expenses, netProfit, margin` (%)                                                                                              |
| GET    | `/reports/stock`  | `report.stock.view`  |                       | `stockValue, totalUnits, low[], expiring[], dead[20]` (no sale in 90 days)                                                                                              |
| GET    | `/reports/dues`   | `report.due.view`    |                       | up to 100:`id, name, phone, due, creditLimit, ageDays`                                                                                                                  |

Sales, stock, and profit's `revenue` and `cost` are for the current branch.
Profit's `returnTotal` and `expenses`, and the dues report, cover the whole store.

### Settings and team

| Method | Path                                       | Perm                       | Body / query                                                                                                                                                                                                                                                                                                                                  | Returns                                                                                                                                                                               |
| ------ | ------------------------------------------ | -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| GET    | `/settings`                              | `settings.store.view`    |                                                                                                                                                                                                                                                                                                                                               | `store, branches[], members[], roles[], settings{}, activity[], permissionModules, loyalty`; `meta.mayUpdateStore, mayManageBranch, mayManageUser, mayManageRole, maySeeActivity` |
| PATCH  | `/settings/store`                        | `settings.store.update`  | `name` required; `phone?, email?, address?, city?, vatMode?` (`inclusive`, `exclusive`), `receiptPaper?` (`58mm`, `80mm`, `A4`), `invoicePrefix?`, `allowCreditSale?`, `loyalty?{loyalty_enabled, loyalty_earn_per, loyalty_earn_points, loyalty_value_per, loyalty_min_redeem, loyalty_max_redeem_pct, loyalty_round}` | `ok`                                                                                                                                                                                |
| POST   | `/settings/branches`                     | `settings.branch.manage` | `name`, `code`, `phone?`, `address?`                                                                                                                                                                                                                                                                                                  | `201 {id}`; `422 plan_limit`                                                                                                                                                      |
| PATCH  | `/settings/branches/{id}`                | `settings.branch.manage` | same as above                                                                                                                                                                                                                                                                                                                                 | `{id}`                                                                                                                                                                              |
| POST   | `/settings/members`                      | `settings.user.manage`   | `name`, `email`, `password` (min 6), `roleId`, `branchId?`                                                                                                                                                                                                                                                                          | `201 {userId, reusedExistingAccount}`; `422 plan_limit / duplicate / bad_role`                                                                                                    |
| PATCH  | `/settings/members/{storeUserId}/status` | `settings.user.manage`   | `active`                                                                                                                                                                                                                                                                                                                                    | `ok`; `422 self`                                                                                                                                                                  |
| PATCH  | `/settings/members/{userId}/role`        | `settings.role.manage`   | `roleId`                                                                                                                                                                                                                                                                                                                                    | `ok`; `422 self`, `403 forbidden_role`                                                                                                                                          |
| GET    | `/settings/roles/{id}`                   | `settings.role.manage`   |                                                                                                                                                                                                                                                                                                                                               | `id, name, label, isLocked, permissions[]`                                                                                                                                          |
| GET    | `/settings/activity`                     | `settings.activity.view` | `q?, subject?, event?, userId?, days?` (1–365, default 30)                                                                                                                                                                                                                                                                                 | up to 200:`id, event, subjectType, subjectId, subjectLabel, changes[] {field, from, to}, createdAt, user, ip`; `meta.subjects, events, days`                                      |

`members[]` item: `storeUserId, status (active|suspended), id, name, email, phone, lastLoginAt, roleName`.

### Super admin

All need the matching `admin.*` permission, which only Super Admin holds.

| Method | Path                               | Perm                        | Body                                                                                                                    | Returns                                                          |
| ------ | ---------------------------------- | --------------------------- | ----------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| GET    | `/admin/overview`                | `admin.store.view`        |                                                                                                                         | `stores[], storeTypes[], plans[], suggestions[], totals`       |
| POST   | `/admin/stores`                  | `admin.store.create`      | `name`, `storeTypeId`, `ownerName`, `ownerEmail`, `ownerPassword`; `planId?, phone?, address?, branchName?` | `201 {storeId, ownerEmail, reusedExistingAccount}`             |
| PATCH  | `/admin/stores/{id}/status`      | `admin.store.update`      | `status` (`active`, `suspended`)                                                                                  | `ok`                                                           |
| POST   | `/admin/stores/{id}/impersonate` | `admin.store.impersonate` |                                                                                                                         | `storeId, branchId`. This device is now in that store          |
| POST   | `/admin/suggestions/{id}/review` | `admin.suggestion.review` | `approve`, `note?`, and optional corrected fields                                                                   | `201 {created: true, globalProductId}` or `{created: false}` |

---

## 7. Not in the API yet

These permissions exist in the role matrix, but **there is no endpoint for them
yet**, in the web workspace or here. Leave them out of the first app release, or
ask for the endpoint first:

| Process                                                                                                      | Permission                                                                                     |
| ------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------- |
| Create, edit or delete a product by hand (outside catalogue adopt or suggestion), activate or deactivate one | `inventory.product.create` / `update` / `delete`                                         |
| Void a completed invoice                                                                                     | `pos.sale.void`                                                                              |
| Send stock to another branch or receive it                                                                   | `inventory.transfer.create` / `approve`                                                    |
| Approve stock adjustments (they apply immediately today)                                                     | `inventory.adjust.approve`                                                                   |
| Edit or delete a purchase, pay a supplier's due, return goods to a supplier                                  | `purchase.bill.update` / `delete`, `purchase.payment.create`, `purchase.return.create` |
| Delete a customer                                                                                            | `customers.customer.delete`                                                                  |
| Daily closing                                                                                                | `accounts.closing.manage`                                                                    |
| VAT report, export of any list or report                                                                     | `report.vat.view`, `report.export`, `*.export`                                           |
| Edit which permissions a role has, or deny one permission to one person                                      | `settings.role.manage` (only reading and assigning roles exists)                             |
| Assign a member to specific branches                                                                         | `settings.user.manage`                                                                       |
| Print templates, API keys                                                                                    | `settings.template.manage`, `settings.apikey.manage`                                       |
| Manage the shared catalogue directly, plans                                                                  | `admin.catalog.manage`, `admin.plan.manage`                                                |
| Push notifications (low stock, big sale)                                                                     | —                                                                                             |

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
