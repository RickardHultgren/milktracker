# Error-prevention audit

## Milk entry

Normal half-can/full-can taps now add immediately to keep farm use fast.
The app persists the new entry before showing a 7-second Snackbar with **UNDO**.
Undo targets the unique ID of that exact new entry, never “the latest” entry.

Undo is refused if the entry has already been included in a recorded payment, because deleting it after payment would make the payment ledger inconsistent.

## Deleting history

Deleting an unpaid milk entry always requires an explicit confirmation dialog.
The confirmation states that deletion is permanent and changes the unpaid balance.

A milk entry already included in a recorded payment cannot be deleted. The app explains why rather than allowing historical payment records to become inconsistent.

## Recording payment

Payment still requires an explicit confirmation dialog showing the full amount being recorded. It is never recorded from a single accidental tap.

## Accounting/storage behavior

No changes were made to the integer accounting model or snapshot/backup storage model.
