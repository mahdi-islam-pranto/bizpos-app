# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`bizpos_app` is the Flutter mobile client for **bizPOS**, a multi-store retail POS
whose backend is an existing, running Laravel web workspace.
**`docs/MOBILE-API-NEW.md` (~1930 lines) is the spec of record** — read the
relevant section before writing any feature. It defines not just endpoints but
which screens each role gets and what order each process' steps must follow.
`docs/MOBILE-API-UPDATED.md` is the superseded second version, kept only for
diffing; do not build from it. (The first version, `MOBILE-API.md`, is gone.)

What the NEW doc changed over UPDATED, and where the app stands on each:

- **The till sends a bill discount as a rate**: `orderDiscountPercent` (0–100),
  worked out by the server off the goods after line discounts. `Cart` holds
  `orderDiscountPercent`; a hold from an older build with a flat
  `orderDiscount` comes back as the equivalent rate. Built.
- **Nothing sells below cost** — a line under its `purchasePrice` after its
  discount, or a bill discount taking the basket under the cost of its goods,
  is `422 sale`. `Cart.belowCost` disables the pay button when the costs are
  known (never for a cashier without `view_cost`, never line-by-line for a
  package). The same rule is a `422` on every price form, so `PricingDraft`
  disables Save. Built.
- **The khata**: `GET /customers/search` `due` includes an `openingBalance`;
  checkout takes `collectPrevious: true` to settle old debt with today's bill
  (the server splits the tender — send what was typed), `payments: []` with a
  named customer is a bill wholly on credit, and the reply has `previousDue` and
  `outstanding`. Customers gain `openingBalance` / `invoiceDue` (both gated on
  `customers.credit.manage`, silently ignored otherwise) and ledger rows
  `opening` / `opening_correction`. Built. **Collecting an opening balance has
  no endpoint yet** — `POST /sales/{id}/payments` needs an invoice.
- **Invoices carry their arithmetic**: list rows gain `subtotal`, `discount`,
  `discountPercent` (the rate given, null ≠ 0), `discountRate` (derived — show
  as "≈"), `previousDue`; detail splits `lineDiscount` / `orderDiscount` and
  adds `mrpSaving` and per-item `mrp`, `mrpDiscount(Percent)`,
  `discountPercent`. Built.
- **Products carry a markup**: `profitPercent` (stated, null ≠ 0) and
  `profitRate` (derived), both null without `view_cost`. The form fills the
  selling price from cost + rate and sends both. `PATCH /products/{id}` now
  also takes the price set, but the app keeps prices on `PriceSheet` →
  `/prices` so the all-or-nothing rule lives in one place, and sends
  `isActive` **alone** (stop / resume selling on the detail screen).
  `GET /products/lookups` feeds the company and unit boxes. `openingStock`
  now defaults to 0 on `POST /products` (1 on catalogue adopt). Built.
- **`GET /pos/shift/report`** — the drawer's takings a day at a time, shown on
  the close sheet before the count. Built.
- **POS "New product"** when a search finds nothing, for
  `inventory.product.create`, then re-search and add. Built.
