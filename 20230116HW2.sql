-- 給最後一題用的
create or alter function GetConsump
(
	@getConsumption int
)
returns table
as
return
(
	select
		c.CompanyName, 
		sum(UnitPrice * Quantity * (1 - Discount)) as Consumptions
	from [Order Details] od
	inner join Orders o on od.OrderID = o.OrderID
	inner join Customers c on o.CustomerID = c.CustomerID
	group by c.CompanyName
	order by sum(UnitPrice * Quantity * (1 - Discount)) desc
	offset (@getConsumption - 1) rows
	fetch next 1 rows only
)
go


-- 列出所有在每個月月底的訂單


select * from Orders where OrderDate in (
	select distinct eomonth(OrderDate) from Orders
)


-- 列出每個月月底售出的產品


select * from Products p
inner join [Order Details] od on p.ProductID = od.ProductID
inner join Orders o on od.OrderID = o.OrderID
where o.OrderID in (
	select OrderID from Orders where OrderDate in (
		select distinct eomonth(OrderDate) from Orders
	)
)


-- 找出有敗過最貴的三個產品中的任何一個的前三個大客戶


select top 3 
	c.CustomerID, c.CompanyName, c.ContactName,
	p.UnitPrice * Quantity * (1-Discount) as total
from Customers c
inner join Orders o on c.CustomerID = o.CustomerID
inner join [Order Details] od on o.OrderID = od.OrderID
inner join Products p on od.ProductID = p.ProductID
where p.ProductID in (
	select top 3 ProductID from Products order by UnitPrice desc
)
order by p.UnitPrice * Quantity * (1-Discount) desc


-- 找出有敗過銷售金額前三高個產品的前三個大客戶


select top 3
	c.CustomerID, c.CompanyName, c.ContactName,
	p.UnitPrice * Quantity * (1-Discount) as total
from Customers c
inner join Orders o on c.CustomerID = o.CustomerID
inner join [Order Details] od on o.OrderID = od.OrderID
inner join Products p on od.ProductID = p.ProductID
where p.ProductID in (
	select top 3 p.ProductID from Products p
	inner join [Order Details] od on od.ProductID = p.ProductID
	order by (p.UnitPrice * Quantity * (1-Discount)) desc
)
order by p.UnitPrice * Quantity * (1-Discount) desc


-- 找出有敗過銷售金額前三高個產品所屬類別的前三個大客戶


select top 3
	c.CustomerID, c.CompanyName, c.ContactName,
	p.UnitPrice * Quantity * (1-Discount) as total
from Customers c
inner join Orders o on c.CustomerID = o.CustomerID
inner join [Order Details] od on o.OrderID = od.OrderID
inner join Products p on od.ProductID = p.ProductID
where p.CategoryID in (
	select top 3
		p.CategoryID
	from Products p
	inner join [Order Details] od on od.ProductID = p.ProductID
	order by p.UnitPrice * Quantity * (1-Discount) desc
)
order by p.UnitPrice * Quantity * (1-Discount) desc;


-- 列出消費總金額高於所有客戶平均消費總金額的客戶的名字，以及客戶的消費總金額


with t6 as (
	select
		sum(UnitPrice * Quantity * (1-Discount)) as total
	from [Order Details] od
	inner join Orders o on od.OrderID = o.OrderID
	group by o.CustomerID
)

select
	c.CompanyName,
	sum(UnitPrice * Quantity * (1-Discount)) as total
from Customers c
inner join Orders o on c.CustomerID = o.CustomerID
inner join [Order Details] od on o.OrderID = od.OrderID
group by c.CompanyName
having sum(UnitPrice * Quantity * (1-Discount)) > (
	select
		avg(total)
	from t6
)
order by total desc


-- 列出最熱銷的產品，以及被購買的總金額


select top 1
	p.ProductName,
	sum(p.UnitPrice * Quantity * (1-Discount)) as total
from Products p
inner join [Order Details] od on p.ProductID = od.ProductID
group by p.ProductName
order by total desc


-- 列出最少人買的產品


