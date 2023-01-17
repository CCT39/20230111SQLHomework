-- Merge範例

-- 建立庫存量的表格，以部分商品為例，將其銷售數量（Quantity）根據ProductID加總後，從庫存量當中扣除，以此演示Merge的使用方式

create table Inventories(
	ProductID int,
	Inventory int
)

select
	od.ProductID,
	sum(Quantity) as totalQuantity
into Sells
from [Order Details] od
group by od.ProductID

insert into Inventories
values (11, 1710), (42, 1265), (72, 1347), (14, 1638)

select * from Sells s
select * from Inventories inv

merge into Inventories inv
	using Sells s
	on inv.ProductID = s.ProductID
when matched and inv.Inventory - s.totalQuantity <= 0 then
	delete
when matched then
	update set inv.Inventory = inv.Inventory - s.totalQuantity;

select * from [Order Details] od order by ProductID
select * from Inventories inv
