select meal_id, meal_item_id, ntile(4) over (order by meal_item_id) as quartile
from meal

select * from EXERCISE

select body_part, rank() over (partition by body_part order by body_part)
from exercise

select *
from meal m
join MEAL_ITEM mi on m.MEAL_ITEM_ID = mi.MEAL_ITEM_ID

-- what do I eat the most?
select meal_item, rank() over(order by [weight]) as rank
from meal m
join MEAL_ITEM mi on m.MEAL_ITEM_ID = mi.MEAL_ITEM_ID
order by weight desc

-- rank the volumes of the foods I consume (what's the heaviest things I consume)
select meal_item, rank() over(partition by mi.meal_item_id order by [weight]) as rank
from meal m
join MEAL_ITEM mi on m.MEAL_ITEM_ID = mi.MEAL_ITEM_ID
order by rank desc

with myMeals
as
(select * from meal)
select * from myMeals

with myMeals(col1, col2)
as
(select meal_item_id, [weight] from meal)
select * from myMeals

-- what is my favorite / least exercise
-- what Day of the week is my favorite / least
-- what is the average time I spend per exercise (min/mid/max)

with exercises
as
(select * from EXERCISE)
 select * from exercises

select * from PHYSICAL_ENTRY  pe
where pe.TYPE_ID = (select type_id from [TYPE] t where t.[TYPE] = 'Exercise')

select *, cast((pe.END_TIME - pe.START_TIME) as time(7)) as duration from PHYSICAL_ENTRY  pe
where pe.TYPE_ID = (select type_id from [TYPE] t where t.[TYPE] = 'Exercise')

select e.BODY_PART, e.EXERCISE, reps, [weight], distance, cast((pe.END_TIME - pe.START_TIME) as time(7)) as duration 
from PHYSICAL_ENTRY  pe
join exercise e on pe.TYPE_TYPE_ID = e.EXERCISE_ID
where pe.TYPE_ID = (select type_id from [TYPE] t where t.[TYPE] = 'Exercise')
order by e.BODY_PART, e.EXERCISE


select sum(reps) as reps, sum([weight]) as weight, sum(distance) as distance, sum(datediff(minute, '0:00:00', cast((pe.END_TIME - pe.START_TIME) as time(7)))) as duration 
from PHYSICAL_ENTRY  pe
join exercise e on pe.TYPE_TYPE_ID = e.EXERCISE_ID
where pe.TYPE_ID = (select type_id from [TYPE] t where t.[TYPE] = 'Exercise')
group by body_part, exercise

select sum(reps) as reps, sum([weight]) as weight, sum(distance) as distance, sum(datediff(minute, '0:00:00', cast((pe.END_TIME - pe.START_TIME) as time(7)))) as duration 
from PHYSICAL_ENTRY  pe
join exercise e on pe.TYPE_TYPE_ID = e.EXERCISE_ID
where pe.TYPE_ID = (select type_id from [TYPE] t where t.[TYPE] = 'Exercise')
and pe.START_TIME > GetDate() - 14
group by body_part

select sum(reps) as reps, sum([weight]) as weight, sum(distance) as distance, sum(datediff(minute, '0:00:00', cast((pe.END_TIME - pe.START_TIME) as time(7)))) as duration 
from PHYSICAL_ENTRY  pe
join exercise e on pe.TYPE_TYPE_ID = e.EXERCISE_ID
where pe.TYPE_ID = (select type_id from [TYPE] t where t.[TYPE] = 'Exercise')
group by exercise

select 
	sum(reps) as reps
	, sum([weight]) as weight
	, sum(distance) as distance
	, sum(datediff(minute, '0:00:00', cast((pe.END_TIME - pe.START_TIME) as time(7)))) as duration
from PHYSICAL_ENTRY  pe
join exercise e on pe.TYPE_TYPE_ID = e.EXERCISE_ID
where pe.TYPE_ID = (select type_id from [TYPE] t where t.[TYPE] = 'Exercise')
group by exercise

select 
	* 
	, row_number() over (order by [weight] desc)
from PHYSICAL_ENTRY  pe
where pe.TYPE_ID = (select type_id from [TYPE] t where t.[TYPE] = 'Exercise')

-- use CTE to enable paging
;with rowNum
as
(
	select 
		* 
		, row_number() over (order by [weight] desc) as rowNumber
	from PHYSICAL_ENTRY  pe
	where pe.TYPE_ID = (select type_id from [TYPE] t where t.[TYPE] = 'Exercise')
)
select * from rowNum rn
where rn.rowNumber between 5 and 10
