/*
================================================================================
  QUESTION 7 - MEDALLION ARCHITECTURE & DATA CONTRACT
================================================================================

  Project: Data Warehouse and Analytics

  Deliverables:
      (A) Map every table to a Medallion Architecture layer.
      (B) Define the data contract for the bronze_bookings feed.
================================================================================
*/


/*
================================================================================
  PART A - MEDALLION LAYER MAPPING
================================================================================

  
BRONZE
├── bronze_bookings
├── bronze_passengers
├── bronze_flights
├── bronze_airports
└── bronze_aircraft

SILVER
└── stg_passenger_updates

GOLD
├── dim_date
├── dim_passenger
├── dim_flight
├── dim_airport
├── dim_aircraft
├── dim_city
├── dim_country
└── fact_ticket_sales


  MEDALLION SUMMARY
  -----------------
  Bronze = Raw source data
  Silver = Staged / cleaned / transformed data
  Gold   = Business-ready analytical data
================================================================================
*/


/*
================================================================================
  PART B - DATA CONTRACT FOR BRONZE_BOOKINGS
================================================================================

  1. DATASET
  ----------
  Dataset Name : dbo.bronze_bookings
  Purpose      : Raw booking and ticket-level transaction data used to
                 populate the Gold fact_ticket_sales table.


  2. GRAIN
  --------
  One row represents one flight ticket/fare for a booking, including
  fare amount, tax amount, and miles earned.


  3. SCHEMA
  ---------

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
  The data types above should match the actual dbo.bronze_bookings
  table definition.


  4. ALLOWED VALUES
  -----------------

  fare_class:
      - Economy
      - Business
      - Premium Economy

  booking_status:
      - Confirmed
      - Cancelled


  5. FRESHNESS / DELIVERY SLA
  ---------------------------

  The bronze_bookings feed is expected to be delivered once per day
  and should be available by 06:00 UTC for the previous day's booking data.

  SLA TYPE:
      Daily delivery

  NOTE:
      This SLA is a project assumption for this assignment.


  6. DATA OWNER
  -------------

  Business Owner:
      Booking / Reservation Source System Team

  Technical Owner:
      Data Engineering Team


  7. CHANGE MANAGEMENT
  --------------------

  BREAKING CHANGE:
      Changing fare_amount from DECIMAL(18,2) to VARCHAR(50) would be
      a breaking change because downstream transformations expect a
      numeric value.

  NON-BREAKING CHANGE:
      Adding a new nullable column such as booking_channel would be
      a non-breaking change because existing columns and their meanings
      remain unchanged.


  8. DATA CONTRACT SUMMARY
  ------------------------

  The bronze_bookings producer must:

      - Maintain the agreed column names and data types.
      - Provide valid fare_class values.
      - Provide valid booking_status values.
      - Deliver the feed according to the agreed daily SLA.
      - Notify the Data Engineering Team before making breaking changes.
================================================================================
*/


-- ============================================================================
-- OPTIONAL VALIDATION: CHECK ACTUAL BRONZE_BOOKINGS DATA TYPES
-- ============================================================================
-- Run this query to confirm that the contract matches your actual table.

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


-- ============================================================================
-- OPTIONAL VALIDATION: CHECK ALLOWED FARE CLASS VALUES
-- ============================================================================

SELECT DISTINCT
    fare_class
FROM dbo.bronze_bookings
ORDER BY fare_class;


-- ============================================================================
-- OPTIONAL VALIDATION: CHECK ALLOWED BOOKING STATUS VALUES
-- ============================================================================

SELECT DISTINCT
    booking_status
FROM dbo.bronze_bookings
ORDER BY booking_status;
