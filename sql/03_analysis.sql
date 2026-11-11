-- =====================================================
-- View: one row per order and scenario (long format)
-- =====================================================
CREATE OR REPLACE VIEW v_order_scenarios AS
SELECT order_id, postal_code, units, sales, billable_lb,
       'current' AS scenario, current_factory AS factory,
       current_road_miles AS road_miles, current_straight_miles AS straight_miles,
       cost_current_low_usps_commercial AS cost_low,
       cost_current_base_usps_retail    AS cost_base,
       cost_current_high_ups_ground     AS cost_high
FROM orders_scenarios
UNION ALL
SELECT order_id, postal_code, units, sales, billable_lb,
       'realistic', realistic_factory,
       realistic_road_miles, realistic_straight_miles,
       cost_realistic_low_usps_commercial,
       cost_realistic_base_usps_retail,
       cost_realistic_high_ups_ground
FROM orders_scenarios
UNION ALL
SELECT order_id, postal_code, units, sales, billable_lb,
       'optimum', optimum_factory,
       optimum_road_miles, optimum_straight_miles,
       cost_optimum_low_usps_commercial,
       cost_optimum_base_usps_retail,
       cost_optimum_high_ups_ground
FROM orders_scenarios;

-- Check: totals per scenario should match notebook 04
SELECT scenario,
       COUNT(*)                     AS parcels,
       ROUND(SUM(road_miles)::numeric, 0) AS total_road_miles,
       ROUND(SUM(cost_base)::numeric, 0)  AS total_cost_base
FROM v_order_scenarios
GROUP BY scenario
ORDER BY total_road_miles DESC;
-- =====================================================
-- Q1. Current shipping cost – by factory, region and product (base price variant)
-- =====================================================

-- Q1a. By factory
SELECT factory,
       COUNT(*)                                          AS parcels,
       ROUND(SUM(sales)::numeric, 0)                     AS sales_usd,
       ROUND(AVG(road_miles)::numeric, 0)                AS avg_road_miles,
       ROUND(SUM(cost_base)::numeric, 0)                 AS shipping_cost_usd,
       ROUND((SUM(cost_base) / SUM(sales) * 100)::numeric, 1) AS cost_pct_of_sales
FROM v_order_scenarios
WHERE scenario = 'current'
GROUP BY factory
ORDER BY shipping_cost_usd DESC;

-- Q1b. By customer region
WITH order_region AS (
    SELECT DISTINCT order_id, region
    FROM sales
)
SELECT r.region,
       COUNT(*)                                          AS parcels,
       ROUND(SUM(v.sales)::numeric, 0)                   AS sales_usd,
       ROUND(AVG(v.road_miles)::numeric, 0)              AS avg_road_miles,
       ROUND(SUM(v.cost_base)::numeric, 0)               AS shipping_cost_usd,
       ROUND((SUM(v.cost_base) / SUM(v.sales) * 100)::numeric, 1) AS cost_pct_of_sales
FROM v_order_scenarios v
JOIN order_region r ON r.order_id = v.order_id
WHERE v.scenario = 'current'
GROUP BY r.region
ORDER BY shipping_cost_usd DESC;

-- Q1c. By product (parcel cost allocated to order lines by share of units)
WITH line_share AS (
    SELECT order_id, product_id, units, sales,
           units::numeric / SUM(units) OVER (PARTITION BY order_id) AS unit_share
    FROM sales
)
SELECT p.product_name, p.division, p.factory,
       SUM(l.units)                                                   AS units,
       ROUND(SUM(l.sales), 0)                                         AS sales_usd,
       ROUND(SUM(l.unit_share * v.cost_base::numeric), 0)             AS shipping_cost_usd,
       ROUND(SUM(l.unit_share * v.cost_base::numeric) / SUM(l.sales) * 100, 1) AS cost_pct_of_sales
FROM line_share l
JOIN v_order_scenarios v ON v.order_id = l.order_id AND v.scenario = 'current'
JOIN products p          ON p.product_id = l.product_id
GROUP BY p.product_name, p.division, p.factory
ORDER BY shipping_cost_usd DESC;
-- Q1 findings (base price variant):
-- * The two chocolate factories generate ~96% of shipping costs (~$108.7k of $113.0k);
--   Lot's O' Nuts has the longest routes (avg 1,544 mi), Wicked Choccy's 1,341 mi
-- * Shipping consumes 83–85% of sales at the chocolate factories
-- * Cost as % of sales is driven mainly by product price, not distance:
--   low-price items (Nerds, Fun Dip, Wonka Gum) 240–330%, high-price items
--   (Lickable Wallpaper, Everlasting Gobstopper) 15–28%, chocolate bars 78–88%
-- * Sugar Shack and most Sugar products have very small volumes → less reliable percentages
-- * Check: product-level costs sum to the factory total (~$113.0k) → allocation is consistent
-- Q1b findings: Atlantic has the longest routes (avg 1,674 mi) and the highest cost share (84.5%)
-- although Wicked Choccy's is in Georgia – 3 of 5 chocolate bars are made in Arizona (Lot's O' Nuts)
-- and cross the whole country. Pacific mirrors this (Georgia bars shipped west).
-- Cost share differs only slightly between regions (80–84.5%) → the fixed per-parcel fee dominates.
-- =====================================================
-- Q2. Savings by scenario and price variant (vs. current model)
-- =====================================================
WITH totals AS (
    SELECT scenario,
           SUM(road_miles) AS road_miles,
           SUM(cost_low)   AS cost_low,
           SUM(cost_base)  AS cost_base,
           SUM(cost_high)  AS cost_high
    FROM v_order_scenarios
    GROUP BY scenario
),
current_model AS (
    SELECT * FROM totals WHERE scenario = 'current'
)
SELECT t.scenario,
       ROUND(t.road_miles::numeric, 0)                                AS total_road_miles,
       ROUND((100 * (1 - t.road_miles / c.road_miles))::numeric, 1)   AS miles_saved_pct,
       ROUND((c.cost_low  - t.cost_low)::numeric, 0)                  AS saved_low_usd,
       ROUND((100 * (1 - t.cost_low  / c.cost_low))::numeric, 1)      AS saved_low_pct,
       ROUND((c.cost_base - t.cost_base)::numeric, 0)                 AS saved_base_usd,
       ROUND((100 * (1 - t.cost_base / c.cost_base))::numeric, 1)     AS saved_base_pct,
       ROUND((c.cost_high - t.cost_high)::numeric, 0)                 AS saved_high_usd,
       ROUND((100 * (1 - t.cost_high / c.cost_high))::numeric, 1)     AS saved_high_pct
