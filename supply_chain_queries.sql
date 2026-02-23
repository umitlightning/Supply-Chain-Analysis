-- ============================================================
-- Supply Chain Delivery Analysis – MySQL Queries
-- Dataset: SCMS Delivery History
-- ============================================================

-- ── Table Setup ──────────────────────────────────────────────
CREATE DATABASE IF NOT EXISTS supply_chain;
USE supply_chain;

CREATE TABLE IF NOT EXISTS deliveries (
    id                          INT PRIMARY KEY,
    project_code                VARCHAR(50),
    country                     VARCHAR(100),
    managed_by                  VARCHAR(100),
    fulfill_via                 VARCHAR(50),
    vendor_inco_term            VARCHAR(50),
    shipment_mode               VARCHAR(50),
    scheduled_delivery_date     DATE,
    delivered_to_client_date    DATE,
    delivery_recorded_date      DATE,
    product_group               VARCHAR(100),
    sub_classification          VARCHAR(100),
    vendor                      VARCHAR(200),
    item_description            VARCHAR(500),
    line_item_quantity          INT,
    line_item_value             DECIMAL(15,2),
    pack_price                  DECIMAL(10,4),
    unit_price                  DECIMAL(10,4),
    weight_kg                   DECIMAL(10,2),
    freight_cost_usd            DECIMAL(15,2),
    line_item_insurance_usd     DECIMAL(15,2)
);

-- ── 1. Overall Delivery Performance ──────────────────────────
SELECT
    COUNT(*)                                              AS total_shipments,
    SUM(delivered_to_client_date > scheduled_delivery_date) AS delayed,
    SUM(delivered_to_client_date <= scheduled_delivery_date) AS on_time,
    ROUND(
        100.0 * SUM(delivered_to_client_date > scheduled_delivery_date) / COUNT(*), 2
    )                                                     AS delay_rate_pct
FROM deliveries
WHERE delivered_to_client_date IS NOT NULL
  AND scheduled_delivery_date  IS NOT NULL;

-- ── 2. Delay Analysis by Shipment Mode ───────────────────────
SELECT
    shipment_mode,
    COUNT(*)                                                               AS shipments,
    ROUND(AVG(DATEDIFF(delivered_to_client_date, scheduled_delivery_date)), 1) AS avg_delay_days,
    ROUND(AVG(freight_cost_usd), 2)                                        AS avg_freight_usd,
    SUM(delivered_to_client_date > scheduled_delivery_date)                AS delayed_count,
    ROUND(
        100.0 * SUM(delivered_to_client_date > scheduled_delivery_date) / COUNT(*), 2
    )                                                                      AS delay_rate_pct
FROM deliveries
WHERE delivered_to_client_date IS NOT NULL
  AND scheduled_delivery_date  IS NOT NULL
GROUP BY shipment_mode
ORDER BY delay_rate_pct DESC;

-- ── 3. Top 10 Countries by Shipment Volume & Delay Rate ──────
SELECT
    country,
    COUNT(*)                                                               AS total_shipments,
    ROUND(AVG(DATEDIFF(delivered_to_client_date, scheduled_delivery_date)), 1) AS avg_delay_days,
    ROUND(AVG(freight_cost_usd), 2)                                        AS avg_freight_usd,
    ROUND(
        100.0 * SUM(delivered_to_client_date > scheduled_delivery_date) / COUNT(*), 2
    )                                                                      AS delay_rate_pct
FROM deliveries
WHERE delivered_to_client_date IS NOT NULL
GROUP BY country
ORDER BY total_shipments DESC
LIMIT 10;

-- ── 4. Vendor Performance – Top 15 by Shipment Count ─────────
SELECT
    vendor,
    COUNT(*)                                                               AS shipments,
    ROUND(AVG(DATEDIFF(delivered_to_client_date, scheduled_delivery_date)), 1) AS avg_delay_days,
    ROUND(AVG(freight_cost_usd), 2)                                        AS avg_freight_usd,
    ROUND(
        100.0 * SUM(delivered_to_client_date > scheduled_delivery_date) / COUNT(*), 2
    )                                                                      AS delay_rate_pct
