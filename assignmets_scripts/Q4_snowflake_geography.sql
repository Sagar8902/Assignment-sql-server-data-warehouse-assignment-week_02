/*
===============================================================================
QUESTION 4 - NORMALIZED AIRPORT / GEOGRAPHY DIMENSION
===============================================================================

PURPOSE:
Create a normalized geography hierarchy:

    Country
       ↓
     City
       ↓
    Airport

This creates a snowflake structure where airport belongs to a city
and city belongs to a country.

The fact table references dim_airport twice using role-playing keys:

    origin_airport_key
    destination_airport_key

Both keys reference dim_airport.airport_key.

The values for these two keys are sourced from the flight's
origin_airport_code and dest_airport_code, NOT from the passenger's
home_airport_code.
===============================================================================
*/


-- ============================================================================
-- DIM_COUNTRY
-- ============================================================================
DROP TABLE IF EXISTS dw.dim_country;
GO

CREATE TABLE dw.dim_country
(
    country_key INT IDENTITY(1,1) PRIMARY KEY,
    country_name VARCHAR(50) NOT NULL,
    region VARCHAR(50)
);


-- ============================================================================
-- DIM_CITY
-- ============================================================================
DROP TABLE IF EXISTS dw.dim_city;
GO

CREATE TABLE dw.dim_city
(
    city_key INT IDENTITY(1,1) PRIMARY KEY,
    city_name VARCHAR(50) NOT NULL,
    country_key INT NOT NULL,

    CONSTRAINT FK_dim_city_country
        FOREIGN KEY (country_key)
        REFERENCES dw.dim_country(country_key)
);


-- ============================================================================
-- DIM_AIRPORT
-- ============================================================================
DROP TABLE IF EXISTS dw.dim_airport;
GO

CREATE TABLE dw.dim_airport
(
    airport_key INT IDENTITY(1,1) PRIMARY KEY,
    airport_code VARCHAR(3) NOT NULL,
    airport_name VARCHAR(50),
    city_key INT NOT NULL,

    CONSTRAINT FK_dim_airport_city
        FOREIGN KEY (city_key)
        REFERENCES dw.dim_city(city_key)
);
