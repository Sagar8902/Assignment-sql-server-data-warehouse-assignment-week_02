# Assignment-sql-server-data-warehouse-assignment-week_02

## 📌 Assignment Overview

This Assignment demonstrates an **end-to-end Data Warehouse implementation using Microsoft SQL Server**.

The Assignment takes raw airline booking data through a **Bronze → Silver → Gold** pipeline and builds a reporting-ready dimensional model.

It covers important Data Engineering concepts such as:

- Data Warehouse design
- Star Schema
- Snowflake Schema
- Fact and Dimension tables
- Surrogate Keys
- SCD Type 2
- Additive Measures
- Date Dimension
- Fact Table Partitioning
- Partition Pruning
- Medallion Architecture
- Data Contracts
- Data Validation

---

## 🏗️ Data Warehouse Architecture

```text
                         SOURCE DATA
                             │
                             ▼
                    ┌─────────────────┐
                    │  BRONZE LAYER   │
                    │                 │
                    │ • Bookings      │
                    │ • Passengers    │
                    │ • Flights       │
                    │ • Airports      │
                    │ • Aircraft      │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  SILVER LAYER   │
                    │                 │
                    │ Passenger       │
                    │ Update Staging  │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │   GOLD LAYER    │
                    │                 │
                    │ Dimensions      │
                    │       +         │
                    │ FactTicketSales │
                    └─────────────────┘
```

---

# 🥉 Bronze Layer

The Bronze layer stores the raw source data with minimal transformation.

| Table | Purpose |
|---|---|
| `dbo.bronze_bookings` | Raw booking and ticket-level data |
| `dbo.bronze_passengers` | Raw passenger data |
| `dbo.bronze_flights` | Raw flight data |
| `dbo.bronze_airports` | Raw airport data |
| `dbo.bronze_aircraft` | Raw aircraft data |

---

# 🥈 Silver Layer

The Silver layer contains staged/transformed data used before loading the final analytical model.

| Table | Purpose |
|---|---|
| `dbo.stg_passenger_updates` | Stages passenger changes before applying SCD Type 2 |

---

# 🥇 Gold Layer

The Gold layer contains business-ready dimensional and fact tables used for analytics.

### Dimensions

- `dw.dim_date`
- `dw.dim_passenger`
- `dw.dim_flight`
- `dw.dim_airport`
- `dw.dim_aircraft`
- `dw.dim_city`
- `dw.dim_country`

### Fact

- `dw.fact_ticket_sales`

---

# ⭐ Fact Table Grain

The grain of `dw.fact_ticket_sales` is:

> **One row represents one flight ticket fare associated with a booking, including its booking details, passenger, flight, airport, aircraft, fare amount, tax amount, and miles earned.**

### Measures

The fact table contains these additive measures:

- `fare_amount`
- `tax_amount`
- `miles_earned`

These measures can be summed across fact rows.

---

# ⭐ Star Schema

The central fact table connects to the main dimensions through surrogate keys.

```text
                         dim_date
                            │
                            │
dim_passenger ─────── fact_ticket_sales ─────── dim_flight
                            │
                            │
                     dim_airport
                            │
                            │
                     dim_aircraft
```

The fact table stores surrogate-key foreign keys rather than repeating descriptive dimension attributes.

---

# ❄️ Snowflake Geography

The airport geography was normalized into three linked tables:

```text
dim_airport
     │
     ▼
  dim_city
     │
     ▼
 dim_country
```

This allows an airport to be resolved through its city to its country and region.

### Example

```text
AMD
 ↓
Ahmedabad
 ↓
India
 ↓
South Asia
```

### Trade-off

> Snowflaking reduces data duplication and improves normalization, but requires additional joins and makes queries more complex.

---

# 🔄 Slowly Changing Dimension Type 2

The passenger dimension uses **SCD Type 2** to preserve historical changes.

Tracked attributes:

- `home_airport_code`
- `frequent_flyer_tier`

When a tracked attribute changes:

```text
Old Version
    ↓
Expire old record
    ↓
is_current = 0
effective_to = change date
    ↓
Insert new version
    ↓
is_current = 1
effective_to = NULL
```

### Example

| passenger_key | passenger_id | tier | is_current | effective_from | effective_to |
|---:|---:|---|---:|---|---|
| 1 | 700000 | Blue | 0 | 2024-09-19 | 2026-09-11 |
| 101 | 700000 | Silver | 1 | 2026-09-11 | NULL |

The business key `passenger_id` remains stable while each version receives a new surrogate key.

---

# 🗓️ Date Dimension

The Date dimension uses an integer `date_key` in `YYYYMMDD` format.

Example:

```text
2026-01-03
     ↓
20260103
```

This provides a consistent date key for the fact table and supports date-based analysis and partitioning.

---

# 🚀 Fact Table Partitioning

Because `fact_ticket_sales` is the largest table, it is partitioned using:

```text
Partition Key: date_key
```

The partition function divides the fact table into date ranges.

```text
FactTicketSales
│
├── Partition 1
├── Partition 2
├── Partition 3
└── Partition 4
```

### Partition pruning

A query filtering on the partition key can eliminate irrelevant partitions.

```sql
SELECT *
FROM dw.fact_ticket_sales
WHERE date_key BETWEEN 20260101 AND 20260131;
```

Because `date_key` is the partition key, SQL Server can identify the relevant partition(s).