select top 1
	p.ProductName,
	count(od.OrderID) as countOrders
from Products p
inner join [Order Details] od on p.ProductID = od.ProductID
group by p.ProductName
order by countOrders


-- 列出最沒人要買的產品類別 (Categories)


select top 1
	c.CategoryName,
	count(od.OrderID) as countOrders
from Products p
inner join [Order Details] od on p.ProductID = od.ProductID
inner join Categories c on p.CategoryID = c.CategoryID
group by c.CategoryName
order by countOrders


-- 列出跟銷售最好的供應商買最多金額的客戶與購買金額 (含購買其它供應商的產品)


select
	c.CompanyName as CustomerName,
	sum(p.UnitPrice * Quantity * (1-Discount)) as total
from Customers c
inner join Orders o on c.CustomerID = o.CustomerID
inner join [Order Details] od on o.OrderID = od.OrderID
inner join Products p on od.ProductID = p.ProductID
where c.CustomerID = (
	select top 1
		c.CustomerID
	from Customers c
	inner join Orders o on c.CustomerID = o.CustomerID
	inner join [Order Details] od on o.OrderID = od.OrderID
	inner join Products p on od.ProductID = p.ProductID
	where p.SupplierID = (
		select top 1
			s.SupplierID
		from [Order Details] od
		inner join Products p on od.ProductID = p.ProductID
		inner join Suppliers s on p.SupplierID = s.SupplierID
		group by s.SupplierID
		order by sum(p.UnitPrice * Quantity * (1-Discount)) desc
	)
	group by c.CustomerID
	order by sum(p.UnitPrice * Quantity * (1-Discount)) desc
)
group by c.CompanyName
order by total desc


-- 列出跟銷售最好的供應商買最多金額的客戶與購買金額 (不含購買其它供應商的產品)


select top 1
	c.CompanyName as CustomerName,
	sum(p.UnitPrice * Quantity * (1-Discount)) as total
from Customers c
inner join Orders o on c.CustomerID = o.CustomerID
inner join [Order Details] od on o.OrderID = od.OrderID
inner join Products p on od.ProductID = p.ProductID
where p.SupplierID = (
	select top 1
		s.SupplierID
	from [Order Details] od
	inner join Products p on od.ProductID = p.ProductID
	inner join Suppliers s on p.SupplierID = s.SupplierID
	group by s.SupplierID
	order by sum(p.UnitPrice * Quantity * (1-Discount)) desc
)
group by c.CompanyName
order by total desc


-- 列出那些產品沒有人買過


select od.ProductID from [Order Details] od
except
select p.ProductID from Products p


-- 列出沒有傳真 (Fax) 的客戶和它的消費總金額


select
	c.CompanyName,
	sum(od.UnitPrice * Quantity * (1-Discount)) as total
from Orders o
inner join [Order Details] od on o.OrderID = od.OrderID
inner join Customers c on o.CustomerID = c.CustomerID
where o.CustomerID in (
	select c.CustomerID from Customers c where c.Fax is null
)
group by c.CompanyName


-- 列出每一個城市消費的產品種類數量


select
	c.City,
	p.ProductName,
	sum(Quantity) as EachQuantity
from Customers c
inner join Orders o on c.CustomerID = o.CustomerID
inner join [Order Details] od on o.OrderID = od.OrderID
inner join Products p on od.ProductID = p.ProductID
group by p.ProductName, c.City


-- 列出目前沒有庫存的產品在過去總共被訂購的數量


select 
	od.ProductID,
	sum(od.Quantity) AllOrderedQuantity
from [Order Details] od
where ProductID in (
	select p.ProductID from Products p where p.UnitsInStock = 0
)
group by od.ProductID


-- 列出目前沒有庫存的產品在過去曾經被那些客戶訂購過


select c.CustomerID, c.CompanyName from Customers c
where c.CustomerID in (
	select o.CustomerID from Orders o
	where o.OrderID in (
		select od.OrderID from [Order Details] od
		where od.ProductID in (
			select p.ProductID from Products p where p.UnitsInStock = 0
		)
	)
)


