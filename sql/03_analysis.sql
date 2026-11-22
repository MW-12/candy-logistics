-- =====================================================================
-- Candy Logistics – SQL analysis (cost model v2)
-- Parcel = order × factory; customer pays a flat delivery fee per order
-- (= average shipping cost per order in the current model).
-- Margin after delivery = gross profit + fee − carrier cost.
-- Base rate table: USPS Ground Advantage commercial; UPS Ground as a check.
-- Yearly values = 4 years of data (2021–2024) / 4.
-- =====================================================================

-- ---------------------------------------------------------------------
-- View: one row per order and scenario (long format, ready for Power BI)
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_order_scenarios AS
WITH fees AS (
    SELECT AVG(current_cost_usps_commercial) AS fee_usps,
           AVG(current_cost_ups_ground)      AS fee_ups
    FROM orders_scenarios
),
long AS (
    SELECT order_no, 'current' AS scenario, current_parcels AS parcels, current_road_miles AS road_miles,
           current_cost_usps_commercial AS cost_usps, current_cost_ups_ground AS cost_ups
    FROM orders_scenarios
    UNION ALL
    SELECT order_no, 'realistic', realistic_parcels, realistic_road_miles,
           realistic_cost_usps_commercial, realistic_cost_ups_ground
    FROM orders_scenarios
    UNION ALL
    SELECT order_no, 'optimum', optimum_parcels, optimum_road_miles,
           optimum_cost_usps_commercial, optimum_cost_ups_ground
    FROM orders_scenarios
)
SELECT o.order_no, o.customer_id, o.postal_code, z.city, z.state_id, o.order_date, o.ship_mode,
       o.units, o.sales, o.gross_profit,
       l.scenario, l.parcels, l.road_miles,
       l.cost_usps, l.cost_ups, f.fee_usps, f.fee_ups,
       f.fee_usps - l.cost_usps                  AS delivery_result_usps,
       f.fee_ups  - l.cost_ups                   AS delivery_result_ups,
       o.gross_profit + f.fee_usps - l.cost_usps AS margin_after_delivery_usps,
       o.gross_profit + f.fee_ups  - l.cost_ups  AS margin_after_delivery_ups
FROM long l
JOIN orders_scenarios o USING (order_no)
JOIN zips z ON z.zip = o.postal_code
CROSS JOIN fees f;

-- Check: 3 scenarios × 5,009 orders = 15,027 rows
SELECT scenario, COUNT(*) AS orders FROM v_order_scenarios GROUP BY scenario ORDER BY scenario;


-- =====================================================================
-- Q1. Margin after delivery and savings by scenario (both rate tables)
-- =====================================================================
WITH s AS (
    SELECT scenario,
           SUM(parcels)                                          AS parcels,
           SUM(road_miles)                                       AS road_miles,
           SUM(cost_usps) / 4                                    AS cost_usps_per_year,
           SUM(cost_ups) / 4                                     AS cost_ups_per_year,
           SUM(margin_after_delivery_usps) / SUM(sales + fee_usps) * 100 AS margin_pct_usps,
           SUM(margin_after_delivery_ups)  / SUM(sales + fee_ups)  * 100 AS margin_pct_ups,
           SUM(gross_profit) / 4                                 AS gross_profit_per_year
    FROM v_order_scenarios
    GROUP BY scenario
)
SELECT s.scenario,
       s.parcels,
       ROUND(s.road_miles)                                        AS road_miles,
       ROUND(s.margin_pct_usps, 1)                                AS margin_after_delivery_pct_usps,
       ROUND(s.margin_pct_ups, 1)                                 AS margin_after_delivery_pct_ups,
       ROUND(c.cost_usps_per_year - s.cost_usps_per_year)         AS saving_per_year_usps,
       ROUND(c.cost_ups_per_year  - s.cost_ups_per_year)          AS saving_per_year_ups,
       ROUND((c.cost_usps_per_year - s.cost_usps_per_year) / s.gross_profit_per_year * 100, 1) AS saving_pct_of_gross_profit_usps
