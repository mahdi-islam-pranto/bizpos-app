
# bizPOS mobile app — build plan

## Context

`bizpos_app` is still the stock `flutter create` scaffold: `lib/main.dart`, one
widget test, no dependencies beyond `cupertino_icons`. The entire product
definition lives in `docs/MOBILE-API.md` — a finished, running Laravel API that
already exposes every process of the bizPOS web workspace: selling, invoices and
returns, dues, customers, products and stock, packages, the shared catalogue,
purchases, accounts and expenses, reports, team and store settings, and a
super-admin section, with a server-side permission check on every call.

So this is not a "design the system" project. The server is the system, and it is
authoritative on money, stock, discounts and permissions. The job is a faithful,
**permission-driven client**: seven roles must each see only their own app, and
the UI must stay minimal enough that a cashier can run it one-handed at a counter.

The real difficulty is concentrated in three places, and almost none of it is in
screens:

1. **Transport** — `PUT`/`PATCH`/`DELETE` must travel as `POST`, envelopes must be
   unwrapped, errors must become types, and a particular HTML 403 must be caught.
2. **Session** — token + `/me` + permission set + (store, branch) scope, where a
   scope change has to atomically invalidate every cached screen.
3. **Permissions** — ~45 gate/action strings, plus `meta.may*` flags that can
   narrow further, plus responses that *degrade* (nulls and zeros) instead of
   failing for weaker roles.

Everything after that is ~14 feature verticals of CRUD over the same spine.

Decisions taken up front:

| Decision                | Choice                                                                         |
| ----------------------- | ------------------------------------------------------------------------------ |
| Scope order             | Counter-first (login → POS → invoices → customers), then widen              |
| Architecture            | Riverpod + go_router + Dio, feature-first                                      |
| Offline                 | Online-first; small read-cache for POS lookups.**No offline sale queue** |
| Phase 1 device features | Camera barcode scanning, Bangla + English, dark mode                           |
| Deferred                | Bluetooth thermal printing, HID sled scanners                                  |

The user asked for a **very small, verifiable version first**, so Phase 0 is a
deliberately tiny vertical slice — real login against the real API, `/me`, a
themed shell with a permission-built menu, and nothing else. Every later phase is
additive and ends in something you can open and judge.

---

## Design language

Minimal, light green and white. Flat surfaces, no gradients, no card shadows
(hairlines instead), generous spacing, one accent used sparingly so that green
*means* something: primary action, money in, success.

Tokens live in `lib/core/theme/` and nothing else in the app names a raw colour.
The palette is exposed as a `ThemeExtension` with **semantic** slots — screens say
`palette.positive`, never `Colors.green`:

```
Light                                       Dark (midnight)
bg         #F5FAF7  white with a green cast  #0E1512
surface    #FFFFFF                           #161F1B
surfaceAlt #F2F8F4  grouped rows, chips      #1B2621
accent     #1E9D63  primary action, active   #4FD198
onAccent   #FFFFFF                           #06120C
hairline   #E3EEE7  1px, replaces elevation  #23302A
text       #11201A                           #ECF3EF
muted      #63756B                           #92A39A
positive   #1E9D63  paid, in stock           #4FD198
warning    #B4761A  partial, low stock       #E0A542
danger     #C4443B  unpaid, damage, void     #F08079
```

- Spacing is a 4pt scale (`s4 s8 s12 s16 s24 s32`); radii `r8` rows, `r12` sheets,
  `r999` pills; exactly one elevation level, used only for bottom sheets.
- Typography: `Inter` for Latin, `Noto Sans Bengali` for Bangla, both **bundled as
  assets** (not `google_fonts` — a counter with bad wifi must not wait on a font
  fetch), with `fontFamilyFallback` covering both in either locale because mixed
  strings like `INV-005521 · রহিম` are constant. Bengali gets more line height
  (`1.45` vs `1.25`).
- Money goes through one formatter reading `store.currency`, with tabular figures
  so columns line up. Any client-side arithmetic uses `decimal`, never `double` —
  `1.2 × 10` must not render as `11.999999`.
- Core widgets built once in `lib/core/widgets/`: `AppScaffold`, `AppButton`
  (filled/tonal/text), `AppTextField`, `AppListTile`, `SectionHeader`, `AsyncView`,
  `EmptyState`, `ErrorView`, `LoadingList` (skeletons), `AppBottomSheet`,
  `ConfirmSheet`, `AmountField`, `NumPad`, `QtyStepper`, `ForbiddenTile`.

