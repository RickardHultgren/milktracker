# Local storage audit

## Result

The app now persists the complete ledger and settings as one versioned JSON snapshot in SharedPreferences.
The current unpaid balance is never persisted as an authoritative value. It is reconstructed from:

1. all persisted milk entries, and
2. the milk-entry IDs persisted in payment records as cleared.

This prevents a separately saved balance from drifting away from transaction history.

## Persisted data

Each snapshot includes:

- all milk entries (`id`, ISO-8601 date/time, integer `amountMl`, integer `costOre`)
- all payments (`id`, ISO-8601 date/time, integer `amountOre`, cleared milk-entry IDs)
- settings (`canCapacityMl`, `milkPriceOrePerLiter`, `paymentThresholdOre`)
- a storage schema version

## Reliability changes

The previous implementation stored milk entries, payments, and settings under three different SharedPreferences keys. Cases A-C worked during normal shutdown/restart, but an interruption between writes could theoretically create a mixed snapshot.

The corrected implementation:

- writes one complete state JSON value
- keeps the last valid complete snapshot as a backup
- validates the whole snapshot before accepting it
- restores the backup if the primary snapshot is unreadable
- migrates the previous three-key format automatically
- does not silently decode a malformed transaction list as an empty ledger

## Mental/reconstruction tests

### Case A

3.0 L + 1.5 L + 3.0 L serializes and restores as three entries.
Derived totals after restart:

- 7,500 ml = 7.5 L unpaid
- 5,250 öre = 52.50 SEK unpaid

### Case B

24 full 3 L collections at 2,100 öre each produce 50,400 öre.
A payment stores all 24 entry IDs as cleared and amount 50,400 öre.
After serialization/restart:

- all 24 milk entries remain
- the payment remains
- unpaid amount reconstructs to 0 öre
- unpaid milk reconstructs to 0 ml

### Case C

After a payment, a new 1.5 L / 1,050 öre entry has an ID that does not appear in any previous payment's `clearedEntryIds`.
After restart it is therefore the only unpaid entry.

## Tests

`test/storage_roundtrip_test.dart` covers Cases A-C using actual JSON encode/decode followed by ledger reconstruction.

## Corruption behavior

If persisted snapshot data exists but neither the primary nor backup snapshot can be decoded, the app now shows a load error and does **not** replace the ledger with an empty state. This avoids converting a storage/read problem into apparent bookkeeping data loss.

The first successful save also seeds the backup snapshot. On later saves, the backup retains the previous known-good complete snapshot while the primary is replaced with the new one.
