# Accounting audit

The accounting logic was reviewed against the requested business rules.

1. Default can capacity is 3000 ml; half-can is calculated with integer arithmetic and is 1500 ml.
2. Full can is 3000 ml.
3. Default milk price is 700 öre/liter.
4. Integer cost calculation gives 1500 ml -> 1050 öre and 3000 ml -> 2100 öre.
5. Default payment threshold is 50,000 öre.
6. The payment state activates when unpaid balance is greater than or equal to the threshold.
7. A 50,400 öre unpaid balance records a 50,400 öre payment, not 50,000 öre.
8. Payments clear the IDs of the currently unpaid entries. Historical milk entries are not modified or deleted.
9. Milk history remains stored after payment.
10. Each milk entry stores its own costOre, so later price-setting changes do not alter historical prices.

## Floating-point audit

Persisted/accounting values use integers:

- milk quantities: milliliters (`int`)
- prices and balances: öre (`int`)
- threshold: öre (`int`)
- payment amount: öre (`int`)

Decimal user input is converted directly from text to scaled integers without parsing through `double`.
Cost calculation uses integer arithmetic and deterministic rounding to the nearest öre.

The only remaining floating-point operation is the UI-only progress ratio for `LinearProgressIndicator`; it does not affect stored quantities, money, thresholds, or payment calculations.