### The API's five themes

`PATCH /me/preferences` accepts `daylight`, `midnight`, `workspace`, `paper`,
`contrast`. Building five distinct looks contradicts "very minimal", so v1 ships
**two**: `daylight` (the light-green default) and `midnight` (dark). The other
three resolve to their nearest sibling for rendering, but the app **stores the
server's value unchanged** and PATCHes back only what the user actually picked —
so a `paper` preference set in the web workspace is never clobbered by the phone.
`workspace` (denser) and `contrast` (AAA) can be added later as palette recipes
without touching a screen. Unknown values fall back to `daylight` rather than
erroring.

---

## Architecture

Feature-first with a hard `core/` spine. Inside a feature, a light `data/` +
`presentation/` split — no use-case classes for what is one HTTP call.

```
lib/
  main.dart                      ProviderScope + BizposApp
  app/
    bizpos_app.dart              MaterialApp.router; theme + locale from session
    router/
      app_router.dart            GoRouter; redirect = the boot state machine
      permission_guard.dart      route-level gate -> /not-allowed
      app_shell.dart             bottom nav generated from permissions
      screen_gates.dart          doc section 4's table, as data
  core/
    env.dart                     base URL via --dart-define
    network/
      api_client.dart            get/post/patch/delete -> Envelope<T>
      envelope.dart              { data, meta }, meta.flag() -> bool?
      paged.dart                 ONLY for /sales and /products
      api_paths.dart             every path string, once
      api_exception.dart         sealed hierarchy
      interceptors/              auth, method_override, error, unauthenticated, logging
    session/
      session_state.dart         Unknown | LoggedOut | NoStore | Active
      session_controller.dart    login, /me, switch store/branch, logout
      session_scope.dart         (storeId, branchId, epoch) with value equality
      token_store.dart           flutter_secure_storage, failure-tolerant
      me_cache.dart              last /me snapshot for an instant cold start
      lifecycle_refresher.dart   refresh /me on foreground after ~15 min
    permissions/
      permissions.dart           const P.posSaleCreate = 'pos.sale.create' ...
      permission_set.dart        has / hasAny / hasAll, super-admin short-circuit
      permission_gate.dart       PermissionGate(perm:, alsoRequire:, child:)
    cache/read_cache.dart        tiny JSON snapshot cache, namespaced by scope
    theme/  tokens.dart palette.dart typography.dart theme.dart theme_controller.dart
    l10n/   app_en.arb app_bn.arb
    format/ money.dart dates.dart numerals.dart
    widgets/ ...
  features/
    auth/ home/ pos/ sales/ customers/ products/ packages/ catalog/
    purchases/ accounts/ reports/ settings/ admin/
  shared/
    scanner/    camera scanner sheet (+ HID wedge listener, later)
    printing/   receipt renderer + ESC/POS raster (Phase 5)
```

### `ApiClient` — where the API's quirks get solved once

```
AuthInterceptor → MethodOverrideInterceptor → LoggingInterceptor
   → network →
ErrorInterceptor → UnauthenticatedInterceptor
```

**Method override.** Every request the app writes as `PUT`/`PATCH`/`DELETE` is
rewritten to `POST` with `X-HTTP-Method-Override: <real verb>`. Feature code calls
`api.patch(...)` and never thinks about it, so the code reads like the spec:

```dart
const _overridable = {'PUT', 'PATCH', 'DELETE'};
if (_overridable.contains(m)) {
  options.headers['X-HTTP-Method-Override'] = m;
  options.method = 'POST';
}
```

This is non-negotiable: the production host (LiteSpeed) answers the real verbs
with its own HTML 403 before Laravel is reached — and it *works locally*, which is
what makes it a deployment-day bug rather than a development one.

**Typed errors**, so no screen ever inspects a status code:

| Server                            | Exception                    | App behaviour                                            |
| --------------------------------- | ---------------------------- | -------------------------------------------------------- |
| 401`unauthenticated`            | `UnauthenticatedException` | wipe token → login (debounced, see below)               |
| 403`forbidden` + `permission` | `ForbiddenException`       | hide the action; refresh`/me` once                     |
| 403 with an**HTML** body    | `MethodOverrideError`      | the override was lost —`assert` in debug              |
| 422`validation` + `fields`    | `ValidationException`      | bind field → message under each input                   |
| 422 business code                 | `BusinessRuleException`    | show`message` verbatim                                 |
| 409`already_in_catalog`         | `ConflictException`        | carries`match`, `alreadyInStore`                     |
| 404                               | `NotFoundException`        | **"not available in this store"**, not "not found" |
| 400`bad_request`                | `NoStoreException`         | route to the no-store*screen*, not a toast             |
| 429                               | `RateLimitedException`     | countdown; never auto-retry login                        |
| timeout / socket                  | `NetworkException`         | offline state                                            |

