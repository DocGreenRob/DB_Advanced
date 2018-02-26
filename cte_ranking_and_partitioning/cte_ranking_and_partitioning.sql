-------------------------------------- clear plan cache
dbcc freeproccache;
-------------------------------------------------------

-------------------------------------- see plan cache
select * from PlanCache; 
-----------------------------------------------------

-------------------------------------- IsParameterizationForced
select DATABASEPROPERTYEX('sql_server_fundamentals__cte_ranking_and_paritioning', 'IsParameterizationForced');
---------------------------------------------------------------

-- sql server will create plan cache for this sql 
-- (@1 tinyint)SELECT * FROM [products] WHERE [id]=@1
select * from products where id = 4;

-- but it considers this too complex
select * from products where id > 4;
-- and no plan cache is created
select * from PlanCache; 

-- but setting the parameterization to forced, and then checking the PlanCache you will see this plan cache created

-------------------------------------- parameterization forced
alter database sql_server_fundamentals__cte_ranking_and_partitioning set parameterization forced
---------------------------------------------------------------

-- now run 
select * from products where id > 5;

-- and then
select * from PlanCache; 

-- also, we can create a manual parameterized plan by using "sp_executesql"
-- first change back to simple

-------------------------------------- parameterization simple
alter database sql_server_fundamentals__cte_ranking_and_partitioning set parameterization simple
--------------------------------------------------------------

-- then...
sp_executesql N'select count(*) from products where id > @id', N'@id int', 6;

-- and then
select * from PlanCache;

-- table hints
-- look at the query plan, and see the xml to note the EstimateRows property (right click on the select icon and select view xml)
select * from products;
-- EstimateRows="1000"
-- "when you process this statement, as soon as you get 9 rows send them back to the client and don't wait for the rest of the rows to buffer up things and when you get around to it, send the rest of the rows
select * from products option(fast 9);

-- creating a guide plan
-- we can tell sql to recognize an ad-hoc batch and apply a hint to it, in this case a "fast" option
-- ad-hoc batch:
select * from shifts;
select * from products;
-- we must have a unique name
exec sp_create_plan_guide
@name = N'FAST9',
@stmt = N'select * from products',
@type = N'SQL',
@module_or_batch = N'select * from shifts;
select * from products;',
@params=null,
@hints = 'OPTION (FAST 9)';

select * from shifts;select * from products;

exec sp_create_plan_guide
@name = N'FAST9_see_difference',
@stmt = N'select * from products',
@type = N'SQL',
@module_or_batch = N'select * from shifts;select * from products;',
@params=null,
@hints = 'OPTION (FAST 9)';

exec sp_create_plan_guide
@name = N'FAST9_sales_see_difference',
@stmt = N'select * from products',
@type = N'SQL',
@module_or_batch = N'select * from sales;select * from products;',
@params=null,
@hints = 'OPTION (FAST 9)';

-- not the same batch because of the \n
-- did not use the plan guide
select * from sales;
select * from products;

-- this however will use the plan guide
select * from sales;select * from products;

-- now we will remove the hint if the batch below is processed
select * from shifts;
select * from products option(fast 9);

exec sp_create_plan_guide
@name = N'NOFAST9v2',
@stmt = N'select * from products option(fast 9)',
@type = N'SQL',
@module_or_batch = N'select * from shifts;
select * from products option(fast 9);',
@params=null,
@hints=null;

dbcc freeproccache;
select * from PlanCache; 

-- managing plan guides

-------------------------------------- to see all plan guides
select * from sys.plan_guides;
-------------------------------------------------------------

-------------------------------------- disable plan guide
sp_control_plan_guide
@operation = N'disable',
@name = N'FAST9'
----------------------------------------------------------

-------------------------------------- enable plan guide
sp_control_plan_guide
@operation = N'enable',
@name = N'FAST9'
--------------------------------------------------------

-------------------------------------- drop plan guide
sp_control_plan_guide
@operation = N'drop',
@name = N'FAST9'
------------------------------------------------------

select * from shifts;
select * from products option(fast 9);

-- in cases where we want to two plan guides (one fast 9 and another fast 5) for the same batch statement,
exec sp_create_plan_guide
@name = N'FAST5',
@stmt = N'select * from products',
@type = N'SQL',
@module_or_batch = N'select * from shifts;
select * from products;',
@params=null,
@hints = 'OPTION (FAST 5)';

-- will throw error because there can only be one plan guide that matches both the batch and the statement

-- to fix, disable FAST9 then create this one


-------------------------------------- disable all plan guides
sp_control_plan_guide
@operation = N'disable all'
------------------------------------------------------

-------------------------------------- enable all plan guides
sp_control_plan_guide
@operation = N'enable all'
------------------------------------------------------

-------------------------------------- drop all plan guides
sp_control_plan_guide
@operation = N'drop all'
------------------------------------------------------

----------------------------------------------------------------------------------------
-- if you want to create a plan guide from an existing query plan so that it sticks becuase when shutdown/restart i8t will empty the plan cache and  all those plans will be rebuilt, possibly in a different way
-- one way to prevent that is to create a plan guide that applies the exact same query plan all the time

-- 0. clear plan cache
dbcc freeproccache;