-- 列出每位員工的下屬的業績總金額


select
	e.ReportsTo,
	sum(Sells)
from (
	select 
		o.EmployeeID,
		sum(od.UnitPrice * Quantity * (1-Discount)) as Sells
	from Orders o
	inner join [Order Details] od on o.OrderID = od.OrderID
	group by o.EmployeeID
) EmployeeSells
inner join Employees e on EmployeeSells.EmployeeID = e.EmployeeID
group by e.ReportsTo


-- 列出每家貨運公司運送最多的那一種產品類別與總數量


select 
	ss.ShipperID, ss.CompanyName,
	(
		select top 1
			CategoryID
		from Products p
		inner join [Order Details] od on p.ProductID = od.ProductID
		inner join Orders o on od.OrderID = o.OrderID
		inner join Shippers s on o.ShipVia = s.ShipperID
		where s.ShipperID = ss.ShipperID
		group by s.ShipperID, CategoryID
		order by sum(Quantity) desc
	) as CategoryID,
	(
		select top 1
			sum(od.Quantity) as Total
		from Products p
		inner join [Order Details] od on p.ProductID = od.ProductID
		inner join Orders o on od.OrderID = o.OrderID
		inner join Shippers s on o.ShipVia = s.ShipperID
		where s.ShipperID = ss.ShipperID
		group by s.ShipperID, CategoryID
		order by sum(od.Quantity) desc
	)
from Shippers ss


-- 列出每一個客戶買最多的產品類別與金額


select
	cc.CustomerID, cc.CompanyName,
	(
		select top 1
			CategoryID
		from Products p
		inner join [Order Details] od on p.ProductID = od.ProductID
		inner join Orders o on od.OrderID = o.OrderID
		inner join Customers c on o.CustomerID = c.CustomerID
		where c.CustomerID = cc.CustomerID
		group by c.CustomerID, CategoryID
		order by sum(od.UnitPrice * Quantity * (1-Discount)) desc
	) as CategoryID,
	(
		select top 1
			sum(od.UnitPrice * Quantity * (1-Discount))
		from Products p
		inner join [Order Details] od on p.ProductID = od.ProductID
		inner join Orders o on od.OrderID = o.OrderID
		inner join Customers c on o.CustomerID = c.CustomerID
		where c.CustomerID = cc.CustomerID
		group by c.CustomerID, CategoryID
		order by sum(od.UnitPrice * Quantity * (1-Discount)) desc
	) as Consumptions
from Customers cc


-- 列出每一個客戶買最多的那一個產品與購買數量


select
	cc.CustomerID, cc.CompanyName,
	(
		select top 1
			CategoryID
		from Products p
		inner join [Order Details] od on p.ProductID = od.ProductID
		inner join Orders o on od.OrderID = o.OrderID
		inner join Customers c on o.CustomerID = c.CustomerID
		where c.CustomerID = cc.CustomerID
		group by c.CustomerID, CategoryID
		order by sum(od.UnitPrice * Quantity * (1-Discount)) desc
	) as CategoryID,
	(
		select top 1
			sum(Quantity)
		from Products p
		inner join [Order Details] od on p.ProductID = od.ProductID
		inner join Orders o on od.OrderID = o.OrderID
		inner join Customers c on o.CustomerID = c.CustomerID
		where c.CustomerID = cc.CustomerID
		group by c.CustomerID, CategoryID
		order by sum(od.UnitPrice * Quantity * (1-Discount)) desc
	) as Quantities
from Customers cc


-- 按照城市分類，找出每一個城市最近一筆訂單的送貨時間


select
	o.ShipCity,
	max(o.ShippedDate)
from Orders o
group by o.ShipCity


-- 列出購買金額第五名與第十名的客戶，以及兩個客戶的金額差距


select CompanyName from GetConsump(5)
select CompanyName from GetConsump(10)
select
	(select Consumptions from GetConsump(5)) - 
	(select Consumptions from GetConsump(10)) as Diff

