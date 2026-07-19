# Disposal Mobile Implementation Plan

## Goal

Replicate the frontend Disposal workflow in the Flutter mobile app while
following the [Mobile Module Architecture Standard](mobile-module-architecture.md).

The feature is a **draft-to-complete inventory workflow**:

```text
List -> create draft -> add/remove lot items -> review -> complete
```

Completion is irreversible from mobile. The backend atomically validates the
draft, deducts quantities, writes inventory movements, and marks the disposal
as completed.

## Source of Truth

The mobile implementation must match these existing contracts:

- Frontend feature: `tretech-frontend/src/features/operations/disposals/`
- Backend routes: `tretech-backend/routes/api.php`
- Backend disposal services:
  `tretech-backend/app/Services/Disposal/`

No API changes are required for this mobile work.

## Lifecycle and Business Rules

### Disposal record

- A record starts as `draft`.
- Only a draft may be edited or have items added or removed.
- A draft requires at least one item before it can be completed.
- Completing changes the disposal status to `completed`, stores the time and
  acting user, and locks the record from further mobile mutation.

### Disposal item

Each item represents one lot and contains:

| Field | Requirement |
| --- | --- |
| `lot_id` | Required existing lot |
| `quantity` | Required positive integer, no greater than available quantity |
| `disposal_category` | `expired`, `damaged`, `lost`, or `other` |
| `reason_text` | Required; maximum 500 characters |
| `remarks` | Optional; maximum 1,000 characters |

Backend validation remains authoritative:

- A lot cannot appear twice in the same disposal.
- `disposed` and `returned_to_supplier` lots cannot be added or completed.
- Availability is rechecked during atomic completion, so the mobile app must
  display backend errors caused by stale data or concurrent changes.
- On completion, `quantity_available` is reduced by the item quantity. A lot
  gets status `disposed` only when it is fully depleted.
- Each item creates a `disposed` inventory movement associated with the
  disposal record.

## API Contract

All paths are beneath `/api/v1`.

| Action | Method and path | Request fields |
| --- | --- | --- |
| List | `GET /disposals` | `page`, `per_page`, `search`, `status`, `from_date`, `to_date` |
| Detail | `GET /disposals/:id` | — |
| Create draft | `POST /disposals` | `disposed_at`, `pic_user_id`, `remarks` |
| Update draft | `PATCH /disposals/:id` | one or more header fields |
| List items | `GET /disposals/:id/items` | — |
| Add item | `POST /disposals/:id/items` | item fields above |
| Remove item | `DELETE /disposals/:id/items/:itemId` | — |
| Complete | `POST /disposals/:id/complete` | — |

The list response uses `{ data: [], pagination: {} }`; individual resources
use the standard `{ data: {} }` envelope.

## Mobile Architecture

```text
GoRouter
  -> Disposal screens
    -> Riverpod provider families keyed by immutable IDs/queries
      -> DisposalRepository
        -> authenticated Dio -> Disposal API
```

Create the following feature layout:

```text
lib/features/disposal/
  data/
    models/disposal_models.dart
    repositories/disposal_repository.dart
  presentation/
    providers/disposal_providers.dart
    screens/
      disposal_screen.dart
      disposal_form_screen.dart
      disposal_detail_screen.dart
      disposal_item_form_screen.dart
      disposal_complete_screen.dart
    widgets/
      disposal_status_badge.dart
      disposal_list_tile.dart
      disposal_item_tile.dart
      disposal_detail_sections.dart
```

### Models

`disposal_models.dart` should include immutable DTOs for:

- `DisposalModel`: record, PIC, completion metadata, count, optional items.
- `DisposalItemModel`: category, reason, quantity, remarks, and nested lot.
- `DisposalLotBrief`: lot number, status, expiry date, product, and supplier.
- `DisposalUserBrief`: ID, full name, optional email.
- `DisposalPage`: items plus pagination values.

Use safe `fromJson` parsing consistent with Inventory models.

### Repository

`DisposalRepository` owns all requests above. It must:

- depend on `dioProvider`;
- unwrap the standard `data` object;
- parse paginated responses;
- convert `DioException` values to `AppException`;
- normalize blank optional text to `null`;
- keep date values in `yyyy-MM-dd` API format.