Three behaviours that are easy to miss:

- **401 storms.** A dashboard fires 4–6 parallel calls; a revoked token yields 6
  simultaneous 401s. `UnauthenticatedInterceptor` holds a `_loggingOut` flag so
  logout and navigation happen exactly once.
- **A 403 is evidence the local permission set is stale** (an owner just revoked
  something). Refresh `/me` once on a 403, then show the message.
- **`meta.may*` is tri-state.** Absent ≠ false: absent means the endpoint didn't
  say, false means explicitly denied. Modelled as `bool?`, evaluated as
  `perm && (flag ?? true)`. Treating absent as false silently hides working buttons.

**Never retry a POST.** There is no idempotency key, so an auto-retried
`POST /pos/checkout` creates a duplicate sale. Retry is opt-in and GET-only. On a
checkout timeout the app shows a dedicated "we're not sure that sale went through"
screen that searches `GET /sales?days=1&q=<phone>` so the cashier can confirm
before trying again.

**Pagination is structurally separated.** `Paged<T>` exists at exactly two call
sites (`GET /sales`, `GET /products`); every other list uses a
`RecentWindowList` widget with a "latest 50 — search to narrow" footer. Wiring
infinite scroll to a non-paginated endpoint is the most likely early bug, so the
two cases are different types.

### Session

```dart
sealed class SessionState {
  const factory SessionState.unknown();       // splash
  const factory SessionState.loggedOut();
  const factory SessionState.noStore(Me me);  // store == null
  const factory SessionState.active({ required Me me, required SessionScope scope, ... });
}
```

`SessionController` owns boot (token → hydrate from `MeCache` for an instant first
frame → `GET /me`), login, `refreshMe()`, store/branch switching, impersonation
and `forceLogout()`. `/me` is refetched at start-up, after every switch, on
foreground-resume after ~15 minutes, and after a 403 — an owner may have changed
the person's role meanwhile.

Details that bite:

- `/me` returns some **snake_case** keys (`is_super_admin`, `store_type_id`,
  `label_bn`) while the rest of the API is camelCase. Hand-written `@JsonKey`
  bindings for that one response, pinned by a fixture test using the doc's literal
  example.
- `flutter_secure_storage` can throw on Android after a backup restore or keystore
  reset. Every read is wrapped: a failed read means *logged out*, not a crash. Set
  `android:allowBackup="false"` so a restored token from another device never
  appears.
- The token lasts 90 days. Within 7 days of `expiresAt`, show a banner; at expiry,
  pre-emptively go to login rather than letting a checkout fail.

Permissions are string constants in `permissions.dart`, consumed three ways:
`ref.can(P.x)` for logic, `PermissionGate` to hide a button, and the router's
`permission_guard` so a deep link to a forbidden screen redirects instead of
rendering a 403. `screen_gates.dart` encodes the doc's section 4 table as data, and
**both the nav shell and the route guards read from it**, so a menu item and its
route can never disagree. Constants for section 7's endpoint-less permissions are
marked `// NO ENDPOINT — doc §7` and have no gate entry.

Menus are built from `permissions`, never `role.name` — an owner can revoke a
single permission while the role name stays `cashier`. The auditor then falls out
for free: a read-only role simply fails every action gate, with no
`if (role == auditor)` anywhere.

### Store / branch switching

The token carries store and branch server-side, so no request sends a store id —
which means **every cached screen is wrong the instant a switch happens**, and every
retained record id becomes a cross-store 404.

One value type solves it: `SessionScope(storeId, branchId, epoch)`. **Every
repository provider begins with `ref.watch(sessionScopeProvider)`**, so Riverpod
disposes and refetches the whole dependent graph when the scope changes. `epoch`
lets `refreshMe()` force the same invalidation when a role changed but the store
did not. Three supporting measures:

- In-flight requests are cancelled via a per-scope `CancelToken` disposed with the
  scope, so a slow store-A response cannot land in a store-B screen.
