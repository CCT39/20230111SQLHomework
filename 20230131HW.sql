-- 建立 PIVOT 表，統計銷售金額如下：
-- City, [Beverages], [Condiments], [Seafood]

SELECT City, [Beverages], [Condiments], [Seafood] FROM (
	SELECT
		cu.City, ca.CategoryName,
		od.UnitPrice * od.Quantity * (1-od.Discount) AS Total
	FROM Products p 
	INNER JOIN Categories ca ON p.CategoryID = ca.CategoryID
	INNER JOIN [Order Details] od ON p.ProductID = od.ProductID
	INNER JOIN Orders o ON od.OrderID = o.OrderID
	INNER JOIN Customers cu ON o.CustomerID = cu.CustomerID
) t1
PIVOT (
	SUM(Total) FOR CategoryName IN 
		([Beverages], [Condiments], [Seafood])
) AS pvt1

-- 使用 NTILE window 函數，以銷售金額分成 5 等分，
-- 統計不同國家的客戶在這 5 個級距的平均銷售金額
-- Country, [1], [2], [3], [4], [5]

SELECT Country, [1], [2], [3], [4], [5] FROM (
	SELECT
		c.Country,
		od.Quantity * od.UnitPrice * (1-od.Discount) AS Total,
		NTILE(5) OVER (
			PARTITION BY c.Country
			ORDER BY od.Quantity * od.UnitPrice * (1-od.Discount) DESC
		) AS Tile2
	FROM [Order Details] od
	INNER JOIN Orders o ON od.OrderID = o.OrderID
	INNER JOIN Customers c ON o.CustomerID = c.CustomerID
) t2
PIVOT (
	AVG(Total) FOR Tile2 
		IN ([1], [2], [3], [4], [5])
) AS pvt2

-- 按照 UnitPrice 由大排到小，找出與前一筆產品價格相差 5 元以上的產品

SELECT * FROM(
	SELECT 
		 *,
		 LAG(UnitPrice) OVER (
			ORDER BY UnitPrice DESC
		 ) - UnitPrice AS Diff
	FROM Products
) t3
WHERE Diff > 5

-- 寫一個 TVF 可以帶入上一題所要過濾的價格差 @diff_price，
-- 傳回與前一筆價格相差 @diff_price 的產品

CREATE OR ALTER PROC SearchDiff(
	@diff_price money
)
AS
BEGIN
	SELECT * FROM(
		SELECT 
			 *,
			 LAG(UnitPrice) OVER (
				ORDER BY UnitPrice DESC
			 ) - UnitPrice AS Diff
		FROM Products
	) t4
	WHERE Diff > @diff_price
END
GO

EXEC SearchDiff 5

-- 列出年紀最大的員工最早的一筆訂單的日期

SELECT TOP 1
	o.OrderDate
FROM Orders o
INNER JOIN Employees e ON o.EmployeeID = e.EmployeeID
WHERE o.EmployeeID = (
	SELECT TOP 1 EmployeeID FROM Employees e ORDER BY BirthDate
)
ORDER BY o.OrderDate

-- 列出每一個客戶所購買的同城市供應商所生產的產品

SELECT
	c.CompanyName Customer, s.CompanyName Supplier, p.*
FROM Products p
INNER JOIN Suppliers s ON p.SupplierID = s.SupplierID
INNER JOIN [Order Details] od ON p.ProductID = od.ProductID
INNER JOIN Orders o ON od.OrderID = o.OrderID
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE c.City = s.City

-- 列出每一個客戶所購買的同城市供應商所生產的產品的總銷售金額

SELECT 
	ProductID,
	SUM(UnitPrice * Quantity * (1-Discount)) AS Total
FROM [Order Details] od
WHERE od.ProductID IN (
	SELECT DISTINCT
		p.ProductID
	FROM Products p
	WHERE p.SupplierID IN (
		SELECT s.SupplierID FROM Suppliers s
		WHERE p.ProductID IN (
			SELECT od.ProductID FROM [Order Details] od
			WHERE od.OrderID IN (
				SELECT o.OrderID FROM Orders o
				WHERE o.CustomerID IN (
					SELECT c.CustomerID FROM Customers c
					WHERE c.City = s.City
				)
			)
		)
	)
)
GROUP BY ProductID

-- 列出高於平均單價以上的產品在不同城市的銷售量

SELECT 
	City, od.ProductID,
	SUM(od.Quantity) AS TotalQuantity
FROM [Order Details] od
INNER JOIN Orders o ON od.OrderID = o.OrderID
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE od.ProductID IN (
	SELECT
		pp.ProductID
	FROM Products pp
	WHERE UnitPrice > (
		SELECT AVG(ppp.UnitPrice) FROM Products ppp
	)
)
GROUP BY City, od.ProductID

-- 列出業績最差的員工賣最好的產品

SELECT * FROM Products p
WHERE p.ProductID = (
	SELECT TOP 1
		od.ProductID
	FROM Orders o
	INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
	WHERE o.EmployeeID = (
		SELECT TOP 1
			o.EmployeeID
		FROM Orders o
		INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
		GROUP BY o.EmployeeID
		ORDER BY SUM(Quantity * UnitPrice * (1-Discount))
	)
	GROUP BY od.ProductID
	ORDER BY SUM(Quantity * UnitPrice * (1-Discount)) DESC
)

-- 列出職稱 (ContactTitle) 是 Sales 開頭的客戶最近一次訂單購買的產品清單