- **Sign-in**: `403 trial_ended` / `store_suspended` → `StoreLockedException`
  (message in the reader's language via `messageBn`); `/me` `store` gains
  `trial_ends_at` / `trial_days_left`, and the shell warns on the last day.
  Built. **Sign-up is built too**: `/register` (`RegisterScreen`) posts
  `POST /auth/register` and adopts the returned token straight into the new
  shop via `SessionController.register` — which, unlike `signIn`, leaves the
  session untouched on failure so the screen keeps its own errors. `409
  sign_in_to_add_store` sends the person to `/login?email=`; opening a second
  shop is `OpenStoreSheet` (`POST /stores` then switch-store) on Profile and on
  the no-store screen, with `GET /stores` `meta.locked` named there.
- **Later phases, not built**: `GET /dashboard?range=` (the whole owner's
  screen in one call, sections `null` when not permitted — phase 3), salary
  expenses (`isSalary`, `employeeName`, `salaryMonth`) and `employees[]` on
  `GET /accounts` (phase 3), `GET /suppliers/search`, `supplierName` on
  `POST /purchases`, `discountPercent` on purchases and bill photos
  `PATCH /admin/stores/{id}` and `/extend` (phase 4). (Phase 2's catalogue
  and purchase additions are built — see below.)

What the UPDATED doc had already changed (all built where the phase is):

- **`POST /sales/{id}/void`** now exists — `pos.sale.void`, `reason` required
  (3–255). A void is not a return: it undoes the entire sale (stock, money,
  debt, points) and the invoice stays on the list marked `void`, out of every
  revenue figure. `GET /sales/{id}` carries `meta.mayVoid`, true only for a
  **completed** invoice. Built in phase 1.
- **Manual products**: `POST /products`, `PATCH /products/{id}`, soft
  `DELETE /products/{id}` and `POST /products/{id}/restore`. `GET /products`
  gains `trashed=1`, `mrp`, `sku`, `trackBatch`, `deletedAt`,
  `meta.trashedCount`. Phase 2.
- **Catalogue** is now paginated and takes `mine=1` / `missing=1`
  ("Not in my store"), plus `GET /catalog/lookups` for units and brands, and
  entries carry `pending`. Phase 2.
- **`/admin/catalog`** (`admin.catalog.manage`) gives the platform direct
  control of the shared catalogue. Phase 4.

The build plan lives at `~/.claude/plans/piped-twirling-crab.md`. **Phases 0, 1
and 2 are done**; phase 3 (money and insight) is next. Phase 0 is the
transport/session/permission spine, login, a permission-built navigation shell
and a profile screen. Phase 1 is the counter: POS with camera scanning, cart,
customer picker, split payment, loyalty redemption, cash drawer and held carts;
invoices with returns, due collection and void; customers with ledger and
points. Phase 2 so far is `lib/features/products/`: the paginated product list
with `lowOnly` and the `trashed=1` list, product detail with movement and price
history, manual create / edit / soft-delete / restore, `PATCH
/products/{id}/prices` and `POST /products/{id}/adjust`; `lib/features/packages/`
(bundles CRUD with availability and date window); `lib/features/catalogue/`
(paged catalogue with All / In my store / Not in my store, adopt with the
catalogue's prices and MRP, suggest with a live `/catalog/check` verdict and the
`409` → `confirmedNew` resend, and the review queue); and
`lib/features/purchases/` (bill list, goods-in at `/purchase/new` with supplier
search or a new `supplierName`, batch/expiry lines, bill `discountPercent`,
paid-from account, and bill photos). Later phases add money, team and
platform; printing comes last.

Phase 2 details that are easy to break:

- **Bill photos are `multipart/form-data`**, the one non-JSON call, uploaded
  *after* `POST /purchases` succeeds and retried on their own — never part of
  the bill. `PurchasesRepository.uploadPhotos` passes a `FormData` and lets Dio
  write the boundary; the test asserts the content type.
- **Adopt defaults `openingStock` to 1, `POST /products` to 0.** Both forms
  always send the figure they show.
- **`/catalog/check` matches are snake_case** (`generic_name`, `reason_en`).
- **Accounts for paying a supplier** have no purchase endpoint: they come from
  `GET /accounts` or `/pos/lookups`, whichever the role may read, and a stock
  keeper sends no `accountId`.
- **The POS "added" confirmation lives in the cart bar**, not a snack bar: the
  shell's scaffold floats snack bars over the bar the cashier taps next.

`builtScreens` in `app_router.dart` lists the gates that have a real screen
behind them, and the landing screen after sign-in is the first *built* one a
person may reach. Without that, a cashier opened the app on the Dashboard
placeholder — its gate is `inventory.stock.view`, which a cashier holds — with
the till one tab away. Landing a phase means adding its `AppScreen` to both
`screenFor()` and `builtScreens`.

## Commands

```powershell
flutter pub get
flutter gen-l10n                 # after editing lib/l10n/*.arb (also runs during build)
flutter run --dart-define=BIZPOS_BASE_URL=http://10.0.2.2:8000/api/v1
flutter analyze                  # lints via flutter_lints (analysis_options.yaml)
flutter test                     # 169 tests
flutter test test/app/screen_gates_test.dart --plain-name "cashier"   # one test
flutter build apk --debug
```

The base URL defaults to `http://10.0.2.2:8000/api/v1` (how the Android emulator
reaches the host's `127.0.0.1`); pass a LAN address for a physical phone.

Android builds require **JDK 21** — `flutter config --jdk-dir` is pinned to
Temurin 21, because JDK 26's `jlink` breaks Gradle's `JdkImageTransform`. Do not
change it. `android/gradle.properties` also sets `kotlin.incremental=false`:
Kotlin's incremental compiler cannot reopen its caches under this project path
and fails every plugin module with "Could not close incremental caches".

## Structure

Feature-first over a hard `core/` spine. Riverpod 3 + go_router + Dio; DTOs are
hand-written (no codegen yet), and `/me` needs it that way.

```
lib/core/network/      ApiClient + 5 interceptors, typed ApiException, Envelope, Paged
lib/core/session/      SessionController (the app's root), token store, /me model
lib/core/permissions/  P constants, PermissionSet, PermissionGate
lib/core/theme/        tokens, AppPalette (ThemeExtension), AppTheme, preferences
lib/core/format/       Money (store currency), Exact (decimal), AppDates
lib/core/widgets/      states, AsyncView, app_sheet, fields (QtyStepper, AmountField)
lib/app/router/        GoRouter redirect, AppShell, screen_gates.dart, screenFor()
lib/features/          one folder per vertical: data/ (models + repository), ui/
```

`lib/app/router/screen_gates.dart` is section 4 of the doc as data. Both the
navigation shell and the route guards read it, so a menu entry and its route can
never disagree. `test/app/screen_gates_test.dart` asserts each role's exact
screen list — that test *is* the table, and it is what catches anyone building UI
from `role.name`.

Every gate gets a route whether or not its phase is built; `screenFor()` at the
bottom of `app_router.dart` picks the real screen or a `PlaceholderScreen`.
Landing a later phase is one line there. Detail routes (`/invoices/:id`,
`/customers/:id`) sit outside the gate table because they are not menu entries —
`gateForPath` matches them by prefix, so they inherit their parent's gate.

## API contract — invariants that affect every layer

These come from `docs/MOBILE-API-NEW.md` and are easy to get wrong once and
then everywhere. Build them into the HTTP client and the session layer, not into
individual screens.

- **Base URL** `https://<domain>/api/v1` (local `http://127.0.0.1:8000/api/v1`).
- **A void is not a return.** A return brings goods back and the invoice stands;
  `POST /sales/{id}/void` says the sale should not have happened and undoes all
  of it. Gate it on `pos.sale.void` **and** `meta.mayVoid`, never on the
  permission alone — the flag is what knows the invoice is still completed.
- **`PUT`/`PATCH`/`DELETE` must be sent as `POST`** with the real verb in the
  `X-HTTP-Method-Override` header. The production web server (LiteSpeed) rejects
  those verbs with an HTML 403 before Laravel sees them. `MethodOverrideInterceptor`
  does this globally, so repositories call `client.patch(...)` as the doc names
  it; an HTML-bodied 403 surfaces as `MethodOverrideException`, never as a
  permission problem.
- **Never retry a POST.** There is no idempotency key, so a retried
  `POST /pos/checkout` is a second sale. Retries stay opt-in and GET-only.
- **Auth is a Sanctum bearer token, one per device, 90 days.** The token itself
  carries the current store *and* branch, so no store id is ever sent per call.
  Store it in Keychain / EncryptedSharedPreferences. Switching store on one
  device does not move other devices.
- **Every record is fenced to the current store**; an id from another store
  returns 404, not 403.
- Request and response fields are camelCase — *except* `GET /me`, which returns
  some snake_case keys (`is_super_admin`, `store_type_id`, `label_bn`). Model it
  from the doc's literal example, not from the general convention.
- Errors are always `{"error": {"message", "code", ...}}`, mapped once in
  `error_interceptor.dart` to the sealed `ApiException` family — so no screen
  inspects a status code. Business-rule messages are shown verbatim; the server
  already wrote them for a person to read.
- A **burst of 401s** (a dashboard fires several calls at once) must sign out
  once. The latch in `UnauthenticatedInterceptor` stays shut until the next
  successful sign-in calls `allowSignOutAgain()`.
- Only `GET /sales`, `GET /products`, `GET /catalog` and `GET /admin/catalog`
  paginate (`?page=&perPage=`, `meta.total`, `meta.pages`). Other lists return a
  fixed recent window and accept `?q=` — `GET /customers` caps at 100, so
  narrowing the query *is* how you reach the hundred-and-first.
- Money is a plain JSON number in `store.currency` (usually BDT); dates are ISO
  8601 with offset, report buckets are `YYYY-MM-DD`.

## Permissions drive the UI

`GET /me` returns `permissions` (a flat list), `role`, `store`, `branch`,
`stores`, `branches`. **Build menus and buttons from `permissions`, never from
`role.name`** — an owner can revoke a single permission while the role name stays
the same. Use `PermissionGate` for buttons, `ref.can(P.x)` for logic, and
`screen_gates.dart` for anything screen-level.

`meta.may*` flags are **tri-state**: absent means the endpoint said nothing (so
the permission alone decides), false is an explicit denial. Evaluate as
`permission && (flag ?? true)` — `Meta.flag()` returns `bool?` for this reason,
and treating absent as false silently hides working buttons.

Two more consequences that shape models, not just widgets:

- The same endpoint returns **less** to a weaker role rather than failing: costs
  arrive as `null` or `0`, `loyaltyPoints` as `null`, profit as `null` with
  `showProfit: false`, `activity` empty. Every such field must be nullable and
  the UI must degrade, not crash.
- Some request fields are **silently ignored** without the permission —
  `unitPrice`/`discount`/`orderDiscountPercent` on checkout, `creditLimit` and
  `openingBalance` on customers.
  Never assume the echoed response equals what was sent.

`/me` is refreshed at start-up, after every store/branch switch, on
foreground-resume after 15 minutes, and after a 403 (which is evidence the local
permission list is stale).

## Store and branch scope

The token carries store and branch server-side, so no request sends a store id —
which means every cached screen is wrong the instant a switch happens, and
retained ids from the previous store answer **404, not 403**. `SessionScope`
(store, branch, epoch) is the invalidation key: **every repository provider must
start with `ref.watch(sessionScopeProvider)`**, and `scopeCancelTokenProvider`
cancels in-flight requests so a slow answer cannot land in the wrong store's
screen.

Roles: `super_admin`, `store_owner`, `manager`, `cashier`, `stock_keeper`,
`accountant`, `auditor`. The app is bilingual (English / বাংলা) — the API supplies
`label_bn` and a `locale` preference, so user-facing strings need localization
from the start.

## Scope boundaries

Section 7 of the doc lists permissions that exist in the role matrix but have
**no endpoint yet**: branch transfers, approving stock adjustments, purchase
edit/delete/return, supplier payments, deleting a customer, daily closing, VAT
report, exports, per-permission overrides, assigning a member to branches, print
templates, API keys, plans, push notifications. Do not build screens for these;
ask for the endpoint instead. The `P` constants for them are grouped at the
bottom of `permissions.dart` and marked, so nobody has to guess why a permission
has no UI.

## The counter (phase 1)

Three rules break silently rather than loudly, so they live in one testable
place each rather than in a widget:

- `Cart.toCheckoutBody()` decides which permission-gated fields travel.
  `unitPrice`, line `discount` and `orderDiscountPercent` are **ignored** without
  `pos.sale.change_price` / `pos.sale.give_discount` — sending them anyway is
  worse than an error, because the response comes back without them and nothing
  says why. `customerId` goes only for a *named* customer. `credit` and `points`
  are never payment methods: a due is paying less, points go in `redeemPoints`.
- **The server's total is the sale.** The cart's running figure is a preview
  computed with `decimal` (so `1.2 × 10` is not `11.999999999999998`); the
  receipt shows `POST /pos/checkout`'s own `total`, and `pointsRedeemed` is
  server-capped and routinely smaller than what was asked for.
- **Never retry a checkout.** `PaymentSheet` latches its button before the
  await, and the checkout call deliberately does *not* use the scope cancel
  token: a sale in flight during a branch switch must finish and be reported,
  not vanish.

Held carts round-trip JSON the server never reads, so `Cart.fromHoldJson` is
deliberately forgiving — a hold from an older build brings back the lines it
can rather than failing the resume.

Barcode scanning is `mobile_scanner`, debounced by (value, 800 ms) because MLKit
fires the same label many times a second. The sheet always offers a typed
barcode as well: a camera permission can be refused, and a till that only works
one way is a till that stops.

**Lists fetch through a provider, never through a future held in `initState`.**
The repository's `CancelToken` dies with the session scope, and the scope epoch
is bumped by the `/me` refresh on foreground-resume and after any 403. A search
started by hand in `initState` loses that race, comes back `CancelledException`,
and `AsyncView` renders that as a spinner with no retry — a till with no
products in it and no way to get any. `posSearchProvider` and
`posCustomerSearchProvider` are keyed on a value-type query so Riverpod re-runs
them against the new repository instead.

## Theme traps

`ButtonStyle.minimumSize` uses `Size(0, kMinTapTarget)`, **never**
`Size.fromHeight`. `Size.fromHeight` sets the minimum *width* to infinity, which
is harmless in a stretched `Column` and fatal in a `Row`: the button asserts
"BoxConstraints forces an infinite width" and paints as a grey box in release.
That one line broke the POS charge button, the resume button on a held cart and
"Use the most allowed" at once. Buttons that want the full width say so with a
`SizedBox` at the call site.

## Testing against the backend

Seeded demo accounts, password `bizpos123`: `super@bizpos.test`,
`owner@rahman.test`, `manager@rahman.test`, `cashier@rahman.test`,
`stock@rahman.test`, `accounts@rahman.test`. The appendix of the doc has a curl
recipe, including the correct shape of an overridden `PATCH`.
