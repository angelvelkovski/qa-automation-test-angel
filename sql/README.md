# Part 3: SQL

`queries.sql` has the two queries for the W3Schools Northwind playground (Try-It editor).

1. **United Package customers:** each customer once, with the number of their United Package orders and total value (quantity × product price), highest value first. `COUNT(DISTINCT OrderID)` is needed because joining order lines repeats each order once per line.
2. **Ordered but never used United Package:** `EXISTS` keeps only customers with at least one order, `NOT EXISTS` drops anyone who ever used United Package, even once alongside other shippers.

## How to run

- **In the playground (the real check):** open the W3Schools SQL Try-It editor, paste one query at a time and press Run.
- **Locally (logic check):** `npm run test:sql` runs both queries in an in-memory SQLite database on `sample-data.sql`, a tiny dataset where each customer proves one behaviour (multi-line order, mixed shippers, never used United Package, no orders). It needs Node 22.5+.

The local check proves the logic and edge cases, not the real Northwind numbers. Run the queries once in the playground as well.
