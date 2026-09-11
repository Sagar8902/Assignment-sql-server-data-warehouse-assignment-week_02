/*
================================================================================
 QUESTION 3 - GOLD LAYER - DIMENSION AND FACT TABLE LOADING
================================================================================

  Purpose:
      Load dimension and fact tables from the Bronze layer.

  Process:
      1. Truncate existing DW tables.
      2. Load dimension tables from bronze_* tables.
      3. Generate DateKey in YYYYMMDD format.
      4. Load FactTicketSales using surrogate keys from dimensions.
================================================================================
*/

-- ============================================================================
-- LOAD DIM_AIRCRAFT
-- ============================================================================

TRUNCATE TABLE dw.dim_aircraft;

INSERT INTO dw.dim_aircraft
(
    aircraft_code,
    model,
    manufacturer,
    seat_capacity
)
SELECT
    aircraft_code,
    model,
    manufacturer,
    seat_capacity
FROM dbo.bronze_aircraft;

SELECT *
FROM dw.dim_aircraft;


-- ============================================================================
-- LOAD DIM_AIRPORT
-- ============================================================================

TRUNCATE TABLE dw.dim_airport;

INSERT INTO dw.dim_airport
(
    airport_code,
    airport_name,
    city_key
)
SELECT DISTINCT
    airport_code,
    airport_name,
    city_key
FROM dbo.bronze_airports AS a
JOIN dw.dim_city AS c
    ON a.city = c.city_name

SELECT *
FROM dw.dim_airport;


-- ============================================================================
-- LOAD DIM_CITY
-- ============================================================================

TRUNCATE TABLE dw.dim_city;

INSERT INTO dw.dim_city
(
    city_name,
    country_key
)

SELECT DISTINCT
    city,
    c.country_key
FROM dbo.bronze_airports AS a
LEFT JOIN dw.dim_country AS c
ON a.country = c.country_name

SELECT *
FROM dw.dim_city;



-- ============================================================================
-- LOAD DIM_COUNTRY
-- ============================================================================

TRUNCATE TABLE dw.dim_country;

INSERT INTO dw.dim_country
(
    country_name,
    region
)

SELECT DISTINCT
    country,
    region
FROM dbo.bronze_airports;

SELECT *
FROM dw.dim_country;


-- ============================================================================
-- LOAD DIM_FLIGHT
-- ============================================================================

TRUNCATE TABLE dw.dim_flight;

INSERT INTO dw.dim_flight
(
    flight_id,
    flight_number,
    origin_airport_code,
    dest_airport_code,
    aircraft_code,
    flight_date
)
SELECT
    flight_id,
    flight_number,
    origin_airport_code,
    dest_airport_code,
    aircraft_code,
    flight_date
FROM dbo.bronze_flights;

SELECT *
FROM dw.dim_flight;


-- ============================================================================
-- LOAD DIM_PASSENGER
-- ============================================================================

TRUNCATE TABLE dw.dim_passenger;

INSERT INTO dw.dim_passenger
(
    passenger_id,
    passenger_name,
    home_airport_code,
    frequent_flyer_tier,
    signup_date,
    is_current,
    effective_from,
    effective_to
)
SELECT
    passenger_id,
    passenger_name,
    home_airport_code,
    frequent_flyer_tier,
    signup_date,
    1 AS is_current,
    signup_date AS effective_from,
    NULL AS effective_to
FROM dbo.bronze_passengers;

SELECT *
FROM dw.dim_passenger;


-- ============================================================================
-- LOAD DIM_DATE
-- ============================================================================
-- DateKey is generated in YYYYMMDD integer format.
-- Example: 2026-01-03 → 20260103

TRUNCATE TABLE dw.dim_date;

INSERT INTO dw.dim_date
(
    date_key,
    full_date,
    day,
    month,
    year,
    quarter
)
SELECT DISTINCT
    CONVERT(INT, CONVERT(VARCHAR(8), booking_date, 112)) AS date_key,
    booking_date AS full_date,
    DAY(booking_date) AS day,
    MONTH(booking_date) AS month,
    YEAR(booking_date) AS year,
    DATEPART(QUARTER, booking_date) AS quarter
FROM dbo.bronze_bookings
WHERE booking_date IS NOT NULL;

SELECT *
FROM dw.dim_date;


-- ============================================================================
-- LOAD FACT_TICKET_SALES
-- ============================================================================
-- Fact is populated by joining Bronze bookings to dimensions
-- using business keys and retrieving the corresponding surrogate keys.

TRUNCATE TABLE dw.fact_ticket_sales;

INSERT INTO dw.fact_ticket_sales
(
    booking_id,
    passenger_key,
    date_key,
    flight_key,
    airport_key,
    aircraft_key,
    fare_amount,
    tax_amount,
    miles_earned
)
SELECT
    b.booking_id,
    p.passenger_key,
    d.date_key,
    f.flight_key,
    a.airport_key,
    ac.aircraft_key,
    b.fare_amount,
    b.tax_amount,
    b.miles_earned
FROM dbo.bronze_bookings AS b

LEFT JOIN dw.dim_date AS d
    ON b.booking_date = d.full_date

LEFT JOIN dw.dim_flight AS f
    ON b.flight_id = f.flight_id

LEFT JOIN dw.dim_passenger AS p
    ON b.passenger_id = p.passenger_id

LEFT JOIN dw.dim_aircraft AS ac
    ON f.aircraft_code = ac.aircraft_code

LEFT JOIN dw.dim_airport AS a
    ON p.home_airport_code = a.airport_code;


-- ============================================================================
-- VALIDATE FACT TABLE
-- ============================================================================

SELECT *
FROM dw.fact_ticket_sales;