- On a **store** switch, reset the navigation stack (`router.go('/')`) and rebuild
  the shell under a `ValueKey(scope.storeId)`, since permissions themselves changed.
- **Impersonation is just a store switch** (epoch bump + nav reset) plus a
  non-dismissible "Support mode" banner. Record the admin's own store id *before*
  impersonating, so the exit (`POST /auth/switch-store`) has somewhere to go.

### Caching (online-first)

Deliberately small: a JSON snapshot cache (`shared_preferences`, namespaced by
scope key) holding only `pos/lookups`, the recent product-search results,
`products/stats` and the last `/me`. Served instantly, revalidated in the
background. **No local database** — a mirror of a store-fenced, permission-degraded
dataset is a correctness trap (stale rows that 404 after a switch) and there are no
offline writes to justify one.

Writes always go to the network. Interrupted sales use the server's own hold
endpoints (`POST /pos/hold` stores opaque cart JSON), so no local sale queue is
invented. Two caveats there: stamp the cart `{"v": 1, ...}` and refuse gracefully
on a version mismatch, because the server hands the same JSON back months and app
versions later; and **re-resolve every line against `pos/search` on resume**, since
held prices and stock are stale.

### Packages

| Concern            | Package                                                                                       |
| ------------------ | --------------------------------------------------------------------------------------------- |
| State / DI         | `flutter_riverpod` + `riverpod_annotation` (replaces a DI container)                      |
| Routing            | `go_router`                                                                                 |
| HTTP               | `dio` (+ `http_mock_adapter` for tests)                                                   |
| Models             | `json_serializable`; `freezed` only for sealed unions (errors, cart, session state)       |
| Secure token       | `flutter_secure_storage`                                                                    |
| Prefs / cache      | `shared_preferences`                                                                        |
| Money arithmetic   | `decimal`                                                                                   |
| Barcode            | `mobile_scanner`                                                                            |
| i18n               | `flutter_localizations` + `intl`, ARB + `l10n.yaml`                                     |
| Connectivity       | `connectivity_plus` (offline banner and a pre-checkout guard)                               |
| Device name        | `device_info_plus` (`deviceName` appears in the device list)                              |
| Charts             | `fl_chart` (Phase 3)                                                                        |
| Printing (Phase 5) | `esc_pos_utils_plus`, `print_bluetooth_thermal`, `image`, optional `printing`/`pdf` |

Avoided: **Hive/Drift/Isar** (no offline writes; see above), **`dio_smart_retry`**
(would duplicate sales), **`retrofit`** (would fight the method-override trick),
**GetX / provider / get_it** (redundant or no invalidation primitive),
**`easy_localization`** (no compile-time checking across ~800 strings × 2 locales),
**Firebase** (push has no endpoint — doc §7), and any UI kit (the design is too
specific and too minimal to fight a component library).

---

## Phases

### Phase 0 — the small verifiable version *(look at this first)*

One screen of real work, end to end, against the live API. Deliberately tiny — but
the entire spine is built here, because retrofitting the interceptors later means
touching every repository.

1. `pubspec.yaml`: Riverpod, go_router, Dio, json_serializable/build_runner,
   freezed, flutter_secure_storage, shared_preferences,
   flutter_localizations/intl, device_info_plus. Fonts bundled. `l10n.yaml`.
2. `core/theme/` — the palette above, light + dark, tokens, typography.
3. `core/network/` — Dio client, all five interceptors (**including** the method
   override and the full typed-error mapping), `Envelope`, `Paged`, `api_paths`.
4. `core/session/` + `core/permissions/` — `POST /auth/login`, secure token,
   `GET /me`, `MeCache`, logout, `SessionScope`, `P` constants, `PermissionGate`.
5. `core/l10n/` — English + Bangla ARB, language toggle that also PATCHes
   `/me/preferences`.
6. Screens: **Login**, **Home shell** (bottom nav generated from `permissions`,
   each tab a labelled placeholder), **Session/Profile** (name, role, store,
   branch, store + branch pickers when there is more than one, theme and language
   toggles, device list with remote sign-out, logout).
7. Base URL via `--dart-define=BIZPOS_BASE_URL`, defaulting to
   `http://127.0.0.1:8000/api/v1`.

**How you verify it:** sign in as each seeded account (`owner@`, `manager@`,
`cashier@`, `stock@`, `accounts@rahman.test`, `super@bizpos.test`, password
`bizpos123`) and confirm the bottom nav differs per role from a single build;
Bangla and dark mode both look right; a wrong password shows a field error rather
than a crash; a hand-forced bad token bounces to login exactly once; logout
returns to login. One screen's worth of UI — with everything hard already solved.

