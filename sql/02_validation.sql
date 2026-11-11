-- 1. Row counts per table
SELECT 'factories' AS table_name, COUNT(*) AS row_count FROM factories
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'zips', COUNT(*) FROM zips
UNION ALL SELECT 'sales', COUNT(*) FROM sales
UNION ALL SELECT 'road_distances', COUNT(*) FROM road_distances
UNION ALL SELECT 'cost_formulas', COUNT(*) FROM cost_formulas
UNION ALL SELECT 'orders_scenarios', COUNT(*) FROM orders_scenarios;

-- 2. Full chain check: sales line -> product -> factory -> route distance
SELECT
    COUNT(*)                         AS sales_lines,
    COUNT(rd.road_miles)             AS lines_with_route,
    ROUND(AVG(rd.road_miles), 0)     AS avg_road_miles
FROM sales s
JOIN products p        ON p.product_id = s.product_id
JOIN road_distances rd ON rd.factory = p.factory AND rd.zip = s.postal_code;

-- 3. Consistency with Python: total sales in the database vs. orders table
SELECT
    (SELECT SUM(sales) FROM sales)            AS sales_table_total,
    (SELECT ROUND(SUM(sales)::numeric, 2) FROM orders_scenarios) AS orders_table_total;
-- Results (Nov 2026): all row counts match the loaded CSVs;
-- 9,994 / 9,994 sales lines link to a road distance (avg 1,447 mi);
-- sales totals match between sales and orders_scenarios ($138,830.34)