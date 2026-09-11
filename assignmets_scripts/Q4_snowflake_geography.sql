-- ============================================================================
-- QUESTION 4 - NORMALIZED AIRPORT DIMENSION
-- ============================================================================
-- Stores country details.
-- country_key = surrogate key
-- country_name = business key from the source system

CREATE TABLE dw.dim_country
(
    country_key INT IDENTITY(1,1) PRIMARY KEY,
    country_name VARCHAR(50) NOT NULL,
    region VARCHAR(50)
);


-- ============================================================================
-- NORMALIZED AIRPORT DIMENSION
-- ============================================================================
-- Stores city details.
-- city_key = surrogate key
-- city_name = business key from the source system

CREATE TABLE dw.dim_city
(
    city_key INT IDENTITY(1,1) PRIMARY KEY,
    city_name VARCHAR(50) NOT NULL,
    country_key INT NOT NULL,

 -- Foreign key relationships

    FOREIGN KEY (country_key)
        REFERENCES dw.dim_country(country_key)
);


-- ============================================================================
-- NORMILIZED AIRPORT DIMENSION
-- ============================================================================
-- Stores airport details.
-- airport_key = surrogate key
-- airport_code = business key from the source system

CREATE TABLE dw.dim_airport
(
    airport_key INT IDENTITY(1,1) PRIMARY KEY,
    airport_code VARCHAR(3) NOT NULL,
    airport_name VARCHAR(50),
    city_key INT NOT NULL,

      FOREIGN KEY (city_key)
        REFERENCES dw.dim_city(city_key)
);
