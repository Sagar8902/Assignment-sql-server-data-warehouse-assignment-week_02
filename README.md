# Assignment-sql-server-data-warehouse-assignment-week_02

## 📌 Assignment Overview

This assignment demonstrates an **end-to-end Data Warehouse implementation using Microsoft SQL Server**.

The assignment takes raw airline booking data through a:

**Bronze → Silver → Gold**

pipeline and builds a reporting-ready dimensional data warehouse.

It covers important Data Engineering concepts such as:

- Data Warehouse Design
- Dimensional Modeling
- Star Schema
- Snowflake Schema
- Fact and Dimension Tables
- Fact Table Grain
- Surrogate Keys
- Slowly Changing Dimension Type 2
- Additive Measures
- Date Dimension
- ETL / Data Loading
- Fact Table Partitioning
- Partition Elimination
- Medallion Architecture
- Data Contracts
- Data Quality Validation
- SQL Server Execution Plans

---

# 🏗️ Data Warehouse Architecture

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
                    │ • Passenger     │
                    │   Update        │
                    │   Staging       │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │   GOLD LAYER    │
                    │                 │
                    │ • Dimensions    │
                    │ • Fact Table    │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │   ANALYTICS     │
                    │  & REPORTING    │
                    └─────────────────┘