### Phase 1 — the counter (a cashier's whole day)

- **POS**: `GET /pos/lookups` on open; `GET /pos/search` with camera scanning
  (exact barcode match is `data[0]`, straight into the cart, debounced by
  (value, 800 ms) with a beep so MLKit's repeat reads register once);
  `GET /packages/sellable` for bundles; cart with `QtyStepper` and a stock warning
  when `qty > stock`; customer picker via `GET /customers/search` (2+ chars) with
  `POST /customers/quick` inline (honouring `created: false` when the phone
  exists); price and discount fields rendered **only** with
  `pos.sale.change_price` / `pos.sale.give_discount`, since the server ignores them
  otherwise; loyalty redeem when `loyalty.mayRedeem`; split payment over
  `lookups.accounts` (never sending `credit` or `points` as a method — a due is
  simply paying less); `POST /pos/checkout` → success sheet showing the **server's**
  total, invoice number and `pointsRedeemed` (which is server-capped and will often
  be less than requested).
- **Cash drawer**: open/close, with the expected/counted/difference summary and the
  `shift_open` / `no_shift` codes shown as plain messages.
- **Held carts**: hold, resume (with re-resolution), discard.
- **Invoices**: paginated `GET /sales` with `q` and `days`, `meta.summary` strip,
  detail from `GET /sales/{id}`, an on-screen receipt, returns and due collection
  gated on `meta.mayReturn` / `meta.mayCollect`.
- **Customers**: list, search, create/edit, ledger, points — `creditLimit` only
  offered with `customers.credit.manage`.

Demoable as: open drawer → sell → hold → resume → collect a due → close drawer,
including a correctly-rendered `insufficient_stock` refusal and a credit refusal.

### Phase 2 — inventory and goods in

Products (paginated, `lowOnly`, `meta.showCost`), detail with `history`
(`movements` + `prices`), `PATCH /products/{id}/prices`, stock adjust (signed,
non-zero, damage flag), `products/stats` alerts, packages CRUD with
`availability`/`buildable`, the catalogue flow (`/catalog` search → adopt;
`/catalog/check` verdicts while typing; suggest, with the `409 already_in_catalog`
→ `confirmedNew` resend; the review queue), purchases with supplier create and the
goods-in form (batch + expiry).

### Phase 3 — money and insight

`GET /accounts` (balances, one-tap quick-expense tiles, full expense form,
`categoryName` auto-create, delete/refund, transfers), the four reports, and the
role-shaped dashboard — the owner's tiles fanned out in parallel, each tile its own
provider wrapped in `ForbiddenTile` so a manager's 403 on profit doesn't kill the
page; the cashier/stock-keeper's smaller version from `products/stats` and the open
shift. Reports label their scope, because sales, stock and profit's revenue/cost
are **per branch** while returns, expenses and dues are **store-wide**.

### Phase 4 — team, store and platform

`GET /settings` (members, roles, branches, store settings, loyalty), add member
(`plan_limit`), suspend/reactivate by **`storeUserId`**, change role by **user
`id`** (two different identifiers on adjacent rows — easy to swap), activity log,
and the super-admin section (overview, create store, suspend, impersonate with the
support banner, shared-catalogue review).

### Phase 5 — printing and polish

Bluetooth thermal receipts, then an empty/error-state pass, offline banner and an
accessibility sweep (tap targets, contrast in both themes).

**The receipt must be rendered as an image, not as text.** No ESC/POS codepage
covers Bengali; sending UTF-8 yields garbage. So the receipt is a Flutter widget →
`RepaintBoundary` PNG → 1-bit raster, for *both* locales so there is a single
uniform path: 384px wide for 58mm, 576px for 80mm, driven by
`settings.receiptPaper`, with an A4/PDF share fallback. Pre-warm the renderer so
the first print isn't slow.

**Not built:** everything in section 7 of the doc has no endpoint yet (manual
product create/edit/delete, invoice void, branch transfers, adjustment approval,
supplier payments, daily closing, VAT report, exports, per-permission overrides,
push notifications). These will be *asked for*, because the permission matrix
lists them — the answer is that they need the endpoint first.

---

## Pitfalls this plan deliberately guards against

| Pitfall                                                             | Guard                                                                                               |
| ------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| A real`PATCH`/`DELETE` reaching production → HTML 403          | Global override interceptor; a distinct`MethodOverrideError` if an HTML body ever appears         |
| A timed-out checkout retried → duplicate sale                      | No retries on POST; a "did that sale go through?" reconciliation screen                             |
| UI built from`role.name` → breaks when one permission is revoked | Only`permissions` is consulted; `role` is display text; a guard test enforces it                |
| Stale data or cross-store 404s after a switch                       | `sessionScopeProvider` watched by every repo; scoped `CancelToken`; nav reset on store switch   |
| Client-computed totals disagreeing with the invoice                 | No client-side field named`total` before checkout; only `≈ estimated subtotal`                 |
| `0`/`null` costs rendered as real numbers to a cashier          | Nullable models +`meta.showCost` / `showProfit` drive visibility                                |
| Silently ignored`unitPrice` / `discount` / `creditLimit`      | Those inputs aren't rendered without the permission; never re-render sent values, only the response |
| `meta.may*` absent treated as false → working buttons hidden     | Tri-state`bool?`, evaluated `perm && (flag ?? true)`                                            |
| Six parallel 401s → six logouts                                    | Debounce flag in`UnauthenticatedInterceptor`                                                      |
| `400 bad_request` shown as a toast to a suspended member          | Routes to a dedicated no-store screen with sign-out                                                 |
| `storeUserId` vs user `id` on member endpoints                  | Distinct Dart types so they can't be passed interchangeably                                         |
| `/me`'s snake_case keys                                           | Hand-written bindings + a fixture test on the doc's literal example                                 |
| Report`YYYY-MM-DD` buckets parsed then `toLocal()`'d            | `Dates.parseBucket` returns date-only and never converts — otherwise a BD day shifts on UTC CI   |
| Bangla digits or Bengali text sent to the API / a printer           | Bangla numerals are display-only, inputs ASCII-only; receipts print as raster                       |
| A held cart from an older app version                               | Versioned cart JSON; graceful refusal on mismatch; prices re-resolved on resume                     |
| Login retry loop hitting the 10/min limit                           | No retry on`/auth/login`; 429 shows a countdown                                                   |
| Secure-storage read throwing after a backup restore                 | Wrapped reads → logged out, not a crash;`allowBackup="false"`                                    |

---

## Verification

- `flutter analyze` and `flutter test` clean at the end of every phase.
- **Transport unit tests** (highest value per line, all via `http_mock_adapter`):
  a table test asserting each of PUT/PATCH/DELETE leaves the client as a POST
  carrying the right override header while GET/POST are untouched; one case per row
  of the error table above, including the HTML-403 → `MethodOverrideError`; auth
  header present everywhere and absent on `/auth/login` and `/public/permissions`;
  `Envelope`/`meta.flag` tri-state.
- **DTO fixture tests**: every JSON example in `docs/MOBILE-API.md` copied verbatim
  into `test/fixtures/` and asserted to parse — the cheapest defence against drift,
  and what pins the `/me` snake_case trap. A second set of *degraded* fixtures
  (cashier `pos/search` with `purchasePrice: null`, `products` with
  `showCost: false`, `reports/sales` with `showProfit: false`) asserts nullability
  actually holds.
- **The section 4 table, executable**: six role permission fixtures × the 13
  screens, asserting the nav shell shows exactly the expected set. This single test
  catches the "built from role.name" regression immediately.
- **Session/scope tests**: the boot state machine (no token → loggedOut; token +
  401 → token wiped → loggedOut; `store == null` → noStore; happy path → active);
  and a fake repo that counts fetches, asserting `switchBranch` triggers exactly one
  refetch and cancels in-flight requests.
- **Goldens**: a component gallery plus the POS cart in light × dark × en × bn —
  where a minimal design regresses invisibly, and where Bengali (typically 20–40%
  wider) overflows. Pin the font loader so CI matches local. The receipt gets its
  own golden at both widths once Phase 5 lands; it is a customer-facing document.
- **Manual, per phase**: run against the local backend
  (`http://127.0.0.1:8000/api/v1`) and sign in as each seeded role in turn — the
  role map in section 4 is the checklist. Confirm a cashier sees no costs, an
  auditor sees no write buttons, a manager has no profit tab.
- Android builds need **JDK 21** (`flutter config --jdk-dir` is already pinned to
  Temurin 21; JDK 26 breaks Gradle's `JdkImageTransform`).
