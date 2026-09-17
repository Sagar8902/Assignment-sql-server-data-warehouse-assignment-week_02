/*
================================================================================
QUESTION 2 - DATA WAREHOUSE STAR SCHEMA
================================================================================
  Schema : dw
  Purpose: Create the dimensional model for ticket sales analysis.

  Fact Grain:
  One row in fact_ticket_sales represents one flight ticket/fare for a booking,
  including fare amount, tax amount, and miles earned.
================================================================================
*/


-- ============================================================================
-- CREATE DATA WAREHOUSE SCHEMA
-- ============================================================================

CREATE SCHEMA dw;


-- ============================================================================
-- DATE DIMENSION
-- ============================================================================
-- Stores calendar information used for filtering and time-based analysis.
DROP TABLE IF EXISTS dw.dim_date;
GO

CREATE TABLE dw.dim_date
(
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    day INT,
    month INT,
    year INT,
    quarter INT
);


-- ============================================================================
-- AIRCRAFT DIMENSION
-- ============================================================================
-- Stores aircraft details.
-- aircraft_key = surrogate key
-- aircraft_code = business key from the source system
DROP TABLE IF EXISTS dw.dim_aircraft;
GO

CREATE TABLE dw.dim_aircraft
(
    aircraft_key INT IDENTITY(1,1) PRIMARY KEY,
    aircraft_code VARCHAR(4) NOT NULL,
    model VARCHAR(10),
    manufacturer VARCHAR(10),
    seat_capacity INT
);


-- ============================================================================
-- FLIGHT DIMENSION
-- ============================================================================
-- Stores flight-related descriptive information.
-- flight_key = surrogate key
-- flight_id = business key from the source system
DROP TABLE IF EXISTS dw.dim_flight;
GO

CREATE TABLE dw.dim_flight
(
    flight_key INT IDENTITY(1,1) PRIMARY KEY,
    flight_id VARCHAR(5) NOT NULL,
    flight_number VARCHAR(5),
    origin_airport_code VARCHAR(3),
    dest_airport_code VARCHAR(3),
    aircraft_code VARCHAR(4),
    flight_date DATE
);

-- ============================================================================
-- PASSENGER DIMENSION
-- ============================================================================
-- Stores passenger-related descriptive information.
-- passenger_key = surrogate key
-- passenger_id = business key from the source system
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
    is_current INT,
    effective_from DATE,
    effective_to DATE
);


-- ============================================================================
-- FACT TABLE: TICKET SALES
-- ============================================================================
-- Grain:
-- One row represents one flight ticket/fare for a booking.
--
-- Dimension keys are stored as foreign keys.
-- Measures are additive and can be aggregated across fact rows.
DROP TABLE IF EXISTS dw.fact_ticket_sales;
GO

CREATE TABLE dw.fact_ticket_sales
(
    ticket_sales_key INT IDENTITY(1,1) PRIMARY KEY,

    -- Business/transaction identifier
    booking_id INT NOT NULL,
    booking_date_key INT,
    travel_date_key INT,

    passenger_key INT,
    flight_key INT,

    origin_airport_key INT,
    destination_airport_key INT,

    aircraft_key INT,

    fare_class VARCHAR(50),
    booking_status VARCHAR(50),

    -- Additive measures
    fare_amount DECIMAL(18,2),
    tax_amount DECIMAL(18,2),
    miles_earned INT,

    -- Foreign key relationships
    FOREIGN KEY (travel_date_key)
        REFERENCES dw.dim_date(date_key),

    FOREIGN KEY (passenger_key)
        REFERENCES dw.dim_passenger(passenger_key),

    FOREIGN KEY (flight_key)
        REFERENCES dw.dim_flight(flight_key),

    FOREIGN KEY (aircraft_key)
        REFERENCES dw.dim_aircraft(aircraft_key),

    FOREIGN KEY (origin_airport_key)
        REFERENCES dw.dim_airport(airport_key),

    FOREIGN KEY (destination_airport_key)
        REFERENCES dw.dim_airport(airport_key)
);

