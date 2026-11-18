-- 1. Row counts per table
SELECT 'factories' AS table_name, COUNT(*) AS row_count FROM factories
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'zips', COUNT(*) FROM zips
UNION ALL SELECT 'orders_scenarios', COUNT(*) FROM orders_scenarios
UNION ALL SELECT 'sales', COUNT(*) FROM sales
UNION ALL SELECT 'road_distances', COUNT(*) FROM road_distances
UNION ALL SELECT 'cost_formulas', COUNT(*) FROM cost_formulas;

-- 2. Full chain check: sales line -> product -> factory -> route distance
SELECT
    COUNT(*)                         AS sales_lines,
    COUNT(rd.road_miles)             AS lines_with_route,
    ROUND(AVG(rd.road_miles), 0)     AS avg_road_miles
FROM sales s
JOIN products p        ON p.product_id = s.product_id
JOIN road_distances rd ON rd.factory = p.factory AND rd.zip = s.postal_code;

-- 3. Order lines add up to their orders (units, sales, gross profit) – expected: 0 mismatches
SELECT COUNT(*) AS orders_with_mismatch
FROM orders_scenarios o
JOIN (
    SELECT order_no,
           SUM(units)        AS units,
           SUM(sales)        AS sales,
           SUM(gross_profit) AS gross_profit
    FROM sales
    GROUP BY order_no
) s USING (order_no)
WHERE s.units <> o.units
   OR ABS(s.sales - o.sales) > 0.01
   OR ABS(s.gross_profit - o.gross_profit) > 0.01;

-- 4. Scenario totals – should match notebook 04
SELECT 'current' AS scenario,
       SUM(current_parcels)                        AS parcels,
       ROUND(SUM(current_road_miles), 0)           AS road_miles,
       ROUND(SUM(current_cost_usps_commercial), 0) AS cost_usps,
       ROUND(SUM(current_cost_ups_ground), 0)      AS cost_ups
FROM orders_scenarios
UNION ALL
SELECT 'realistic', SUM(realistic_parcels), ROUND(SUM(realistic_road_miles), 0),
       ROUND(SUM(realistic_cost_usps_commercial), 0), ROUND(SUM(realistic_cost_ups_ground), 0)
FROM orders_scenarios
UNION ALL
SELECT 'optimum', SUM(optimum_parcels), ROUND(SUM(optimum_road_miles), 0),
       ROUND(SUM(optimum_cost_usps_commercial), 0), ROUND(SUM(optimum_cost_ups_ground), 0)
FROM orders_scenarios;
-- Results (Nov 2026): row counts match the loaded CSVs (orders_scenarios: 5,009 orders, sales: 9,994 lines);
-- 9,994 / 9,994 sales lines link to a road distance (avg 1,447 mi);
-- 0 orders whose lines do not add up to the order (units, sales, gross profit) → order_no links correctly;
-- scenario totals match notebook 04: parcels 6,825 / 5,239 / 5,009,
-- USPS cost $71,513 / $49,299 / $45,616, UPS cost $104,883 / $76,031 / $71,502.