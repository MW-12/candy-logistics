-- Candy Logistics – database schema
DROP TABLE IF EXISTS orders_scenarios, sales, road_distances, products, zips, factories, cost_formulas CASCADE;

CREATE TABLE factories (
    factory     VARCHAR(50) PRIMARY KEY,
    latitude    NUMERIC(9,6) NOT NULL,
    longitude   NUMERIC(9,6) NOT NULL
);

CREATE TABLE products (
    product_id   VARCHAR(20) PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    division     VARCHAR(20) NOT NULL,
    factory      VARCHAR(50) NOT NULL REFERENCES factories(factory),
    unit_price   NUMERIC(10,2) NOT NULL,
    unit_cost    NUMERIC(10,2) NOT NULL
);

CREATE TABLE zips (
    zip       CHAR(5) PRIMARY KEY,
    lat       NUMERIC(9,6) NOT NULL,
    lng       NUMERIC(9,6) NOT NULL,
    city      VARCHAR(100),
    state_id  CHAR(2)
);

-- One row per order (order_no = first part of order_id); shipping results per scenario
-- (parcel = order × factory; costs from notebook 04, two rate tables)
CREATE TABLE orders_scenarios (
    order_no                        VARCHAR(20) PRIMARY KEY,
    customer_id                     INTEGER NOT NULL,
    postal_code                     CHAR(5) NOT NULL REFERENCES zips(zip),
    order_date                      DATE NOT NULL,
    ship_mode                       VARCHAR(20) NOT NULL,
    units                           INTEGER NOT NULL,
    sales                           NUMERIC(10,2) NOT NULL,
    gross_profit                    NUMERIC(10,2) NOT NULL,
    current_parcels                 SMALLINT NOT NULL,
    current_road_miles              NUMERIC(10,2) NOT NULL,
    current_cost_usps_commercial    NUMERIC(10,4) NOT NULL,
    current_cost_ups_ground         NUMERIC(10,4) NOT NULL,
    realistic_parcels               SMALLINT NOT NULL,
    realistic_road_miles            NUMERIC(10,2) NOT NULL,
    realistic_cost_usps_commercial  NUMERIC(10,4) NOT NULL,
    realistic_cost_ups_ground       NUMERIC(10,4) NOT NULL,
    optimum_parcels                 SMALLINT NOT NULL,
    optimum_road_miles              NUMERIC(10,2) NOT NULL,
    optimum_cost_usps_commercial    NUMERIC(10,4) NOT NULL,
    optimum_cost_ups_ground         NUMERIC(10,4) NOT NULL
);

CREATE TABLE sales (
    row_id          INTEGER PRIMARY KEY,
    order_id        VARCHAR(30) NOT NULL,
    order_no        VARCHAR(20) NOT NULL REFERENCES orders_scenarios(order_no),
    order_date      DATE NOT NULL,
    ship_date       DATE NOT NULL,
    lead_time_days  INTEGER NOT NULL,
    ship_mode       VARCHAR(20) NOT NULL,
    customer_id     INTEGER NOT NULL,
    city            VARCHAR(100),
    state_province  VARCHAR(50),
    postal_code     CHAR(5) NOT NULL REFERENCES zips(zip),
    region          VARCHAR(20),
    product_id      VARCHAR(20) NOT NULL REFERENCES products(product_id),
    sales           NUMERIC(10,2) NOT NULL,
    units           INTEGER NOT NULL,
    gross_profit    NUMERIC(10,2) NOT NULL,
    cost            NUMERIC(10,2) NOT NULL
);

CREATE TABLE road_distances (
    factory     VARCHAR(50) REFERENCES factories(factory),
    zip         CHAR(5) REFERENCES zips(zip),
    road_miles  NUMERIC(8,2) NOT NULL,
    PRIMARY KEY (factory, zip)
);

CREATE TABLE cost_formulas (
    variant        VARCHAR(30) PRIMARY KEY,
    a              NUMERIC(10,6) NOT NULL,
    b              NUMERIC(10,6) NOT NULL,
    c              NUMERIC(12,8) NOT NULL,
    e              NUMERIC(12,8) NOT NULL,
    r2             NUMERIC(6,4),
    max_error_usd  NUMERIC(8,4)
);
