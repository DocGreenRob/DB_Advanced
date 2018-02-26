SP_HELP PHYSICAL_ENTRY

-------------------() put in #TempTable because we can not use joins when PIVOTing

GO
SELECT * FROM
(
SELECT
	pe.PHYSICAL_ENTRY_ID
	, pe.START_TIME
	, pe.END_TIME
	, pe.REPS
	, pe.[WEIGHT]
	, pe.DISTANCE
	, ex.EXERCISE
	, ex.BODY_PART
FROM PHYSICAL_ENTRY pe
JOIN EXERCISE ex ON pe.TYPE_TYPE_ID = ex.EXERCISE_ID
) AS X
PIVOT
(
	COUNT(PHYSICAL_ENTRY_ID)
	FOR BODY_PART IN ([Back], [Abs])
) AS pvt

/*
Msg 4104, Level 16, State 1, Line 4
The multi-part identifier "pe.PHYSICAL_ENTRY_ID" could not be bound.
Msg 4104, Level 16, State 1, Line 5
The multi-part identifier "pe.START_TIME" could not be bound.
Msg 4104, Level 16, State 1, Line 6
The multi-part identifier "pe.END_TIME" could not be bound.
Msg 4104, Level 16, State 1, Line 7
The multi-part identifier "pe.REPS" could not be bound.
Msg 4104, Level 16, State 1, Line 8
The multi-part identifier "pe.WEIGHT" could not be bound.
Msg 4104, Level 16, State 1, Line 9
The multi-part identifier "pe.DISTANCE" could not be bound.
Msg 4104, Level 16, State 1, Line 10
The multi-part identifier "ex.EXERCISE" could not be bound.
Msg 4104, Level 16, State 1, Line 11
The multi-part identifier "ex.BODY_PART" could not be bound.
*/

-------------------() put in #TempTable because we can not use joins when PIVOTing

--DROP TABLE #TempTbl
IF OBJECT_ID('tempdb..#TempTbl') IS NOT NULL
    DROP TABLE #TempTbl
GO
CREATE TABLE #TempTbl (ID INT, START_TIME DATETIME, END_TIME DATETIME, REPS INT, [WEIGHT] NUMERIC(18,2), DISTANCE NUMERIC(18,2), EXERCISE NVARCHAR(100), BODY_PART NVARCHAR(10))
GO
INSERT INTO #TempTbl
SELECT
	pe.PHYSICAL_ENTRY_ID
	, pe.START_TIME
	, pe.END_TIME
	, pe.REPS
	, pe.[WEIGHT]
	, pe.DISTANCE
	, ex.EXERCISE
	, ex.BODY_PART
FROM PHYSICAL_ENTRY pe
JOIN EXERCISE ex ON pe.TYPE_TYPE_ID = ex.EXERCISE_ID
GO

-------------------() get by body parts w/o sub-query
SELECT * FROM #TempTbl -- Mostly a Sub-Query (because we usually want to throw away some columns in the pivot table)
PIVOT
(
	COUNT(ID) -- Always an AGGREGATE
	FOR BODY_PART IN ([Abs], [Arms], [Back], [Chest], [Legs], [Shoulders]) -- Column to PIVOT on and the value from that column to do the PIVOT on itself 
) AS pvt

--SELECT DISTINCT(BODY_PART) FROM EXERCISE

-------------------() get by body parts
GO
SELECT 
	[DATE] AS 'Workout Date'
	, [Abs]
	, Arms
	, Back
	, Chest
	, Legs
	, Shoulders
FROM (
		SELECT 
			ID
			, CAST(END_TIME AS DATE) AS [DATE]
			, BODY_PART 
		FROM #TempTbl
	) 
AS t -- Now a Sub-Query
PIVOT
(
	COUNT(ID) -- Always an AGGREGATE
	FOR BODY_PART IN ([Abs], [Arms], [Back], [Chest], [Legs], [Shoulders]) 
) AS pvt
ORDER BY [DATE] DESC

-------------------() get by sum(REPS)
GO
SELECT * 
FROM (
		SELECT 
			REPS
			, CAST(END_TIME AS DATE) AS [DATE]
			, BODY_PART 
		FROM #TempTbl
	) 
AS t
PIVOT
(
	SUM(REPS)
	FOR BODY_PART IN ([Abs], [Arms], [Back], [Chest], [Legs], [Shoulders])
) AS pvt
ORDER BY [DATE] DESC

-------------------() get by sum(WEIGHT)
GO
SELECT * 
FROM (
		SELECT 
			[WEIGHT]
			, CAST(END_TIME AS DATE) AS [DATE]
			, BODY_PART 
		FROM #TempTbl
	) 
AS t
PIVOT
(
	SUM([WEIGHT])
	FOR BODY_PART IN ([Abs], [Arms], [Back], [Chest], [Legs], [Shoulders])
) AS pvt
ORDER BY [DATE] DESC

----------------------------------------------------- unpivot
-- 0. prep data
--DROP TABLE #TempTbl
IF OBJECT_ID('tempdb..#Unpivot') IS NOT NULL
    DROP TABLE #Unpivot
GO
CREATE TABLE #Unpivot 
	(
		WORKOUT_DATE DATE
		, [ABS] INT
		, ARMS INT
		, BACK INT
		, CHEST INT
		, LEGS INT
		, SHOULDERS INT
	)
GO
INSERT INTO #Unpivot
SELECT 
	[DATE] AS 'Workout Date'
	, [Abs]
	, Arms
	, Back
	, Chest
	, Legs
	, Shoulders
FROM (
		SELECT 
			ID
			, CAST(END_TIME AS DATE) AS [DATE]
			, BODY_PART 
		FROM #TempTbl
	) 
AS t -- Now a Sub-Query
PIVOT
(
	COUNT(ID) -- Always an AGGREGATE
	FOR BODY_PART IN ([Abs], [Arms], [Back], [Chest], [Legs], [Shoulders]) 
) AS pvt
	

SELECT * 
FROM #Unpivot 
ORDER BY WORKOUT_DATE DESC

-- 1. 
SELECT * FROM #Unpivot 
UNPIVOT
(
	VALUE_COLUMN FOR NAME_OF_COLUMN_PIVOTED IN ([Abs], [Arms], [Back], [Chest], [Legs], [Shoulders])
) AS X
WHERE X.VALUE_COLUMN <> 0
ORDER BY WORKOUT_DATE DESC, NAME_OF_COLUMN_PIVOTED

SELECT * FROM #Unpivot ORDER BY WORKOUT_DATE DESC
