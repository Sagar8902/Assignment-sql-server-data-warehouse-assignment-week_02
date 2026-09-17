
/*
================================================================================
QUESTION 1 - SALES FACT GRAIN AND COLUMN CLASSIFICATION
================================================================================

GRAIN:
One row represents one flight ticket/fare for a booking,
including the fare amount, tax amount, and miles earned.

--------------------------------------------------------------------------------
DIMENSION KEYS / DESCRIPTIVE ATTRIBUTES:
--------------------------------------------------------------------------------

From booking:
- booking.booking_id
- booking.passenger_id
- booking.flight_id
- booking.booking_date
- booking.travel_date
- booking.fare_class
- booking.booking_status

From flight:
- flight.flight_number
- flight.origin_airport_code
- flight.dest_airport_code
- flight.aircraft_code
- flight.flight_date

These attributes describe the booking, passenger, flight,
route, travel date, fare class, and booking status associated
with each fact row.

--------------------------------------------------------------------------------
MEASURES:
--------------------------------------------------------------------------------

- booking.fare_amount
- booking.tax_amount
- booking.miles_earned

--------------------------------------------------------------------------------
ADDITIVE VS NON-ADDITIVE:
--------------------------------------------------------------------------------

ADDITIVE:
- fare_amount
- tax_amount
- miles_earned

These measures can be summed across fact rows at the defined grain.

NON-ADDITIVE:
- Average fare is non-additive because averages should not be
  summed across fact rows.

================================================================================
*/


SELECT * FROM dbo.bronze_bookings;

SELECT *
FROM dbo.bronze_bookings AS booking
LEFT JOIN dbo.bronze_flights AS flight
ON booking.flight_id = flight.flight_id
