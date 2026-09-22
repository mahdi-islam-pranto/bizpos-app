# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`bizpos_app` is the Flutter mobile client for **bizPOS**, a multi-store retail POS
whose backend is an existing, running Laravel web workspace.
**`docs/MOBILE-API-UPDATED.md` (~1080 lines) is the spec of record** — read the
relevant section before writing any feature. It defines not just endpoints but
which screens each role gets and what order each process' steps must follow.
`docs/MOBILE-API.md` is the superseded first version, kept only for diffing; do
not build from it.

What the updated doc changed (all of it is in section 7's shrinking list):

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

The build plan lives at `~/.claude/plans/piped-twirling-crab.md`. **Phases 0 and
1 are done.** Phase 0 is the transport/session/permission spine, login, a
permission-built navigation shell and a profile screen. Phase 1 is the counter:
POS with camera scanning, cart, customer picker, split payment, loyalty
redemption, cash drawer and held carts; invoices with returns, due collection
and void; customers with ledger and points. Later phases add inventory, money,
team and platform; printing comes last.

## Commands

```powershell
flutter pub get
flutter gen-l10n                 # after editing lib/l10n/*.arb (also runs during build)
flutter run --dart-define=BIZPOS_BASE_URL=http://10.0.2.2:8000/api/v1
flutter analyze                  # lints via flutter_lints (analysis_options.yaml)
flutter test                     # 89 tests
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

These come from `docs/MOBILE-API-UPDATED.md` and are easy to get wrong once and
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
  `unitPrice`/`discount`/`orderDiscount` on checkout, `creditLimit` on customers.
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
  `unitPrice`, line `discount` and `orderDiscount` are **ignored** without
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

## Testing against the backend

Seeded demo accounts, password `bizpos123`: `super@bizpos.test`,
`owner@rahman.test`, `manager@rahman.test`, `cashier@rahman.test`,
`stock@rahman.test`, `accounts@rahman.test`. The appendix of the doc has a curl
recipe, including the correct shape of an overridden `PATCH`.
