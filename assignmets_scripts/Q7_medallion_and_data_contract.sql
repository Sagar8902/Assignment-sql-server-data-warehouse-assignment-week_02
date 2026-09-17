/*
================================================================================
QUESTION 7 - MEDALLION ARCHITECTURE & DATA CONTRACT
================================================================================

Project:
    Data Warehouse and Analytics

Deliverables:
    (A) Map every table to a Medallion Architecture layer.
    (B) Define the data contract for dbo.bronze_bookings.

Architecture:
    BRONZE  -> Raw source data
    SILVER  -> Staged / cleaned / transformed data
    GOLD    -> Business-ready analytical data

================================================================================
*/


/*
================================================================================
PART A - MEDALLION ARCHITECTURE LAYER MAPPING
================================================================================


BRONZE
------
Raw source data loaded from the source systems.

    ├── dbo.bronze_bookings
    ├── dbo.bronze_passengers
    ├── dbo.bronze_flights
    ├── dbo.bronze_airports
    └── dbo.bronze_aircraft


SILVER
------
Staged and transformed data used for downstream processing.

    └── dw.stg_passenger_updates


GOLD
----
Business-ready dimensional model used for analytics and reporting.

    ├── dw.dim_date
    ├── dw.dim_passenger
    ├── dw.dim_flight
    ├── dw.dim_airport
    ├── dw.dim_aircraft
    ├── dw.dim_city
    ├── dw.dim_country
    └── dw.fact_ticket_sales


MEDALLION SUMMARY
-----------------

    Bronze = Raw source data
    Silver = Staged / cleaned / transformed data
    Gold   = Business-ready analytical data

================================================================================
*/


/*
================================================================================
PART B - DATA CONTRACT FOR dbo.bronze_bookings
================================================================================

The data contract defines the expected structure, grain, valid values,
freshness, ownership, and change-management rules for the bronze_bookings
source feed.

================================================================================
*/


/*
================================================================================
1. DATASET
================================================================================
*/

-- Dataset Name:
--     dbo.bronze_bookings

-- Purpose:
--     Raw booking and ticket-level transaction data used to populate
--     the Gold dw.fact_ticket_sales table.


/*
================================================================================
2. GRAIN
================================================================================
*/

-- Grain:
--
-- One row represents one flight ticket/fare for a booking.
--
-- The row contains booking information, passenger and flight references,
-- booking and travel dates, fare information, booking status, tax,
-- and miles earned.


/*
================================================================================
3. SOURCE SCHEMA
================================================================================

Expected source columns:

    Column             Data Type          Required
    ------------------------------------------------
    booking_id         INT                YES
    passenger_id       INT                YES
    flight_id          INT                YES
    booking_date       DATE               YES
    travel_date        DATE               YES
    fare_class         VARCHAR            YES
    fare_amount        DECIMAL(18,2)      YES
    tax_amount         DECIMAL(18,2)      YES
    booking_status     VARCHAR            YES
    miles_earned       INT                YES

NOTE:
    The data types above are the logical contract.

    They should be validated against the actual
    dbo.bronze_bookings table definition.

================================================================================
*/


/*
================================================================================
4. ALLOWED VALUES
================================================================================
*/

-- fare_class:
--
--     Economy
--     Business
--     Premium Economy


-- booking_status:
--
--     Confirmed
--     Cancelled


/*
================================================================================
5. DATE REQUIREMENTS
================================================================================

The source provides TWO important dates:

    booking_date
        = Date when the booking was made.

    travel_date
        = Date when the passenger travels.

Both dates are required because the Gold fact table contains:

    booking_date_key
    travel_date_key

travel_date_key is also used as the partitioning key for
dw.fact_ticket_sales.

================================================================================
*/


/*
================================================================================
6. FRESHNESS / DELIVERY SLA
================================================================================
*/

-- Expected delivery frequency:
--     Daily

-- Expected delivery time:
--     By 06:00 UTC

-- Expected data:
--     Previous day's booking data

-- SLA Type:
--     Daily delivery

-- NOTE:
--     This SLA is a project assumption for this assignment.


