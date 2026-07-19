# Mobile Module Architecture Standard

## Purpose

Use this standard for every feature under `lib/features/`. It keeps modules
independent, predictable to navigate, and consistent in their loading, error,
mutation, and refresh behaviour.

The canonical references are:

- **Inventory** for read-oriented modules with filters, pagination, lookup,
  detail, and history.
- **Consignment** for record-oriented workflows with a draft, child items, and
  an irreversible confirmation step.

Disposal should use the Consignment lifecycle and the Inventory conventions for
selecting lots and refreshing inventory after confirmation.

## Feature Layout

Each module owns its feature-specific code.

```text
lib/features/<module>/
  data/
    models/          // API DTOs and JSON mapping only
    repositories/    // Dio calls, response parsing, typed app errors
  presentation/
    providers/       // Riverpod query state and async providers
    screens/         // page composition, local form/filter state, navigation
    widgets/         // reusable module-only UI pieces
```

Do not place feature repository calls directly in screens. Do not put widgets
or navigation in models, repositories, or providers.

Shared code belongs in `lib/core/`, `lib/router/`, or `lib/shared/` only when it
is genuinely used by more than one module. For example, master-data pickers
should eventually live in a shared master-data feature rather than being
imported from Stock In.

## Data Flow

```text
GoRouter route
  -> Screen owns transient UI state (controller, selected tab, draft form)
  -> Riverpod provider receives an immutable query/key
  -> Repository calls authenticated Dio
  -> Model maps API JSON
  -> AsyncValue renders loading | error/retry | data
```

### Models

- Keep models immutable and API-shaped.
- Use `fromJson` factories; safely handle missing optional data.
- Use a feature-local brief model when the response contains nested data.
- Keep display formatting in UI helpers/widgets, not models.

### Repositories

- One repository per feature, provided with `Provider` and `dioProvider`.
- Put all endpoint paths in `core/constants/api_endpoints.dart`.
- Unwrap the API's `data` envelope consistently.
- Parse `{ data: [], pagination: {} }` into a typed page result.
- Convert `DioException` to `AppException`; do not expose raw HTTP mechanics to
  a screen.
- Keep request keys and values aligned with the backend contract. Omit blank
  optional filters when the API expects omission.

### Providers and query objects

- Use `FutureProvider.autoDispose.family` for server reads.
- Provider arguments must be immutable and implement value equality so caching
  and invalidation use the right request identity.
- Put reusable filter state in an immutable `Filter`/`Query` object.
- Use a notifier only when several widgets/screens must share editable filter
  state. Local screen state is preferred for a screen-private query.
- Providers orchestrate repository calls; business mutations remain explicit
  repository calls from the owning screen/form.

### Screens and widgets

- Screens own text controllers, focus, local tabs, dialogs, navigation, and
  form validation. Dispose controllers.
- Every async screen must render loading, empty, error, and retry states.
- Use existing shared theme and widgets (`ModuleAppBar`, `ContentCard`,
  `AppErrorWidget`, `AppTextField`) before creating equivalents.
- Keep module-specific cards, badges, and tiles in the module's `widgets/`.

## Module Shapes

### Read-oriented module

Use this shape for Inventory-style features.

```text
List/filter screen -> detail screen -> related history/lookup screens
```

- A query object contains search, filters, page, and page size.
- Changing a filter resets the page to one.
- Provider families fetch a page based on that query.
- Detail providers are keyed by the record ID.
- Refresh and Retry invalidate the exact provider/query instance.

### Draft-to-confirm module

Use this shape for Consignment, Disposal, and similar inventory transitions.

```text
List -> create draft -> edit header -> add/remove items -> review -> confirm
```

- Model lifecycle is explicit, normally `draft` then `confirmed`.
- Only drafts can change headers or items.
- Confirmation uses a deliberate dialog and relies on the backend for atomic
  validation and state transition.
- A confirmed record displays audit metadata and does not expose draft actions.
- Do not implement post-confirm edits or cancellation unless the backend
  contract and audit rules explicitly support them.

For Disposal, confirmation must cause the affected lots to become `disposed`
and emit inventory movements. The app should then refresh both Disposal and
Inventory views.

## Routing

- Define paths and path helpers in `router/route_names.dart`.
- Register every path in `router/app_router.dart`; a route constant alone is
  not a usable route.
- Parse only route IDs in the router and pass typed IDs into screens.
- Use `push` for drill-down/create flows and `go` for a deliberate module or
  dashboard destination.

## Mutation and Cache Refresh Rules

After a successful mutation:

1. Invalidate the affected module's list, detail, and item providers.
2. Invalidate all derived data changed by the action.
3. Navigate only after success; show a success or failure message.

For inventory-changing confirmations (Stock In, Consignment, Disposal, Returns):

- Refresh Inventory unit/detail, product/set availability, expiring-soon, and
  ledger providers where relevant.
- Refresh Dashboard summary data.
- Do not optimistically change lot status unless the backend contract supports
  a safe rollback strategy.

## Cross-Module Dependencies

- Depend on another feature's UI or repository only as a temporary bridge.
- Prefer shared contracts/models for cross-module concepts such as searchable
  lots, products, suppliers, and barcode scanning.
- A module must not reach into another module's private UI state.
- Inventory is the system of record for lot availability and movements; modules
  that change stock must refresh it rather than duplicating its state.

## Testing Standard

Each new module should include:

- **Model tests:** required, optional, nested, and null JSON fields.
- **Repository tests:** method/path, query parameters, payload, data-envelope
  parsing, pagination, and error conversion using an intercepted `Dio` client.
- **Provider tests:** query identity and repository delegation for non-trivial
  filters/state.
- **Widget tests:** loading, error/retry, empty state, required validation, and
  draft-only versus confirmed-only actions.
- **Flow verification:** create/edit draft, add valid and invalid items,
  confirm, and verify all affected Inventory and Dashboard data refresh.

Run at minimum:

```powershell
dart analyze
flutter test
```

## New Module Checklist

- [ ] API endpoints and lifecycle rules confirmed with backend.
- [ ] Models, repository, and Riverpod providers created in the feature.
- [ ] List, detail, form, and child-item screens match the appropriate module
      shape.
- [ ] Routes are defined and registered.
- [ ] Loading, empty, error, retry, and permission/backend-error paths are
      handled.
- [ ] Confirmation is guarded and draft-only actions are locked after it.
- [ ] Affected providers, Inventory, and Dashboard refresh after mutations.
- [ ] Repository/model/widget tests pass alongside `dart analyze`.
