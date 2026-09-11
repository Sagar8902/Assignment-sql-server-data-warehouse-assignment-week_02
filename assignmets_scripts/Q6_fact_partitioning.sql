/*
================================================================================
QUESTION 6 - FACT TABLE PARTITIONING
================================================================================

  Partition Key: date_key
  Purpose      : Test partition pruning on the FactTicketSales table.
================================================================================
*/


-- ============================================================================
-- CREATE PARTITION FUNCTION
-- ============================================================================
-- Defines date boundaries for the fact table partitions.

CREATE PARTITION FUNCTION pf_ticket_sales_date (INT)
AS RANGE RIGHT FOR VALUES
(
    20240101,
    20250101,
    20260101
);


-- ============================================================================
-- CREATE PARTITION SCHEME
-- ============================================================================
-- Maps all partitions to the PRIMARY filegroup.

CREATE PARTITION SCHEME ps_ticket_sales_date
AS PARTITION pf_ticket_sales_date
ALL TO ([PRIMARY]);


-- ============================================================================
-- TEST 1: FILTER ON PARTITION KEY
-- ============================================================================
-- date_key is the partition key, so SQL Server can eliminate
-- partitions that do not contain the requested date range.
--
-- Check the Actual Execution Plan to verify partition pruning.

SELECT *
FROM dw.fact_ticket_sales
WHERE date_key BETWEEN 20260101 AND 20260131
ORDER BY date_key;


-- ============================================================================
-- TEST 2: FILTER ON NON-PARTITION COLUMN
-- ============================================================================
-- passenger_key is not the partition key, so this filter alone
-- cannot be used to eliminate partitions.
--
-- Check the Actual Execution Plan to verify that partitions
-- are not eliminated based on passenger_key.

SELECT *
FROM dw.fact_ticket_sales
WHERE passenger_key = 100
ORDER BY date_key;


## Partitioning & Execution Plan

[View Execution Plan - Partition Key](docs/execution_plans/WITH_PARTITION_KEY.sqlplan)

[View Execution Plan - Non-Partition Key](docs/execution_plans/WITHOUT_PARTITION_KEY.sqlplan)

[![Before & After Partitioning](docs/screenshots/ACTUAL_EXECUTION_PLAN_PARTITION_KEY.png)](docs/screenshots/ACTUAL_EXECUTION_PLAN_PARTITION_KEY.png)