FROM s
CROSS JOIN (SELECT * FROM s WHERE scenario = 'current') c
ORDER BY saving_per_year_usps;
-- Findings: current margin after delivery 43.5% (USPS) / 37.5% (UPS). Realistic: 54.1% / 49.4%,
-- parcels 6,825 → 5,239, road miles −59%, saving $5,553 per year (+24.3% of gross profit) with USPS, $7,213 with UPS.
-- Optimum adds only ~$900 per year more (ceiling $6,474) → realistic captures ~86% of the theoretical potential.


-- =====================================================================
-- Q2. Where does the company lose money on delivery? (current model, USPS)
-- =====================================================================
SELECT CASE WHEN parcels >= 3 THEN '3+' ELSE parcels::text END             AS parcels_per_order,
       COUNT(*)                                                             AS orders,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1)                   AS orders_pct,
       ROUND(AVG(sales), 2)                                                 AS avg_sales,
       ROUND(AVG(cost_usps), 2)                                             AS avg_shipping_cost,
       ROUND(AVG(delivery_result_usps), 2)                                  AS avg_delivery_result,
       ROUND(SUM(delivery_result_usps) / 4)                                 AS delivery_result_per_year,
       ROUND(SUM(margin_after_delivery_usps) / SUM(sales + fee_usps) * 100, 1) AS margin_after_delivery_pct
FROM v_order_scenarios
WHERE scenario = 'current'
GROUP BY 1
ORDER BY 1;
-- Findings: split shipments are the loss driver. One third of orders ship as 2+ parcels for one fee and lose
-- $3,211 per year on delivery (margin after delivery 38.2% / 31.3% vs 49.3% for single-parcel orders);
-- single-parcel orders earn exactly that amount back. Distance alone rarely makes delivery unprofitable (notebook 06).


-- =====================================================================
-- Q3. Product lines: gross margin and share of gross profit
-- (margin after delivery per product needs parcel-level allocation → notebook 06)
-- =====================================================================
SELECT p.division,
       p.product_name,
       p.factory,
       SUM(s.units)                                                         AS units,
       ROUND(SUM(s.sales) / 4)                                              AS sales_per_year,
       ROUND(SUM(s.gross_profit) / 4)                                       AS gross_profit_per_year,
       ROUND(SUM(s.gross_profit) / SUM(s.sales) * 100, 1)                   AS gross_margin_pct,
       ROUND(SUM(s.gross_profit) * 100 / SUM(SUM(s.gross_profit)) OVER (), 1) AS share_of_gross_profit_pct
FROM sales s
JOIN products p USING (product_id)
GROUP BY p.division, p.product_name, p.factory
ORDER BY gross_profit_per_year DESC;
-- Findings: the five chocolate bars bring ~95% of gross profit (gross margins 65–71%).
-- Kazookles has the weakest gross margin (7.7%: price $3.25 vs cost $3.00) → a pricing issue.
-- After delivery (notebook 06) the two Wicked Choccy's bars are the weakest bars (Milk Chocolate 39.9%, Triple Dazzle 42.8%).


-- =====================================================================
-- Q4. Where is the saving? Realistic vs current by customer state (USPS)
-- =====================================================================
WITH by_state AS (
    SELECT state_id,
           COUNT(*) FILTER (WHERE scenario = 'current')                     AS orders,
           SUM(cost_usps) FILTER (WHERE scenario = 'current')   / 4         AS cost_now_per_year,
           SUM(cost_usps) FILTER (WHERE scenario = 'realistic') / 4         AS cost_realistic_per_year
    FROM v_order_scenarios
    GROUP BY state_id
)
SELECT state_id,
       orders,
       ROUND(cost_now_per_year - cost_realistic_per_year)                   AS saving_per_year,
       ROUND((cost_now_per_year - cost_realistic_per_year) * 100
             / SUM(cost_now_per_year - cost_realistic_per_year) OVER (), 1) AS share_of_total_saving_pct
FROM by_state
ORDER BY saving_per_year DESC
LIMIT 10;
-- Findings: California alone gives $1,196 per year (22% of the realistic saving) – mostly chocolate shipped
-- from Georgia although the other chocolate factory is in neighbouring Arizona. The top 8 states give 66% of the saving;
-- western states together ~$1,900 per year → a pilot "the West served entirely from Arizona" captures about a third of the potential.
