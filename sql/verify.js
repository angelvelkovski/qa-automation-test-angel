// Runs sql/queries.sql against sql/sample-data.sql in an in-memory SQLite database and checks the results.
// Usage: npm run test:sql   (needs Node 22.5+ for the built-in node:sqlite module)
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { DatabaseSync } = require('node:sqlite');

const read = (file) => fs.readFileSync(path.join(__dirname, file), 'utf8');
const [query1, query2] = read('queries.sql').split(/^-- Query 2/m);

const db = new DatabaseSync(':memory:');
db.exec(read('sample-data.sql'));

const rows = (sql) => db.prepare(sql).all().map((r) => ({ ...r }));

// Query 1: each customer once, only United Package orders, DISTINCT order count, sorted by value (highest first).
assert.deepEqual(
  rows(query1).map((r) => [r.CustomerName, r.OrderCount, r.TotalOrderValue]),
  [
    ['E only United Package, big', 1, 100],
    ['A only United Package, 2 lines', 1, 25],
    ['B mixed shippers', 1, 10],
  ],
);

// Query 2: ordered at least once, never used United Package (so not A, B, D or E).
assert.deepEqual(rows('-- Query 2' + query2).map((r) => r.CustomerName), ['C never United Package']);

console.log('SQL checks passed: query 1 (3 rows) and query 2 (1 row) return the expected results.');
