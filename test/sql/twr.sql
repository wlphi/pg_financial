\set QUIET 1
-- Adjust precision settings for consistent test output
SET extra_float_digits = 0;

-- Create a temporary table for test data
CREATE TEMP TABLE test_twr (
    asset_id TEXT,
    flow_date TIMESTAMPTZ,
    market_value FLOAT8
);

-- Insert test cases
INSERT INTO test_twr VALUES
    ('A', '2023-01-01', 1000.0),
    ('A', '2023-06-01', 1200.0),
    ('A', '2023-12-31', 1500.0);

-- Test basic TWR calculation with appreciation
SELECT round(twr(market_value, flow_date)::numeric, 4) AS appreciation_test
FROM test_twr
GROUP BY asset_id;

-- Reset table and insert depreciation case
TRUNCATE test_twr;
INSERT INTO test_twr VALUES
    ('B', '2023-01-01', 1000.0),
    ('B', '2023-06-01', 900.0),
    ('B', '2023-12-31', 800.0);

-- Test TWR with depreciation
SELECT round(twr(market_value, flow_date)::numeric, 4) AS depreciation_test
FROM test_twr
GROUP BY asset_id;

-- Reset table and insert no-change case
TRUNCATE test_twr;
INSERT INTO test_twr VALUES
    ('C', '2023-01-01', 1000.0),
    ('C', '2023-06-01', 1000.0),
    ('C', '2023-12-31', 1000.0);

-- Test TWR with no value change
SELECT round(twr(market_value, flow_date)::numeric, 4) AS no_change_test
FROM test_twr
GROUP BY asset_id;

-- Reset table and insert large fluctuations
TRUNCATE test_twr;
INSERT INTO test_twr VALUES
    ('D', '2023-01-01', 1000.0),
    ('D', '2023-06-01', 5000.0),
    ('D', '2023-12-31', 2500.0);

-- Test TWR with large fluctuations
SELECT round(twr(market_value, flow_date)::numeric, 4) AS volatility_test
FROM test_twr
GROUP BY asset_id;

-- Reset table and insert single-point test (expect NULL)
TRUNCATE test_twr;
INSERT INTO test_twr VALUES
    ('E', '2023-01-01', 1000.0);

-- Test single data point (expect NULL)
SELECT twr(market_value, flow_date) AS single_point_test
FROM test_twr
GROUP BY asset_id;

-- Error case tests
\set ON_ERROR_STOP 0

-- Test NULL inputs
SELECT twr(NULL, flow_date) AS null_values_test
FROM test_twr
GROUP BY asset_id;

SELECT twr(market_value, NULL) AS null_dates_test
FROM test_twr
GROUP BY asset_id;

-- Test zero values
TRUNCATE test_twr;
INSERT INTO test_twr VALUES
    ('F', '2023-01-01', 0.0),
    ('F', '2023-06-01', 1000.0);

SELECT twr(market_value, flow_date) AS zero_value_test
FROM test_twr
GROUP BY asset_id;

-- Test negative values
TRUNCATE test_twr;
INSERT INTO test_twr VALUES
    ('G', '2023-01-01', 1000.0),
    ('G', '2023-06-01', -1000.0);

SELECT twr(market_value, flow_date) AS negative_value_test
FROM test_twr
GROUP BY asset_id;

\set ON_ERROR_STOP 1

-- Test precision with small changes
TRUNCATE test_twr;
INSERT INTO test_twr VALUES
    ('H', '2023-01-01', 1000.0),
    ('H', '2023-06-01', 1001.0);

SELECT round(twr(market_value, flow_date)::numeric, 4) AS precision_test
FROM test_twr
GROUP BY asset_id;
