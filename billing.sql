/* ===========================================================
   PROJECT: Billing & Payment Compliance Tracker
   AUTHOR : Dilkhus Kumar Das
   DATABASE: SQL Server
   PURPOSE : Monitor invoice generation, payment term adherence,
             and overdue trends for finance reporting
   =========================================================== */

---------------------------------------------------------------
-- 1?? CREATE DATABASE AND TABLE
---------------------------------------------------------------
IF DB_ID('billing_compliance') IS NULL
    CREATE DATABASE billing_compliance;
GO

USE billing_compliance;
GO

-- Drop table if already exists (for reruns)
IF OBJECT_ID('dbo.billing_data', 'U') IS NOT NULL
    DROP TABLE dbo.billing_data;
GO

CREATE TABLE billing_data (
    Invoice_ID     VARCHAR(15) PRIMARY KEY,
    Client         VARCHAR(100),
    Invoice_Date   DATE,
    Due_Date       DATE,
    Amount         DECIMAL(12,2),
    Payment_Date   DATE NULL,
    Status         VARCHAR(20)
);
GO

---------------------------------------------------------------
-- 2?? VIEW INITIAL DATA (after importing via CSV or INSERTs)
---------------------------------------------------------------
SELECT TOP 10 *
FROM billing_data;
GO

---------------------------------------------------------------
-- 3?? CALCULATE DAYS DELAYED AND PAYMENT STATUS
---------------------------------------------------------------
SELECT
    Invoice_ID,
    Client,
    Invoice_Date,
    Due_Date,
    Amount,
    Payment_Date,
    CASE 
        WHEN Payment_Date IS NULL THEN DATEDIFF(DAY, Due_Date, GETDATE())
        ELSE DATEDIFF(DAY, Due_Date, Payment_Date)
    END AS Days_Delayed,
    CASE
        WHEN Payment_Date IS NULL THEN 'Pending'
        WHEN Payment_Date <= Due_Date THEN 'On Time'
        ELSE 'Late'
    END AS Payment_Status
FROM billing_data
ORDER BY Due_Date;
GO

---------------------------------------------------------------
-- 4?? TOTAL OUTSTANDING AND OVERDUE PAYMENTS
---------------------------------------------------------------
SELECT
    COUNT(*) AS Pending_Invoices,
    SUM(Amount) AS Total_Outstanding
FROM billing_data
WHERE Payment_Date IS NULL OR Payment_Date > Due_Date;
GO

---------------------------------------------------------------
-- 5?? CLIENT-WISE PAYMENT SUMMARY
---------------------------------------------------------------
SELECT
    Client,
    COUNT(Invoice_ID) AS Total_Invoices,
    SUM(Amount) AS Total_Billed,
    SUM(CASE WHEN Payment_Date <= Due_Date THEN Amount ELSE 0 END) AS Paid_On_Time,
    SUM(CASE WHEN Payment_Date > Due_Date THEN Amount ELSE 0 END) AS Paid_Late,
    SUM(CASE WHEN Payment_Date IS NULL THEN Amount ELSE 0 END) AS Pending_Amount
FROM billing_data
GROUP BY Client
ORDER BY Total_Billed DESC;
GO

---------------------------------------------------------------
-- 6?? PAYMENT COMPLIANCE PERCENTAGES
---------------------------------------------------------------
SELECT
    ROUND(
        (SUM(CASE WHEN Payment_Date <= Due_Date THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2
    ) AS On_Time_Payment_Percent,
    ROUND(
        (SUM(CASE WHEN Payment_Date > Due_Date THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2
    ) AS Late_Payment_Percent,
    ROUND(
        (SUM(CASE WHEN Payment_Date IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2
    ) AS Pending_Payment_Percent
FROM billing_data;
GO

---------------------------------------------------------------
-- 7?? IDENTIFY CLIENTS WITH FREQUENT LATE PAYMENTS
---------------------------------------------------------------
SELECT
    Client,
    COUNT(*) AS Total_Invoices,
    SUM(CASE WHEN Payment_Date > Due_Date THEN 1 ELSE 0 END) AS Late_Count,
    ROUND(
        (SUM(CASE WHEN Payment_Date > Due_Date THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2
    ) AS Late_Percent
FROM billing_data
GROUP BY Client
HAVING (SUM(CASE WHEN Payment_Date > Due_Date THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) > 20
ORDER BY Late_Percent DESC;
GO

---------------------------------------------------------------
-- 8?? OVERDUE INVOICES AS OF TODAY
---------------------------------------------------------------
SELECT
    Invoice_ID,
    Client,
    Due_Date,
    Amount,
    DATEDIFF(DAY, Due_Date, GETDATE()) AS Days_Overdue
FROM billing_data
WHERE Payment_Date IS NULL AND Due_Date < GETDATE()
ORDER BY Days_Overdue DESC;
GO

---------------------------------------------------------------
-- ? END OF SCRIPT
---------------------------------------------------------------
