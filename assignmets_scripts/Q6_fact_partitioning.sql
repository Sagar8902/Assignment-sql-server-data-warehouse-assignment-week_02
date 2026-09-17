/*
================================================================================
QUESTION 6 - FACT TABLE PARTITIONING
================================================================================

Partition Key:
    travel_date_key

Purpose:
    Physically partition the fact_ticket_sales table using travel_date_key
    and demonstrate partition elimination using actual execution plans.

Process:
    1. Drop the existing fact table.
    2. Create the partition function.
    3. Create the partition scheme.
    4. Create the fact table on the partition scheme.
    5. Load data into the fact table.
    6. Verify physical partitioning.
    7. Verify the partition column.
    8. Check rows in each partition.
    9. Test partition elimination using the partition key.
   10. Compare with a query using a non-partition key.

================================================================================
*/


/*
================================================================================
STEP 1 - DROP EXISTING FACT TABLE
================================================================================
*/

IF OBJECT_ID('dw.fact_ticket_sales', 'U') IS NOT NULL
BEGIN
    DROP TABLE dw.fact_ticket_sales;
END;
GO


/*
================================================================================
STEP 2 - CREATE PARTITION FUNCTION
================================================================================

Partition boundaries:
    < 20240101
    20240101 - 20241231
    20250101 - 20251231
    >= 20260101

RANGE RIGHT means the boundary value belongs to the partition on the right.
================================================================================
*/

CREATE PARTITION FUNCTION pf_ticket_sales_date (INT)
AS RANGE RIGHT
FOR VALUES
(
    20240101,
    20250101,
    20260101
);
GO


/*
================================================================================
STEP 3 - CREATE PARTITION SCHEME
================================================================================
*/

CREATE PARTITION SCHEME ps_ticket_sales_date
AS PARTITION pf_ticket_sales_date
ALL TO ([PRIMARY]);
GO


/*
================================================================================
STEP 4 - CREATE PARTITIONED FACT TABLE
================================================================================

The table is physically placed on the partition scheme using travel_date_key.

The clustered primary key includes travel_date_key so that the clustered
index can be aligned with the partition scheme.
================================================================================
*/

CREATE TABLE dw.fact_ticket_sales
(
    ticket_sales_key INT IDENTITY(1,1) NOT NULL,

    booking_id BIGINT NOT NULL,

    booking_date_key INT NOT NULL,
    travel_date_key INT NOT NULL,

    passenger_key INT NOT NULL,
    flight_key INT NOT NULL,

    origin_airport_key INT NOT NULL,
    destination_airport_key INT NOT NULL,

    aircraft_key INT NOT NULL,

    fare_class VARCHAR(50) NOT NULL,
    booking_status VARCHAR(50) NOT NULL,

    fare_amount DECIMAL(18,2) NOT NULL,
    tax_amount DECIMAL(18,2) NOT NULL,
    miles_earned INT NOT NULL,

    CONSTRAINT PK_fact_ticket_sales
        PRIMARY KEY CLUSTERED
        (
            ticket_sales_key,
            travel_date_key
        )
        ON ps_ticket_sales_date(travel_date_key)
)
ON ps_ticket_sales_date(travel_date_key);
GO


/*
================================================================================
STEP 5 - LOAD DATA INTO FACT TABLE
================================================================================
*/

INSERT INTO dw.fact_ticket_sales
(
    booking_id,
    passenger_key,
    booking_date_key,
    travel_date_key,
    flight_key,
    origin_airport_key,
    destination_airport_key,
    aircraft_key,
    fare_class,
    booking_status,
    fare_amount,
    tax_amount,
    miles_earned
)
SELECT
    b.booking_id,

    p.passenger_key,

    bd.date_key AS booking_date_key,
    td.date_key AS travel_date_key,

    f.flight_key,

    origin.airport_key AS origin_airport_key,
    destination.airport_key AS destination_airport_key,

    ac.aircraft_key,

    b.fare_class,
    b.booking_status,

    b.fare_amount,
    b.tax_amount,
    b.miles_earned

