-- 找出和最貴的產品同類別的所有產品


declare @a1 int
set @a1 = (
	select top 1
		CategoryID
	from Products
	order by UnitPrice desc
)

select
	*
from Products p1
where p1.CategoryID = @a1


-- 找出和最貴的產品同類別最便宜的產品

/* use @a1 */

select top 1
	*
from Products p1
where p1.CategoryID = @a1
order by UnitPrice


-- 計算出上面類別最貴和最便宜的兩個產品的價差


select
	(
		select top 1
			p.UnitPrice
		from Products p
		where p.CategoryID = @a1
		order by UnitPrice desc
	) - (
		select top 1
			p.UnitPrice
		from Products p
		where p.CategoryID = @a1
		order by UnitPrice
	)


-- 找出沒有訂過任何商品的客戶所在的城市的所有客戶


select
	*
from Customers c
where c.City in (
	select distinct
		c.City
	from Customers c
	left outer join Orders o on c.CustomerID = o.CustomerID
	where o.OrderID is null
)


-- 找出第 5 貴跟第 8 便宜的產品的產品類別


select
	*
from Categories c
where c.CategoryID in (
	(
		select
			p.CategoryID
		from Products p
		order by p.UnitPrice
		offset 7 rows
		fetch next 1 rows only
	), 
	(
		select
			p.CategoryID
		from Products p
		order by p.UnitPrice desc
		offset 4 rows
		fetch next 1 rows only
	)
)


-- 找出誰買過第 5 貴跟第 8 便宜的產品


select distinct
	c.CompanyName CustomerName
from Customers c
inner join Orders o on c.CustomerID = o.CustomerID
inner join [Order Details] od on o.OrderID = od.OrderID
inner join Products p on od.ProductID = p.ProductID
where p.ProductID in (
	(
		select
			p.ProductID
		from Products p
		order by p.UnitPrice
		offset 7 rows
		fetch next 1 rows only
	), 
	(
		select
			p.ProductID
		from Products p
		order by p.UnitPrice desc
		offset 4 rows
		fetch next 1 rows only
	)
)


-- 找出誰賣過第 5 貴跟第 8 便宜的產品


select
	s.CompanyName SupplierName
from Suppliers s
inner join Products p on s.SupplierID = p.SupplierID
where p.ProductID in (
	(
		select
			p.ProductID
		from Products p
		order by p.UnitPrice
		offset 7 rows
		fetch next 1 rows only
	), 
	(
		select
			p.ProductID
		from Products p
		order by p.UnitPrice desc
		offset 4 rows
		fetch next 1 rows only
	)
)


-- 找出 13 號星期五的訂單 (惡魔的訂單)


select
	*
from Orders
where datepart(dw, OrderDate) = 5 and day(OrderDate) = 13


-- 找出誰訂了惡魔的訂單


select
	c.CompanyName
from Orders o
inner join Customers c on c.CustomerID = o.CustomerID
where datepart(dw, OrderDate) = 5 and day(OrderDate) = 13


-- 找出惡魔的訂單裡有什麼產品


select
	p.ProductName
from Orders o
inner join [Order Details] od on o.OrderID = od.OrderID
inner join Products p on od.ProductID = p.ProductID
where datepart(dw, OrderDate) = 5 and day(OrderDate) = 13


-- 列出從來沒有打折 (Discount) 出售的產品


select
	p.ProductName
from Products p
where p.ProductID not in (
	select distinct
		ProductID
	from [Order Details]
	where Discount <> 0
)
order by p.ProductID


-- 列出購買非本國的產品的客戶


select distinct
	c.CompanyName CustomerName
from Customers c
inner join Orders o on c.CustomerID = o.CustomerID
inner join [Order Details] od on o.OrderID = od.OrderID
inner join Products p on od.ProductID = p.ProductID
inner join Suppliers s on p.SupplierID = s.SupplierID
where c.Country <> s.Country


-- 列出在同個城市中有公司員工可以服務的客戶


select distinct
	c.CompanyName CustomerName
from Customers c
inner join Orders o on c.CustomerID = o.CustomerID
inner join Employees e on o.EmployeeID = e.EmployeeID
where c.City = e.City


-- 列出那些產品沒有人買過


select
	*
from Products p 
where p.ProductID not in (
	select distinct
		ProductID
	from [Order Details]
)

