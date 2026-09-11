
/*
================================================================================
QUESTION 1 - SALES FACT GRAIN AND COLUMN CLASSIFICATION
================================================================================

GRAIN:
One row represents one flight ticket/fare for a booking,
including the fare amount and tax amount.

DIMENSION KEYS / DESCRIPTIVE COLUMNS:
- booking.booking_id
- booking.passenger_id
- booking.flight_id
- booking.booking_date
- booking.travel_date
- booking.fare_class
- booking.booking_status
- flight.flight_number
- flight.origin_airport_code
- flight.dest_airport_code
- flight.aircaft_code
- flight.flight_date

MEASURES:
- booking.fare_amount
- booking.tax_amount
- booking.miles_earned


ADDITIVE VS NON-ADDITIVE:
ADDITIVE - fare_amount, tax_amount, and miles_earned are additive measures
because their values can be summed across fact rows.

NON-ADDITIVE - An average fare is non-additive because average values
should not be summed across fact rows.
================================================================================
*/


SELECT * FROM dbo.bronze_bookings;

SELECT *
FROM dbo.bronze_bookings AS booking
LEFT JOIN dbo.bronze_flights AS flight
ON booking.flight_id = flight.flight_id