FROM dbo.bronze_bookings AS b

LEFT JOIN dw.dim_passenger AS p
    ON b.passenger_id = p.passenger_id

LEFT JOIN dw.dim_flight AS f
    ON b.flight_id = f.flight_id

LEFT JOIN dw.dim_aircraft AS ac
    ON f.aircraft_code = ac.aircraft_code

LEFT JOIN dw.dim_airport AS origin
    ON f.origin_airport_code = origin.airport_code

LEFT JOIN dw.dim_airport AS destination
    ON f.dest_airport_code = destination.airport_code

LEFT JOIN dw.dim_date AS bd
    ON b.booking_date = bd.full_date

LEFT JOIN dw.dim_date AS td
    ON b.travel_date = td.full_date;
GO


/*
================================================================================
STEP 6 - CHECK SOURCE TRAVEL DATE RANGE
================================================================================

This confirms the minimum and maximum travel dates available in the source data.
================================================================================
*/

SELECT
    MIN(travel_date) AS min_travel_date,
    MAX(travel_date) AS max_travel_date
FROM dbo.bronze_bookings;
GO


/*
================================================================================
STEP 7 - VERIFY PHYSICAL PARTITIONING
================================================================================

Expected:
    table_name       = fact_ticket_sales
    partition_scheme = ps_ticket_sales_date
    partition_function = pf_ticket_sales_date
================================================================================
*/

SELECT
    t.name AS table_name,
    i.name AS index_name,
    ps.name AS partition_scheme,
    pf.name AS partition_function
FROM sys.tables AS t

INNER JOIN sys.indexes AS i
    ON t.object_id = i.object_id

INNER JOIN sys.partition_schemes AS ps
    ON i.data_space_id = ps.data_space_id

INNER JOIN sys.partition_functions AS pf
    ON ps.function_id = pf.function_id

WHERE t.name = 'fact_ticket_sales';
GO


/*
================================================================================
STEP 8 - VERIFY PARTITION COLUMN
================================================================================

Expected partition column:
    travel_date_key
================================================================================
*/

SELECT
    t.name AS table_name,
    i.name AS index_name,
    c.name AS partition_column
FROM sys.tables AS t

INNER JOIN sys.indexes AS i
    ON t.object_id = i.object_id

INNER JOIN sys.index_columns AS ic
    ON i.object_id = ic.object_id
    AND i.index_id = ic.index_id

INNER JOIN sys.columns AS c
    ON ic.object_id = c.object_id
    AND ic.column_id = c.column_id

WHERE t.name = 'fact_ticket_sales'
  AND ic.partition_ordinal > 0;
GO


/*
================================================================================
STEP 9 - CHECK ROWS IN EACH PARTITION
================================================================================

This shows how many rows are physically stored in each partition.
================================================================================
*/

SELECT
    p.partition_number,
    p.rows
FROM sys.partitions AS p

INNER JOIN sys.tables AS t
    ON p.object_id = t.object_id

WHERE t.name = 'fact_ticket_sales'
  AND p.index_id = 1

ORDER BY
    p.partition_number;
GO


/*
================================================================================
STEP 10 - TEST PARTITION ELIMINATION
================================================================================

IMPORTANT:
    Enable "Include Actual Execution Plan" in SSMS before executing.

    Shortcut:
        CTRL + M

This query filters directly on the partition key:
    travel_date_key

Expected:
    SQL Server should be able to eliminate unnecessary partitions and
    access only the relevant partition(s).
================================================================================
*/

SELECT *
FROM dw.fact_ticket_sales
WHERE travel_date_key BETWEEN 20260101 AND 20260131
ORDER BY travel_date_key;
GO


/*
================================================================================
STEP 11 - TEST QUERY USING NON-PARTITION KEY
================================================================================

This query filters on passenger_key instead of travel_date_key.

It is included for comparison with the partition-key query above.
================================================================================
*/

SELECT *
FROM dw.fact_ticket_sales
WHERE passenger_key = 100
ORDER BY travel_date_key;
GO


/*
================================================================================
END OF QUESTION 6
================================================================================
*/
