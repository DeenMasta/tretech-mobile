# Stock In UI/UX Consistency Standard

Stock In is the reference pattern for mobile operational modules. Apply these
rules to Consignment, Disposal, Returns, and Supplier Return so each workflow
feels familiar without hiding domain-specific controls.

## Flow

1. **List** — searchable/filterable records, concise status, explicit paging.
2. **Draft header** — select only business-owned fields; system-owned values
   (PIC and captured date) are displayed read-only.
3. **Item capture** — choose an entry type, select an entity, then reveal only
   the fields required by that entity.
4. **Review in context** — users return to the draft detail after a normal
   save, or remain in the item form with **Save & next** for repeated capture.
5. **Commit** — use one prominent full-width action for irreversible work
   (Finalize, Confirm, Complete) after showing the result and consequence.
6. **After commit** — make the record read-only, retain a result/audit view,
   and expose corrections only to users with the relevant permission.

## UI rules

- Use one page background, `ContentCard` for grouped content, and `SectionHeader`
  for item sections. Keep outer page padding consistent at `spaceLg`.
- Use bottom actions for data-entry screens. Do not add a secondary Cancel
  button; the app-bar back action already supplies this behavior.
- Pair repeated capture actions in one full-width row: **Save & next** on the
  left, primary **Add item** on the right.
- Use `AppBadge` for reusable record status. Status denotes lifecycle state;
  entry type is quiet metadata, not a colored alert.
- Product requirements are text-and-icon metadata (`Lot tracking: Required`),
  not decorative chips. Reveal controls based on the selected product:
  - lot + expiry: show both and require both;
  - lot only: show lot only;
  - expiry only: show expiry only;
  - neither: show neither and explain automatic handling.
- Keep error messages next to the relevant field. Use banners only for request
  failures or workflow-wide errors.

## Scan input standard

Use `shared/widgets/scan_input_field.dart` for any code that supports camera,
hardware-scanner, or typed input. It owns the visual pattern:

- scanner icon at the start;
- optional browse icon at the end;
- editable text field and loading state;
- shared labels, spacing, and error treatment.

The feature owns its domain behavior: parsing a QR payload, debouncing search,
validating a lot, showing a selected-result card, and sending the API payload.
This keeps the UI consistent while avoiding a shared widget that knows inventory
or consignment business rules.

## Styling decisions

- Use semantic color only for lifecycle state, validation, and destructive
  actions. Avoid multiple outlined colored pills in one card.
- Use neutral labels for classifications such as Product entry and Set entry.
- Keep icon sizes at 14–18px for metadata; reserve larger icons for empty and
  result states.
- Prefer short, action-first labels: `Add item`, `Save & next`, `Finalize
  session`, `Complete return`.

## Module adoption checklist

- [ ] List, draft detail, item form, and completion result follow the flow.
- [ ] System-owned values are read-only.
- [ ] Conditional item controls reflect the selected entity’s requirements.
- [ ] Scanner fields use `ScanInputField`.
- [ ] Status uses `AppBadge`; classifications are neutral metadata.
- [ ] Irreversible action is full width and confirmed.
- [ ] Permissions hide unavailable actions and backend errors remain visible.
