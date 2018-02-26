-- use case:
-- get general idea from table

-- inspects every row of table
SELECT * FROM PHYSICAL_ENTRY
WHERE 0.001 >= CAST(CHECKSUM(NEWID(), PHYSICAL_ENTRY_ID) & 0x7FFFFFFF AS FLOAT) / CAST(0x7FFFFFFF AS INT)
ORDER BY PHYSICAL_ENTRY_ID;

SELECT 
	*
	, CHECKSUM(NEWID(), PHYSICAL_ENTRY_ID) AS CHK_SUM
	, CAST(CHECKSUM(NEWID(), PHYSICAL_ENTRY_ID) & 0x7FFFFFFF AS FLOAT)
	, CAST(0x7FFFFFFF AS INT)
	, CAST(CHECKSUM(NEWID(), PHYSICAL_ENTRY_ID) & 0x7FFFFFFF AS FLOAT) / CAST(0x7FFFFFFF AS INT) 
FROM PHYSICAL_ENTRY
WHERE 0.001 >= CAST(CHECKSUM(NEWID(), PHYSICAL_ENTRY_ID) & 0x7FFFFFFF AS FLOAT) / CAST(0x7FFFFFFF AS INT)
ORDER BY PHYSICAL_ENTRY_ID;

-- uses pages
SELECT * FROM PHYSICAL_ENTRY
TABLESAMPLE (.1 PERCENT);

-- determine the effectiveness of the sample

-- goal: get the average and use it to compare against
-- 0. 
SELECT AVG([WEIGHT]) FROM PHYSICAL_ENTRY
-- 1.
SELECT AVG([WEIGHT]) FROM PHYSICAL_ENTRY
WHERE 0.001 >= CAST(CHECKSUM(NEWID(), PHYSICAL_ENTRY_ID) & 0x7FFFFFFF AS FLOAT) / CAST(0x7FFFFFFF AS INT);

SELECT AVG([WEIGHT]) FROM PHYSICAL_ENTRY
TABLESAMPLE (.1 PERCENT);

-- magnify difference
SELECT AVG([WEIGHT])-20 FROM PHYSICAL_ENTRY
WHERE 0.001 >= CAST(CHECKSUM(NEWID(), PHYSICAL_ENTRY_ID) & 0x7FFFFFFF AS FLOAT) / CAST(0x7FFFFFFF AS INT);

SELECT AVG([WEIGHT])-20 FROM PHYSICAL_ENTRY
TABLESAMPLE (.1 PERCENT);

------------------------------ TABLESAMPLE overloads()
SELECT * FROM PHYSICAL_ENTRY
TABLESAMPLE (1000 ROWS); -- Specify rows

SELECT * FROM PHYSICAL_ENTRY
TABLESAMPLE (100 ROWS) -- Specify rows
REPEATABLE(444); -- Specify seed