SELECT * FROM Products p
WHERE p.ProductID IN (
	SELECT DISTINCT od.ProductID FROM [Order Details] od
	WHERE od.OrderID IN (
		SELECT OrderID FROM (
			SELECT DISTINCT
				CustomerID, o.OrderID,
				MAX(OrderDate) OVER (
					PARTITION BY CustomerID
				) AS Nearest
			FROM Orders o
			INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
			WHERE o.CustomerID IN (
				SELECT c.CustomerID FROM Customers c
				WHERE c.ContactTitle LIKE 'Sales%'
			)
		) t10
	)
)

-- 列出公司最資深員工與最資淺員工之間的業績差距

SELECT
(
	SELECT 
		SUM(Quantity * UnitPrice * (1-Discount)) AS Total
	FROM Orders o
	INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
	WHERE o.EmployeeID = (
		SELECT TOP 1 EmployeeID FROM Employees ORDER BY HireDate
	)
) - (
	SELECT 
		SUM(Quantity * UnitPrice * (1-Discount)) AS Total
	FROM Orders o
	INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
	WHERE o.EmployeeID = (
		SELECT TOP 1 EmployeeID FROM Employees ORDER BY HireDate DESC
	)
) Diff

-- 列出不同國家與不同產品類別的銷售量統計

SELECT 
	Country, CategoryName,
	SUM(Quantity) TotalSold
FROM (
	SELECT
		cu.Country, ca.CategoryName, od.Quantity
	FROM Categories ca
	INNER JOIN Products p ON ca.CategoryID = p.ProductID
	INNER JOIN [Order Details] od ON p.ProductID = od.ProductID
	INNER JOIN Orders o ON od.OrderID = o.OrderID
	INNER JOIN Customers cu ON o.CustomerID = cu.CustomerID
) t12
GROUP BY GROUPING SETS(Country, CategoryName)

-- 列出每個國家中賣得最好的產品與銷售金額

SELECT * FROM (
	SELECT 
		c.Country, p.ProductName,
		od.Quantity * od.UnitPrice * (1-od.Discount) AS Total,
		RANK() OVER (
			PARTITION BY Country
			ORDER BY od.Quantity * od.UnitPrice * (1-od.Discount) DESC
		) SoldRankByCountry
	FROM Products p
	INNER JOIN [Order Details] od ON p.ProductID = od.ProductID
	INNER JOIN Orders o ON od.OrderID = o.OrderID
	INNER JOIN Customers c ON o.CustomerID = c.CustomerID
) t13
WHERE SoldRankByCountry = 1

-- 列出銷售量最多的城市各類型產品的銷售明細

SELECT * FROM [Order Details] od
WHERE od.ProductID IN (
	SELECT DISTINCT od.ProductID FROM [Order Details] od
	WHERE od.OrderID IN (
		SELECT o.OrderID FROM Orders o
		WHERE o.CustomerID IN (
			SELECT c.CustomerID FROM Customers c
			WHERE c.City = (
				SELECT TOP 1
					c.City
				FROM Customers c
				INNER JOIN Orders o ON c.CustomerID = o.CustomerID
				INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
				GROUP BY c.City
				ORDER BY SUM(Quantity) DESC
			)
		)
	)
)
ORDER BY od.ProductID

-- 寫一支預存程序，用來新增一筆供應商 (Suppliers) 資料

CREATE OR ALTER PROC AddSupplier(
	@companyName nvarchar(40),
	@contactName nvarchar(30) = NULL,
	@contactTitle nvarchar(30) = NULL,
	@address nvarchar(60) = NULL,
	@city nvarchar(15) = NULL,
	@region nvarchar(15) = NULL,
	@postalCode nvarchar(10) = NULL,
	@country nvarchar(15) = NULL,
	@phone nvarchar(24) = NULL,
	@fax nvarchar(24) = NULL,
	@homePage ntext = NULL
)
AS
BEGIN
	INSERT INTO Suppliers(
		CompanyName,
		ContactName,
		ContactTitle,
		[Address],
		City,
		Region,
		PostalCode,
		Country,
		Phone,
		Fax,
		HomePage
	) VALUES (
		@companyName,
		@contactName,
		@contactTitle,
		@address,
		@city,
		@region,
		@postalCode,
		@country,
		@phone,
		@fax,
		@homePage
	)

	RETURN @@IDENTITY
END
GO

DECLARE @id int
EXEC @id = AddSupplier 'TadokoroInc'
SELECT @id
SELECT * FROM Suppliers

-- 列出銷售數量最高的產品是那些客戶訂的，每年度分別訂多少

SELECT o.CustomerID, YEAR(OrderDate) OrderYear 
INTO t16 FROM Orders o
WHERE o.OrderID IN (
	SELECT od.OrderID FROM [Order Details] od
	WHERE od.ProductID = (
		SELECT TOP 1
			odd.ProductID
		FROM [Order Details] odd
		GROUP BY odd.ProductID
		ORDER BY SUM(Quantity) DESC
	)
)

SELECT CustomerID FROM t16

SELECT
	SUM([1996]) sum1996, SUM([1997]) sum1997, SUM([1998]) sum1998
FROM t16
PIVOT (
	COUNT(OrderYear) FOR OrderYear IN ([1996], [1997], [1998])
) AS pvt16

-- 列出每位員工的下屬的業績總金額

SELECT
	e.ReportsTo,
	SUM(Sells) AS WorkersProfit
FROM (
	SELECT 
		o.EmployeeID,
		SUM(od.UnitPrice * Quantity * (1-Discount)) AS Sells
	FROM Orders o
	INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
	GROUP BY o.EmployeeID
) t17
INNER JOIN Employees e ON t17.EmployeeID = e.EmployeeID
GROUP BY e.ReportsTo
