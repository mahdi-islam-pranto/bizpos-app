# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`bizpos_app` is the Flutter mobile client for **bizPOS**, a multi-store retail POS
whose backend is an existing, running Laravel web workspace. `docs/MOBILE-API.md`
(~980 lines) is the spec of record: read the relevant section before writing any
feature — it defines not just endpoints but which screens each role gets and what
order each process' steps must follow.

The build plan lives at `~/.claude/plans/piped-twirling-crab.md`. **Phase 0 is
done**: the whole transport/session/permission spine plus login, a
permission-built navigation shell with placeholder tabs, and a profile screen.
Phase 1 is the counter (POS, invoices, customers). Later phases add inventory,
money, team and platform; printing comes last.

## Commands

```powershell
flutter pub get
flutter gen-l10n                 # after editing lib/l10n/*.arb (also runs during build)
flutter run --dart-define=BIZPOS_BASE_URL=http://10.0.2.2:8000/api/v1
flutter analyze                  # lints via flutter_lints (analysis_options.yaml)
flutter test                     # 61 tests
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
lib/app/router/        GoRouter redirect, AppShell, screen_gates.dart
lib/features/          one folder per vertical
```

`lib/app/router/screen_gates.dart` is section 4 of the doc as data. Both the
navigation shell and the route guards read it, so a menu entry and its route can
never disagree. `test/app/screen_gates_test.dart` asserts each role's exact
screen list — that test *is* the table, and it is what catches anyone building UI
from `role.name`.

## API contract — invariants that affect every layer

These come from `docs/MOBILE-API.md` and are easy to get wrong once and then
everywhere. Build them into the HTTP client and the session layer, not into
individual screens.

- **Base URL** `https://<domain>/api/v1` (local `http://127.0.0.1:8000/api/v1`).
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
- Only `GET /sales` and `GET /products` paginate (`?page=&perPage=`, `meta.total`).
  Other lists return a fixed recent window and accept `?q=`.
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
**no endpoint yet** (manual product create/edit/delete, invoice void, branch
transfers, supplier payments, daily closing, VAT report, exports, per-permission
overrides, push notifications). Do not build screens for these; ask for the
endpoint instead.

## Testing against the backend

Seeded demo accounts, password `bizpos123`: `super@bizpos.test`,
`owner@rahman.test`, `manager@rahman.test`, `cashier@rahman.test`,
`stock@rahman.test`, `accounts@rahman.test`. The appendix of the doc has a curl
recipe, including the correct shape of an overridden `PATCH`.
