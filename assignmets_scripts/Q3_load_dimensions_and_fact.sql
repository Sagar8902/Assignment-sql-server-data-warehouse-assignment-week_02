/*
================================================================================
 QUESTION 3 - GOLD LAYER - DIMENSION AND FACT TABLE LOADING
================================================================================

  Purpose:
      Load dimension and fact tables from the Bronze layer.

  Process:
      1. DELETE existing DW tables.
      2. Load dimension tables from bronze_* tables.
      3. Generate DateKey in YYYYMMDD format.
      4. Load FactTicketSales using surrogate keys from dimensions.
================================================================================
*/

-- ============================================================================
-- LOAD DIM_AIRCRAFT
-- ============================================================================

DELETE FROM dw.dim_aircraft;

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

DELETE FROM dw.dim_airport;

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

DELETE FROM dw.dim_city;

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

DELETE FROM dw.dim_country;

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

DELETE FROM dw.dim_flight;

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

DELETE FROM dw.dim_passenger;

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

DELETE FROM dw.dim_date;

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
    CONVERT(INT, CONVERT(VARCHAR(8), d.full_date, 112)),
    d.full_date,
    DAY(d.full_date),
    MONTH(d.full_date),
    YEAR(d.full_date),
    DATEPART(QUARTER, d.full_date)
FROM
(
    SELECT booking_date AS full_date
    FROM dbo.bronze_bookings
    WHERE booking_date IS NOT NULL

    UNION

    SELECT travel_date AS full_date
    FROM dbo.bronze_bookings
    WHERE travel_date IS NOT NULL
) AS d;

SELECT *
FROM dw.dim_date;


-- ============================================================================
-- LOAD FACT_TICKET_SALES
-- ============================================================================
-- Fact is populated by joining Bronze bookings to dimensions
-- using business keys and retrieving the corresponding surrogate keys.

DELETE FROM dw.fact_ticket_sales;

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

    booking_date.date_key,
    travel_date.date_key,

    f.flight_key,

    origin.airport_key,
    destination.airport_key,

    ac.aircraft_key,

    b.fare_class,
    b.booking_status,

    b.fare_amount,
    b.tax_amount,
    b.miles_earned
FROM dbo.bronze_bookings AS b

LEFT JOIN dw.dim_flight AS f
    ON b.flight_id = f.flight_id

LEFT JOIN dw.dim_passenger AS p
    ON b.passenger_id = p.passenger_id

LEFT JOIN dw.dim_aircraft AS ac
    ON f.aircraft_code = ac.aircraft_code

LEFT JOIN dw.dim_airport AS origin
    ON f.origin_airport_code = origin.airport_code

LEFT JOIN dw.dim_airport AS destination
    ON f.dest_airport_code = destination.airport_code

LEFT JOIN dw.dim_date AS booking_date
    ON b.booking_date = booking_date.full_date

LEFT JOIN dw.dim_date AS travel_date
    ON b.travel_date = travel_date.full_date;


-- ============================================================================
-- VALIDATE FACT TABLE
-- ============================================================================

SELECT *
FROM dw.fact_ticket_sales;