FROM deliveries
WHERE delivered_to_client_date IS NOT NULL
  AND freight_cost_usd IS NOT NULL
GROUP BY vendor
HAVING shipments >= 30
ORDER BY delay_rate_pct ASC
LIMIT 15;

-- ── 5. Monthly Shipment Trend ─────────────────────────────────
SELECT
    DATE_FORMAT(scheduled_delivery_date, '%Y-%m') AS year_month,
    COUNT(*)                                       AS scheduled,
    SUM(delivered_to_client_date IS NOT NULL)      AS delivered,
    ROUND(AVG(freight_cost_usd), 2)                AS avg_freight_usd
FROM deliveries
WHERE scheduled_delivery_date IS NOT NULL
GROUP BY year_month
ORDER BY year_month;

-- ── 6. Product Group Breakdown ───────────────────────────────
SELECT
    product_group,
    COUNT(*)                                                               AS shipments,
    ROUND(SUM(line_item_value), 2)                                         AS total_value_usd,
    ROUND(AVG(line_item_value), 2)                                         AS avg_value_usd,
    ROUND(
        100.0 * SUM(delivered_to_client_date > scheduled_delivery_date) / COUNT(*), 2
    )                                                                      AS delay_rate_pct
FROM deliveries
WHERE delivered_to_client_date IS NOT NULL
GROUP BY product_group
ORDER BY total_value_usd DESC;

-- ── 7. Freight Cost vs. Weight Bucket ────────────────────────
SELECT
    CASE
        WHEN weight_kg < 100   THEN '< 100 kg'
        WHEN weight_kg < 500   THEN '100 – 500 kg'
        WHEN weight_kg < 2000  THEN '500 – 2000 kg'
        ELSE '> 2000 kg'
    END                            AS weight_bucket,
    COUNT(*)                       AS shipments,
    ROUND(AVG(freight_cost_usd), 2) AS avg_freight_usd,
    ROUND(AVG(weight_kg), 1)        AS avg_weight_kg
FROM deliveries
WHERE weight_kg IS NOT NULL
  AND freight_cost_usd IS NOT NULL
GROUP BY weight_bucket
ORDER BY avg_weight_kg;

-- ── 8. Delayed Shipments Costing the Most (Top 20) ───────────
SELECT
    id,
    country,
    shipment_mode,
    vendor,
    DATEDIFF(delivered_to_client_date, scheduled_delivery_date) AS delay_days,
    freight_cost_usd,
    line_item_value
FROM deliveries
WHERE delivered_to_client_date > scheduled_delivery_date
  AND freight_cost_usd IS NOT NULL
ORDER BY freight_cost_usd DESC
LIMIT 20;

-- ── 9. Incoterm Impact on Delay ───────────────────────────────
SELECT
    vendor_inco_term,
    COUNT(*)                                                               AS shipments,
    ROUND(AVG(DATEDIFF(delivered_to_client_date, scheduled_delivery_date)), 1) AS avg_delay_days,
    ROUND(
        100.0 * SUM(delivered_to_client_date > scheduled_delivery_date) / COUNT(*), 2
    )                                                                      AS delay_rate_pct
FROM deliveries
WHERE delivered_to_client_date IS NOT NULL
GROUP BY vendor_inco_term
ORDER BY delay_rate_pct DESC;

-- ── 10. Fulfillment Channel Comparison ───────────────────────
SELECT
    fulfill_via,
    COUNT(*)                                                               AS shipments,
    ROUND(AVG(DATEDIFF(delivered_to_client_date, scheduled_delivery_date)), 1) AS avg_delay_days,
    ROUND(AVG(freight_cost_usd), 2)                                        AS avg_freight_usd,
    ROUND(
        100.0 * SUM(delivered_to_client_date > scheduled_delivery_date) / COUNT(*), 2
    )                                                                      AS delay_rate_pct
FROM deliveries
WHERE delivered_to_client_date IS NOT NULL
GROUP BY fulfill_via
ORDER BY shipments DESC;
