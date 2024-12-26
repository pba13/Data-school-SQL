--- Join Queries
--1)Retrieve Sales orders with Product details using INNER JOIN
SELECT soh.SalesOrderID, soh.OrderDate, 
sod.ProductID, p.Name AS ProductName
FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.SalesOrderDetail sod
ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN Production.Product p
ON sod.ProductID = p.ProductID;

--2) List Products with associated vendors.
SELECT p.Name AS ProductName, 
v.Name AS VendorName
FROM Production.Product p
INNER JOIN Purchasing.ProductVendor pv
ON p.ProductID = pv.ProductID	
INNER JOIN Purchasing.Vendor v
ON pv.BusinessEntityID = v.BusinessEntityID;

--3) List purchase orders with vendor details.
SELECT po.PurchaseOrderID, po.OrderDate, 
v.Name AS VendorName
FROM Purchasing.PurchaseOrderHeader po
INNER JOIN Purchasing.Vendor v
ON po.VendorID = v.BusinessEntityID;

--4) Top 10 products with the highest sales volume
SELECT TOP 10
p.Name AS ProductName,
SUM(sod.OrderQty) AS TotalSalesVolume
FROM Sales.SalesOrderDetail sod
INNER JOIN Production.Product p
ON sod.ProductID = p.ProductID
GROUP BY p.Name
ORDER BY TotalSalesVolume DESC;

--5) Top 10 managers by their sales output.
SELECT TOP 10
m.BusinessEntityID AS ManagerID,
p.FirstName +''+ p.LastName AS
ManagerName,
      SUM(soh.TotalDue) AS TotalSalesOutput
FROM Sales.SalesOrderHeader soh
INNER JOIN HumanResources.Employee e
  ON soh.SalesPersonID = e.BusinessEntityID
INNER JOIN HumanResources.Employee m
  ON e.BusinessEntityID = m.BusinessEntityID
INNER JOIN Person.Person p
  ON m.BusinessEntityID = p.BusinessEntityID
GROUP BY m.BusinessEntityID, p.FirstName, 
p.LastName
ORDER BY TotalSalesOutput DESC;

-- USING CTE

--6) TOTAL SALES BY TERRITORY

WITH SalesCTE AS (
    SELECT 
        t.Name AS TerritoryName,
        SUM(soh.SubTotal) AS TotalSales
    FROM 
        Sales.SalesOrderHeader soh
    INNER JOIN 
        Sales.SalesTerritory t ON soh.TerritoryID = t.TerritoryID
    GROUP BY 
        t.Name
)
SELECT 
    TerritoryName,
    TotalSales
FROM 
    SalesCTE
ORDER BY 
    TotalSales DESC;

--7) History of customer purchase

WITH CustomerCTE AS (
    SELECT 
        c.CustomerID,
        c.AccountNumber,
        SUM(soh.SubTotal) AS TotalPurchases
    FROM 
        Sales.Customer c
    INNER JOIN 
        Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
    GROUP BY 
        c.CustomerID,
        c.AccountNumber
)
SELECT 
    CustomerID,
    AccountNumber,
    TotalPurchases
FROM 
    CustomerCTE
ORDER BY 
    TotalPurchases DESC;

-- 8) Average Order Value by Sales Territory

WITH SalesCTE AS (
    SELECT 
        t.Name AS TerritoryName,
        AVG(soh.SubTotal) AS AverageOrderValue
    FROM 
        Sales.SalesOrderHeader soh
    INNER JOIN 
        Sales.SalesTerritory t ON soh.TerritoryID = t.TerritoryID
    GROUP BY 
        t.Name
)
SELECT 
    TerritoryName,
    AverageOrderValue
FROM 
    SalesCTE
ORDER BY 
    AverageOrderValue DESC;

--9) Identify products with no sales.

WITH ProductSales AS (
    SELECT 
        p.ProductID,
        p.Name AS ProductName,
        SUM(sod.OrderQty) AS TotalSales
    FROM Production.Product p
    LEFT JOIN Sales.SalesOrderDetail sod
        ON p.ProductID = sod.ProductID
    GROUP BY p.ProductID, p.Name
)
SELECT *
FROM ProductSales
WHERE TotalSales IS NULL OR TotalSales = 0;

--10) Top Products by order count
WITH ProductOrders AS (
    SELECT 
        p.Name AS ProductName,
        COUNT(sod.SalesOrderID) AS OrderCount
    FROM Sales.SalesOrderDetail sod
    INNER JOIN Production.Product p
        ON sod.ProductID = p.ProductID
    GROUP BY p.Name
)
SELECT TOP 10 *
FROM ProductOrders
ORDER BY OrderCount DESC;

---11) List customers with orders above average order value
SELECT c.CustomerID, p.FirstName, p.LastName
FROM Sales.Customer c
INNER JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
WHERE EXISTS (
    SELECT 1
    FROM Sales.SalesOrderHeader soh
    WHERE soh.CustomerID = c.CustomerID
    AND soh.TotalDue > (
        SELECT AVG(TotalDue) FROM Sales.SalesOrderHeader
    )
);

--12)  Find Territories contributing more than 10% of Sales

SELECT Name AS TerritoryName
FROM Sales.SalesTerritory
WHERE TerritoryID IN (
    SELECT TerritoryID
    FROM Sales.SalesOrderHeader
    GROUP BY TerritoryID
    HAVING SUM(TotalDue) > (
        SELECT SUM(TotalDue) * 0.1 FROM Sales.SalesOrderHeader
    )
);

--13) Vendors offering products in a specific category

SELECT Name AS VendorName
FROM Purchasing.Vendor
WHERE BusinessEntityID IN (
    SELECT DISTINCT pv.BusinessEntityID
    FROM Purchasing.ProductVendor pv
    INNER JOIN Production.Product p ON pv.ProductID = p.ProductID
    WHERE p.ProductID = (
        SELECT ProductCategoryID
        FROM Production.ProductCategory
        WHERE Name = 'Bikes'
    )
);

-- 14) Customers with the lowest total order amount

SELECT CustomerID, FirstName, LastName
FROM (
    SELECT c.CustomerID, p.FirstName, p.LastName, SUM(soh.TotalDue) AS TotalSales
    FROM Sales.Customer c
    INNER JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
    INNER JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
    GROUP BY c.CustomerID, p.FirstName, p.LastName
) AS CustomerSales
WHERE TotalSales = (
    SELECT MIN(TotalSales)
    FROM (
        SELECT SUM(TotalDue) AS TotalSales
        FROM Sales.SalesOrderHeader
        GROUP BY CustomerID
    ) AS SalesSummary
);

---15) Customers from the territory with maximum sales

SELECT CustomerID, TerritoryID
FROM Sales.Customer
WHERE TerritoryID = (
    SELECT TOP 1 TerritoryID
    FROM Sales.SalesOrderHeader
    GROUP BY TerritoryID
    ORDER BY SUM(TotalDue) DESC
);