Add endpoint builders in `lib/core/constants/api_endpoints.dart` for record,
item, and complete paths.

### Providers

Use `FutureProvider.autoDispose.family` for:

- `disposalListProvider(DisposalListQuery)`;
- `disposalDetailProvider(int disposalId)`;
- `disposalItemsProvider(int disposalId)`.

`DisposalListQuery` is immutable, supports value equality, and contains
search, status (`all`, `draft`, `completed`), date range, page, and page size.
Changing a filter resets the page to one.

Repository mutations are called explicitly by the owning form/detail screen;
providers remain responsible only for reads.

## Screen Plan

### List: `disposal_screen.dart`

Replace the placeholder with a `ConsumerStatefulWidget` containing:

- search by disposal number;
- Draft/Completed status chips;
- from/to disposal-date filters;
- pagination and pull-to-refresh;
- loading, empty, error, and retry states;
- a create-disposal action when the user has `disposals.create`;
- rows that route to disposal detail.

### Header form: `disposal_form_screen.dart`

Use for create and draft edit:

- default `disposed_at` to today;
- default the PIC to the current signed-in user;
- collect optional remarks;
- validate date, PIC, and the 1,000-character remarks limit;
- create then route to detail; update then return to detail;
- reject edit navigation if the loaded disposal is no longer draft.

### Detail: `disposal_detail_screen.dart`

Show disposal number, date, PIC, item count, remarks, status, completion time,
completion user, and timestamps. Show the item list below it.

For drafts only, show Edit, Add Item, Delete Item, and Complete actions. The
Complete action is enabled only when the item count is greater than zero.

### Item form: `disposal_item_form_screen.dart`

Allow a draft to add one item:

- select a lot by lookup/search and support barcode/QR scanning where practical;
- display available quantity and constrain entered quantity client-side;
- select category, enter required reason, and optional remarks;
- give a friendly warning for terminal lot statuses;
- still submit backend errors unchanged when live availability or duplicate
  checks fail.

Do not import Stock In's private models or repository. Reuse Inventory models
or add a disposal-local lot lookup adapter that calls Inventory APIs.

### Completion: `disposal_complete_screen.dart`

Display the disposal context and a read-only item review. The final action
opens a confirmation dialog stating that the server will deduct quantities and
create inventory movements. On success, route back to the completed detail.

## Routing and Permissions

Add and register these routes in `route_names.dart` and `app_router.dart`:

```text
/disposal
/disposal/create
/disposal/:id
/disposal/:id/edit
/disposal/:id/items/add
/disposal/:id/complete
```

Mirror backend/frontend permissions:

| Permission | Access |
| --- | --- |
| `disposals.view` | list and detail |
| `disposals.create` | create, edit, item add/remove, and completion |

The auth model already carries permissions. Add a small shared mobile
permission helper/gate instead of duplicating permission checks across each
disposal screen.

## Invalidation Plan

After creating, editing, adding an item, or deleting an item, invalidate the
Disposal list, detail, and item providers.

After completion, also invalidate:

- Inventory units, detail, lookup, product/set availability, expiring-soon,
  ledger, and lot movement providers as relevant;
- Dashboard summary provider.

This ensures a completed disposal is immediately visible in Inventory and
Dashboard without maintaining duplicate client state.

## Implementation Sequence

1. Add endpoint builders and disposal DTOs.
2. Implement the repository and its request/response tests.
3. Add query objects and Riverpod read providers.
4. Replace the placeholder with the paginated list and filters.
5. Add routes, header create/edit form, and detail screen.
6. Add lot selection/scanning and draft item add/delete flow.
7. Add review, completion dialog, and all cross-module invalidations.
8. Add permission gating and complete test coverage.

## Verification

- Repository tests cover all methods, paths, payloads, pagination, envelope
  parsing, and API errors.
- Model tests cover nested lot/product/supplier and nullable audit values.
- Widget tests cover loading/error/empty states, draft-only controls, required
  validation, delete confirmation, and completion eligibility.
- Manual workflow: create draft -> add a valid lot -> complete -> verify
  quantity/status in Inventory Detail and a `disposed` entry in the ledger.
- Run:

  ```powershell
  dart analyze
  flutter test
  ```
