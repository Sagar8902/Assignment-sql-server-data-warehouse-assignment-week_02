/*
================================================================================
 QUESTION 5 - PASSENGER DIMENSION - SCD TYPE 2
================================================================================

  Purpose:
      Load passenger data and maintain historical versions of changed records.

  SCD Type 2:
      - Existing changed passengers: expire old version and insert new version.
      - New passengers: insert as the current version.
      - Unchanged passengers: no action.
================================================================================
*/


-- ============================================================================
-- CREATE PASSENGER DIMENSION
-- ============================================================================
-- passenger_key = surrogate key
-- passenger_id  = stable business key
DROP TABLE IF EXISTS dw.dim_passenger;
GO

CREATE TABLE dw.dim_passenger
(
    passenger_key INT IDENTITY(1,1) PRIMARY KEY,

    passenger_id VARCHAR(6) NOT NULL,
    passenger_name VARCHAR(50),
    home_airport_code VARCHAR(3),
    frequent_flyer_tier VARCHAR(10),
    signup_date DATE,

    is_current BIT NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE NULL
);


-- ============================================================================
-- INITIAL LOAD
-- ============================================================================
-- Load the initial passenger version as the current record.
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


-- CHECK INITIAL LOAD

SELECT *
FROM dw.dim_passenger;


-- ============================================================================
-- EXPIRE CHANGED PASSENGER VERSIONS
-- ============================================================================
-- If the home airport or frequent flyer tier changes,
-- expire the existing current version.

UPDATE d
SET
    is_current = 0,
    effective_to = CAST(GETDATE() AS DATE)
FROM dw.dim_passenger AS d
JOIN dbo.stg_passenger_updates AS s
    ON d.passenger_id = s.passenger_id
WHERE d.is_current = 1
  AND
  (
      d.home_airport_code <> s.home_airport_code
      OR d.frequent_flyer_tier <> s.frequent_flyer_tier
  );


-- ============================================================================
-- INSERT NEW / UPDATED PASSENGER VERSIONS
-- ============================================================================
-- Insert brand-new passengers and new versions of changed passengers.
-- New versions become the current record.

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
    s.passenger_id,
    s.passenger_name,
    s.home_airport_code,
    s.frequent_flyer_tier,
    NULL AS signup_date,
    1 AS is_current,
    CAST(GETDATE() AS DATE) AS effective_from,
    NULL AS effective_to
FROM dbo.stg_passenger_updates AS s
LEFT JOIN dw.dim_passenger AS d
    ON s.passenger_id = d.passenger_id
   AND d.is_current = 1
WHERE d.passenger_key IS NULL
   OR d.home_airport_code <> s.home_airport_code
   OR d.frequent_flyer_tier <> s.frequent_flyer_tier;


-- ============================================================================
-- VALIDATE SCD TYPE 2 RESULTS
-- ============================================================================

SELECT *
FROM dw.dim_passenger;

SELECT *
FROM dbo.stg_passenger_updates;