/*
================================================================================
7. DATA OWNER
================================================================================
*/

-- Business Owner:
--     Booking / Reservation Source System Team

-- Technical Owner:
--     Data Engineering Team


/*
================================================================================
8. DATA QUALITY EXPECTATIONS
================================================================================

The bronze_bookings producer should ensure:

    1. booking_id is present.
    2. passenger_id is present.
    3. flight_id is present.
    4. booking_date is present.
    5. travel_date is present.
    6. fare_class contains an agreed valid value.
    7. booking_status contains an agreed valid value.
    8. fare_amount is numeric.
    9. tax_amount is numeric.
   10. miles_earned is numeric.

The source data should not contain unexpected NULL values in required
columns.

================================================================================
*/


/*
================================================================================
9. CHANGE MANAGEMENT
================================================================================

BREAKING CHANGE
---------------

Changing an existing column's meaning or incompatible data type is a
breaking change.

Example:

    Changing:

        fare_amount DECIMAL(18,2)

    to:

        fare_amount VARCHAR(50)

    would be a breaking change because downstream transformations expect
    fare_amount to be numeric.


NON-BREAKING CHANGE
-------------------

Adding a new nullable column is considered a non-breaking change.

Example:

    Adding:

        booking_channel VARCHAR(50) NULL

    would be a non-breaking change because existing columns and their
    meanings remain unchanged.

================================================================================
*/


/*
================================================================================
10. DATA CONTRACT SUMMARY
================================================================================

The bronze_bookings producer must:

    - Maintain agreed column names.
    - Maintain agreed data types.
    - Provide required booking and travel dates.
    - Provide valid fare_class values.
    - Provide valid booking_status values.
    - Provide numeric fare_amount and tax_amount.
    - Deliver data according to the agreed daily SLA.
    - Notify the Data Engineering Team before making breaking changes.

================================================================================
*/


/*
================================================================================
OPTIONAL VALIDATION 1 - CHECK ACTUAL BRONZE_BOOKINGS SCHEMA
================================================================================
*/

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'bronze_bookings'
ORDER BY ORDINAL_POSITION;
GO


/*
================================================================================
OPTIONAL VALIDATION 2 - CHECK FARE CLASS VALUES
================================================================================
*/

SELECT DISTINCT
    fare_class
FROM dbo.bronze_bookings
ORDER BY fare_class;
GO


/*
================================================================================
OPTIONAL VALIDATION 3 - CHECK BOOKING STATUS VALUES
================================================================================
*/

SELECT DISTINCT
    booking_status
FROM dbo.bronze_bookings
ORDER BY booking_status;
GO


/*
================================================================================
OPTIONAL VALIDATION 4 - CHECK NULLS IN REQUIRED COLUMNS
================================================================================
*/

SELECT
    COUNT(*) AS total_rows,

    SUM(CASE WHEN booking_id IS NULL THEN 1 ELSE 0 END)
        AS null_booking_id,

    SUM(CASE WHEN passenger_id IS NULL THEN 1 ELSE 0 END)
        AS null_passenger_id,

    SUM(CASE WHEN flight_id IS NULL THEN 1 ELSE 0 END)
        AS null_flight_id,

    SUM(CASE WHEN booking_date IS NULL THEN 1 ELSE 0 END)
        AS null_booking_date,

    SUM(CASE WHEN travel_date IS NULL THEN 1 ELSE 0 END)
        AS null_travel_date,

    SUM(CASE WHEN fare_class IS NULL THEN 1 ELSE 0 END)
        AS null_fare_class,

    SUM(CASE WHEN booking_status IS NULL THEN 1 ELSE 0 END)
        AS null_booking_status,

    SUM(CASE WHEN fare_amount IS NULL THEN 1 ELSE 0 END)
        AS null_fare_amount,

    SUM(CASE WHEN tax_amount IS NULL THEN 1 ELSE 0 END)
        AS null_tax_amount,

    SUM(CASE WHEN miles_earned IS NULL THEN 1 ELSE 0 END)
        AS null_miles_earned

FROM dbo.bronze_bookings;
GO


/*
================================================================================
END OF QUESTION 7
================================================================================
*/
