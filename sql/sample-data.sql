-- Tiny in-memory dataset for `npm run test:sql`. Same table/column names as the W3Schools (Northwind) playground.
-- Each customer exists to prove one behaviour of the queries in queries.sql.
CREATE TABLE Customers(CustomerID INT, CustomerName TEXT, Country TEXT);
CREATE TABLE Shippers(ShipperID INT, ShipperName TEXT);
CREATE TABLE Orders(OrderID INT, CustomerID INT, ShipperID INT);
CREATE TABLE Products(ProductID INT, Price REAL);
CREATE TABLE OrderDetails(OrderID INT, ProductID INT, Quantity INT);

INSERT INTO Shippers VALUES (1, 'Speedy Express'), (2, 'United Package'), (3, 'Federal Shipping');
INSERT INTO Products VALUES (1, 10), (2, 5);

INSERT INTO Customers VALUES
  (1, 'A only United Package, 2 lines', 'X'),  -- one order with two line items: must count as 1 order, value 2*10 + 1*5 = 25
  (2, 'B mixed shippers',               'Y'),  -- also used another shipper: only the United Package order may count (value 10)
  (3, 'C never United Package',         'Z'),  -- belongs in query 2
  (4, 'D no orders',                    'W'),  -- must appear in neither query
  (5, 'E only United Package, big',     'V');  -- biggest value: must be first in query 1

INSERT INTO Orders VALUES (1, 1, 2), (2, 2, 2), (3, 2, 1), (4, 3, 1), (5, 5, 2);
INSERT INTO OrderDetails VALUES (1, 1, 2), (1, 2, 1), (2, 2, 2), (3, 1, 9), (4, 1, 1), (5, 1, 10);
