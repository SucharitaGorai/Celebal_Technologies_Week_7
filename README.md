# 📊 Slowly Changing Dimensions (SCD) – SQL Server Stored Procedures

This repository provides SQL Server stored procedures to implement various types of Slowly Changing Dimensions (SCD). These are commonly used in data warehousing to track and manage changes in dimension attributes over time.

---

## 📘 Overview of SCD Types

| SCD Type | Description                                                                 |
|----------|-----------------------------------------------------------------------------|
| 0        | **Fixed** – No changes allowed after insert                                |
| 1        | **Overwrite** – Updates the record in place (no history)                   |
| 2        | **Full History** – Inserts a new row and tracks history                    |
| 3        | **Limited History** – Stores only the previous value in extra column       |
| 4        | **History Table** – Moves old records to a separate history table          |
| 6        | **Hybrid (1+2+3)** – Combines overwrite, full and limited history          |

---

## 🏗️ Table Structure Requirements

### Main Table: `DimCustomer`

```sql
CREATE TABLE DimCustomer (
    CustomerCode VARCHAR(50) PRIMARY KEY,
    Name VARCHAR(100),
    Email VARCHAR(100),
    PreviousEmail VARCHAR(100),     -- Used in Type 3 and Type 6
    StartDate DATETIME,             -- Used in Type 2 and Type 6
    EndDate DATETIME,
    IsCurrent BIT                   -- Used in Type 2 and Type 6
);
