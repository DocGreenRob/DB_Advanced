-- cte
-- union all (this makes the query recursive)
with f1(A, B)
as
(
select 3,4
union all
select A-1, B*A from f1
where not A <= 1
)
select A, B from f1
go

-- select last row
with f1(A, B)
as
(
select 3,4
union all
select A-1, B*A from f1
where not A <= 1
)
select B from f1
where A = 1
go

-- limitations exist

-- trying: A = 100
-- errors: Arithmetic overflow error converting expression to data type int.
-- reason: B*A produces number too large for int
with f1(A, B)
as
(
select 100,4
union all
select A-1, B*A from f1
where not A <= 1
)
select B from f1
where A = 1
go

-- another example 
with f1(A, B)
as
(
select 100,4
union all
select A-1, B+A from f1
where not A <= 1
)
select B from f1
where A = 1
go

-- user definied function (udf) that does the same thing
create function udf1(@A int, @B int)
returns int
as
BEGIN
if(@A <= 1) return @B;
return dbo.udf1(@A-1, @B + @A);
END
go

-- this works for udf
select dbo.udf1(3,4);

-- this fails because limit of recursions is 32, so we have to use recursive query (cte)
-- error: Maximum stored procedure, function, trigger, or view nesting level exceeded (limit 32).
select dbo.udf1(100,4);

-- recursive (cte's) has limit of 100
-- The statement terminated. The maximum recursion 100 has been exhausted before statement completion.
with f1(A, B)
as
(
select 102,4
union all
select A-1, B+A from f1
where not A <= 1
)
select B from f1
where A = 1
go

-- fix by adding the OPTION statement
WITH f1(A, B)
AS
(
SELECT 5000,4
UNION ALL
SELECT A-1, B+A FROM f1
WHERE NOT A <= 1
)
SELECT B FROM f1
WHERE A = 1
--OPTION (MAXRECURSION 200)
OPTION (MAXRECURSION 0) -- open, no limitation
GO

-- using 'PARANTED' because we want to store PARANTED information
create table [personnel (parented)]
(
employee int identity primary key,
name nvarchar(50),
[hourly rate] money,
boss int -- parent in personnel tree
);

set identity_insert dbo.[personnel (parented)] on;
insert into [personnel (parented)] (employee, name, [hourly rate], [boss])
values
(1, 'Big Boss', 1000.00, 1),
(2, 'Joe', 10.00, 1),
(8, 'Mary', 20.00, 1),
(14, 'Jack', 15.00, 1),
(3, 'Jane', 10.00, 2),
(5, 'Max', 35.00, 2),
(9, 'Lynn', 15.00, 8),
(10, 'Miles', 60.00, 8),
(12, 'Sue', 15.00, 8),
(15, 'June', 50.00, 14),
(18, 'Jim', 55.00, 14),
(19, 'Bob', 40.00, 14),
(4, 'Jayne', 35.00, 3),
(6, 'Ann', 45.00, 5),
(7, 'Art', 10.00, 5),
(11, 'Al', 70.00, 10),
(13, 'Mike', 50.00, 12),
(16, 'Marty', 55.00, 15),
(17, 'Barb', 60.00, 15),
(20, 'Bart', 1000.00, 19);
set identity_insert dbo.[personnel (parented)] off;

select * from [personnel (parented)]
order by boss


-- employees in Mary's Tree

declare @boss  int;
set @boss = 8; -- Mary

with tree
as
(select employee,  boss from [personnel (parented)]
where employee = @boss
union all -- below is statement that will be executed recursively
select p.employee, p.boss from [personnel (parented)] as p
join tree on tree.employee = p.boss
)
select p.* from [personnel (parented)] as p
join tree on tree.employee = p.employee
go
-- hourly rate budget for Mary
declare @boss int;
set @boss = 8;

with tree
as
(select employee,  boss from [personnel (parented)]
where employee = @boss
union all
select p.employee, p.boss from [personnel (parented)] as p
join tree on tree.employee = P.boss
)
select sum(P.[hourly rate]) as [hourly budget] from [personnel (parented)] as p
join tree on tree.employee = p.employee


-- wrap up tree selection into tvf
create function PersonnelTree(@boss int)
returns table
as
return
with tree
as
(select employee,  boss from [personnel (parented)]
where employee = @boss
union all
select p.employee, p.boss from [personnel (parented)] as P
join tree on tree.employee = P.boss
and P.employee != P.boss
)
select * from tree

select p.* from  [personnel (parented)] as p
join PersonnelTree(8) as tree
on p.employee = tree.employee