A query filtering only on a non-partition column cannot use that predicate to eliminate partitions:

```sql
SELECT *
FROM dw.fact_ticket_sales
WHERE passenger_key = 100;
```

---

## 📊 Actual Execution Plan

### Test 1 — Filter on Partition Key

The query uses `date_key`, which is the partition key.

[View Execution Plan - Partition Key](docs/WITH_PARTITION_KEY.png)

### Test 2 — Filter on Non-Partition Column

The query uses `passenger_key`, which is not the partition key.

[View Execution Plan - Non-Partition Key](docs/WITHOUT_PARTITION_KEY.png)

### Execution Plan Screenshot

> **Place your actual execution plan screenshot at:**
>
> `docs/screenshots/actual_execution_plan.png`

[![Actual Execution Plan](docs/ACTUAL_EXECUTION_PLAN (PARTITION_KEY).png)

---

# 📜 Medallion Architecture Mapping

| Layer | Tables |
|---|---|
| 🥉 Bronze | `bronze_bookings`, `bronze_passengers`, `bronze_flights`, `bronze_airports`, `bronze_aircraft` |
| 🥈 Silver | `stg_passenger_updates` |
| 🥇 Gold | `dim_date`, `dim_passenger`, `dim_flight`, `dim_airport`, `dim_aircraft`, `dim_city`, `dim_country`, `fact_ticket_sales` |

---

# 📋 Data Contract — `bronze_bookings`

The `bronze_bookings` feed contains raw booking and ticket-level transaction data.

### Expected Schema

| Column | Expected Type | Description |
|---|---|---|
| `booking_id` | `INT` | Booking business identifier |
| `passenger_id` | Source-defined numeric/string type | Passenger business identifier |
| `flight_id` | Source-defined numeric/string type | Flight business identifier |
| `booking_date` | `DATE` | Date the booking was created |
| `travel_date` | `DATE` | Scheduled travel date |
| `fare_class` | `VARCHAR` | Ticket fare category |
| `fare_amount` | `DECIMAL(18,2)` | Ticket fare amount |
| `tax_amount` | `DECIMAL(18,2)` | Ticket tax amount |
| `booking_status` | `VARCHAR` | Current booking status |
| `miles_earned` | `INT` | Miles earned for the ticket |

> **Note:** The final data contract should match the actual data types defined in `dbo.bronze_bookings`.

### Allowed Values

**`fare_class`**

- `Economy`
- `Business`
- `Premium Economy`

**`booking_status`**

- `Confirmed`
- `Cancelled`

### Freshness / Delivery SLA

The `bronze_bookings` feed is expected to be delivered **daily by 06:00 UTC** for the previous day's booking data.

> This SLA is a Assignment assumption for this assignment.

### Owner

**Business Owner:** Booking / Reservation Source System Team

**Technical Owner:** Data Engineering Team

### Change Management

**Breaking change:** Changing `fare_amount` from `DECIMAL(18,2)` to `VARCHAR(50)` would be a breaking change because downstream transformations expect a numeric value.

**Non-breaking change:** Adding a new nullable column such as `booking_channel` without changing existing columns or their meanings would be a non-breaking change.

---

# 📁 Assignment Structure

```text
sql-server-data-warehouse-Assignment/
│
├── README.md
│
├── docs/
│   
│   
│  
│   ├── execution_plans/
│   │   ├── WITH_PARTITION_KEY.sqlplan
│   │   └── WITHOUT_PARTITION_KEY.sqlplan
│   │
│   └── screenshots/
│       └── actual_execution_plan.png
│
├── scripts/
│   ├── Q01_grain_and_measures.sql
│   ├── Q02_star_schema_ddl.sql
│   ├── Q03_load_dimensions_and_fact.sql
│   ├── Q04_snowflake_geography.sql
│   ├── Q05_scd_type_2_passenger.sql
│   ├── Q06_fact_partitioning.sql
│   └── Q07_medallion_and_data_contract.sql
│
└── datasets/
    └── source_files/
```

---

# 🧪 Validation

The Assignment validates the warehouse using SQL queries to check:

- Dimension records are populated
- Fact records are populated
- Fact row count matches the Bronze booking data
- Fact rows resolve to all required dimensions
- SCD Type 2 current and historical records
- Snowflake geography relationships
- Partitioning and partition pruning
- Allowed booking and fare values

---

# 🛠️ Technologies Used

- **Microsoft SQL Server**
- **SQL Server Management Studio (SSMS)**
- **T-SQL**
- **GitHub**

---

# 🎯 Key Data Engineering Concepts

| Concept | Implementation |
|---|---|
| Medallion Architecture | Bronze → Silver → Gold |
| Dimensional Modeling | Fact + Dimensions |
| Star Schema | `fact_ticket_sales` + dimensions |
| Snowflake Schema | Airport → City → Country |
| Surrogate Keys | Identity-based dimension keys |
| SCD Type 2 | Historical passenger versions |
| Additive Measures | Fare, tax, miles |
| Date Dimension | `YYYYMMDD` integer key |
| Partitioning | Fact partitioned by `date_key` |
| Partition Pruning | Date-based partition elimination |
| Data Contract | `bronze_bookings` feed rules |

---

# 👨‍💻 Assignment Purpose

This Assignment was developed to demonstrate practical **SQL Server Data Engineering and Data Warehousing skills**, including data modeling, ETL/ELT concepts, dimensional design, historical data management, performance optimization, and data governance.