FROM totals t
CROSS JOIN current_model c
ORDER BY t.road_miles DESC;

-- Q2b. Which orders move in the realistic scenario?
SELECT current_factory,
       realistic_factory,
       COUNT(*)                                                       AS parcels,
       ROUND(AVG(current_road_miles - realistic_road_miles)::numeric, 0) AS avg_miles_saved
FROM orders_scenarios
WHERE current_factory <> realistic_factory
GROUP BY current_factory, realistic_factory
ORDER BY parcels DESC;
-- Q2 findings: realistic scenario cuts road miles by 47.5% and shipping costs by 6.8–12.0%
-- ($8.7k–12.9k over 4 years of data, ~$2.2k–3.2k per year – illustrative);
-- optimum: −59.4% miles, −8.4–14.9% cost. Results match notebook 04.
-- Q2b findings: 96% of reassigned parcels (4,222 of 4,412) are swaps between the two chocolate factories:
-- 3,008 parcels move Lot's O' Nuts → Wicked Choccy's (avg −1,230 mi), 1,214 the other way (avg −1,645 mi).
-- Implication: both factories would need to make all five bars; Wicked Choccy's volume would grow ~53%
-- (3,380 → ~5,174 parcels) and Lot's O' Nuts would drop ~38% → production capacity must be verified first.
-- =====================================================
-- Q3. Routes (factory → customer state) with the highest shipping cost relative to sales
-- =====================================================
SELECT v.factory,
       z.state_id                                                AS customer_state,
       COUNT(*)                                                  AS parcels,
       ROUND(AVG(v.road_miles)::numeric, 0)                      AS avg_road_miles,
       ROUND(SUM(v.sales)::numeric, 0)                           AS sales_usd,
       ROUND(SUM(v.cost_base)::numeric, 0)                       AS shipping_cost_usd,
       ROUND((SUM(v.cost_base) / SUM(v.sales) * 100)::numeric, 1) AS cost_pct_of_sales
FROM v_order_scenarios v
JOIN zips z ON z.zip = v.postal_code
WHERE v.scenario = 'current'
GROUP BY v.factory, z.state_id
HAVING COUNT(*) >= 50
ORDER BY cost_pct_of_sales DESC
LIMIT 10;
-- Q3 findings: all top 10 routes are chocolate shipped coast to coast –
-- Wicked Choccy's (Georgia) → WA, CA, AZ and Lot's O' Nuts (Arizona) → NJ, FL, NY, PA, MA, VA, OH.
-- On WA and NJ routes shipping cost exceeds sales (>100%).
-- Largest by value: Wicked → CA (689 parcels, ~$11.1k) and Lot's → NY (544 parcels, ~$8.6k) → quick wins.
-- Wicked Choccy's ships 88 parcels to Arizona, the state where the other chocolate factory is located.
-- =====================================================
-- Q4. Ship modes: lead time and distance (current vs. realistic)
-- Note: the cost model prices ground shipping only, so express modes are not costed separately.
-- =====================================================
WITH order_mode AS (
    SELECT order_id,
           MIN(ship_mode)      AS ship_mode,
           MAX(lead_time_days) AS lead_time_days
    FROM sales
    GROUP BY order_id
)
SELECT o.ship_mode,
       COUNT(*)                                                   AS parcels,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)         AS share_pct,
       ROUND(AVG(o.lead_time_days), 1)                            AS avg_lead_days,
       ROUND(AVG(os.current_road_miles)::numeric, 0)              AS avg_miles_current,
       ROUND(AVG(os.realistic_road_miles)::numeric, 0)            AS avg_miles_realistic
FROM order_mode o
JOIN orders_scenarios os ON os.order_id = o.order_id
GROUP BY o.ship_mode
ORDER BY avg_lead_days;
-- Q4 findings: Standard Class is 59.9% of parcels, Second 19.3%, First 15.5%, Same Day 5.2%;
-- lead times follow ship mode (0 / 2.2 / 3.2 / 5.0 days).
-- Average distance is almost identical across modes (~1,410–1,450 mi) → ship mode does not depend on distance.
-- The realistic scenario halves distance for every mode (~750–770 mi).
-- Same Day parcels currently travel ~1,400 mi on average, which in practice requires air freight –
-- costs not covered by the ground-based cost model, so real express costs (and potential savings) are likely higher.