-- 1. execute the batch
select * from shifts;
select * from products option(fast 9);

-- 2. find the plan handle
select * from sys.dm_exec_cached_plans
cross apply sys.dm_exec_sql_text(plan_handle);

-- 0x0600060050DE67049082E24E1B02000001000000000000000000000000000000000000000000000000000000

-- 3. use 
exec sp_create_plan_guide_from_handle @name = N'G1',
@plan_handle = 0x0600060050DE67049082E24E1B02000001000000000000000000000000000000000000000000000000000000

-- 4. verify
select * from sys.plan_guides;

-- 5. notice that for each statement in batch a seperate plan guide was created yet both refer the same batch

-------------------------- make plan guide for an object ---------------------------
----------------- proc, multi-line table value func, trigger, 

-- 0. remove all plan guides (just so we know where were at)
sp_control_plan_guide
@operation = N'drop all'

-- 1. create/identify stored proc
if exists (select * from sys.objects where object_id = object_id(N'AllProductsBatch') and type in (N'P', N'PC'))
drop proc AllProductsBatch;

create proc AllProductsBatch
as
select * from shifts;
select * from products;

-- 2. clear plan cache
dbcc freeproccache;

-- 3. execute sproc
exec AllProductsBatch;

-- 4. view plan cache
select * from PlanCache;

-- 5. see query_plan and look at estimatedRows = 1000

-- 6. create a plan guide for the proc

-- a. @type = 'OBJECT';
-- b. @module_or_batch = [procName]
-- c. @stmt = statement from proc to act on
exec sp_create_plan_guide
@name = N'FAST9_proc',
@stmt = N'select * from products',
@type = N'OBJECT',
@module_or_batch = N'AllProductsBatch',
@params=null,
@hints = 'OPTION (FAST 9)';

-- 7. clear plan cache
dbcc freeproccache;

-- 8. exec
exec AllProductsBatch;

-- 9. view plan cache and plan guide, see estimatedRows = 9 and notice planGuide was used
select * from PlanCache;

------------------------------------- hint: optimize for
-- use case: have proc with input params, 1st time plan created, creates based on input params, but you know that another param would be best for optimization, so...

-- 0. remove all plan guides (just so we know where were at)
sp_control_plan_guide
@operation = N'drop all'
go
-- 1. clear plan cache
dbcc freeproccache;
go
-- 2. assume the proc
if exists (select * from sys.objects where object_id = object_id(N'AllProductsBatch_wParams') and type in (N'P', N'PC'))
drop proc AllProductsBatch_wParams;
go
create proc AllProductsBatch_wParams(@id int)
as
select * from shifts;
select * from products where id > @id;
go
-- 3. exec
exec AllProductsBatch_wParams 10;
go
-- 4. view plan cache
select * from PlanCache;
go
-- 5. create a plan guide for the proc

-- a. @type = 'OBJECT';
-- b. @module_or_batch = [procName]
-- c. @stmt = statement from proc to act on
exec sp_create_plan_guide
@name = N'OPTIMIZE_FOR_99_proc',
@stmt = N'select * from products where id > @id',
@type = N'OBJECT',
@module_or_batch = N'AllProductsBatch_wParams',
@params=null,
@hints = 'OPTION (OPTIMIZE FOR (@id = 99))';
go
-- 6. exec
exec AllProductsBatch_wParams 10;
go
-- 7. view plan cache and plan guide, see ColumnReference = 99 regardless of what @id was supplied
select * from PlanCache;

-- summary: 
	-- a. so we optimized for '99' regardless of the input param
	-- b. useful to get sql server to get the right set of input variables so it will make good choices on how to build the query plan

------------------------------------- template plan guides
-- use case: we can control how individual plan guides are created (forced/simple)

-- 0. clear plan cache
go
dbcc freeproccache;
go
-- 1. ensure db is set to paramaterization 'simple' (we could also do the compliment, and set to 'forced')
go
alter database sql_server_fundamentals__cte_ranking_and_partitioning set parameterization simple;
go
-- 2. exec magnitude compare query (so it does not get parameterized, also because paramaterization = simple)
go
select * from products where id > 99;
go
-- 3. view plan cache
-- notice it is shell query plan not full flegged query plan
go
select * from PlanCache;
go
-- 4. so now we will create a template guide for this query to cause its paramaterization to be forced even though the db is set at simple
	-- a. in other plan guides the text we've used for the statements has been the exact literal text in the batch, not for template guides
	-- b. here we have to use a normalized version of the text in the query
	-- c. we have to use the "sp_get_query_template"

declare @s nvarchar(max); -- normalized form of statement
declare @p nvarchar(max); -- the parameters for the statement
exec sp_get_query_template N'select * from products where id > 99;', @s output, @p output
select @s, @p

-- results
--select * from products where id > @0
--@0 int

-- a. @type = 'TEMPLATE';
-- b. @module_or_batch=null
-- c. @stmt = statement from proc to act on
exec sp_create_plan_guide
@name = N'ParamProduct',
@module_or_batch=null,
@stmt = N'select * from products where id > @0',
@type = N'TEMPLATE',
@hints = 'OPTION (parameterization forced)',
@params = N'@0 int';