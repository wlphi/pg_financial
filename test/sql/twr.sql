\set VERBOSITY verbose

-- Setup test tables
CREATE TEMPORARY TABLE twr_test (
    test_name text,
    amount double precision,
    value double precision,
    ts timestamptz
);

-- Test cases
INSERT INTO twr_test VALUES
    ('appreciation_test', -1000, 1000, '2023-01-01'),
    ('appreciation_test', 0, 1500, '2023-02-01');

INSERT INTO twr_test VALUES
    ('depreciation_test', -1000, 1000, '2023-01-01'),
    ('depreciation_test', 0, 800, '2023-02-01');

INSERT INTO twr_test VALUES
    ('no_change_test', -1000, 1000, '2023-01-01'),
    ('no_change_test', 0, 1000, '2023-02-01');

INSERT INTO twr_test VALUES
    ('volatility_test', -1000, 1000, '2023-01-01'),
    ('volatility_test', 0, 2500, '2023-02-01');

INSERT INTO twr_test VALUES
    ('single_point_test', -1000, 1000, '2023-01-01');

INSERT INTO twr_test VALUES
    ('precision_test', -1000, 1000, '2023-01-01'),
    ('precision_test', 0, 1001, '2023-02-01');

-- Run basic tests
SELECT test_name, 
       round(twr(amount, value, ts)::numeric, 4) as twr_result
FROM twr_test
WHERE test_name = 'appreciation_test'
GROUP BY test_name;

SELECT test_name, 
       round(twr(amount, value, ts)::numeric, 4) as twr_result
FROM twr_test
WHERE test_name = 'depreciation_test'
GROUP BY test_name;

SELECT test_name, 
       round(twr(amount, value, ts)::numeric, 4) as twr_result
FROM twr_test
WHERE test_name = 'no_change_test'
GROUP BY test_name;

SELECT test_name, 
       round(twr(amount, value, ts)::numeric, 4) as twr_result
FROM twr_test
WHERE test_name = 'volatility_test'
GROUP BY test_name;

SELECT test_name, 
       round(twr(amount, value, ts)::numeric, 4) as twr_result
FROM twr_test
WHERE test_name = 'single_point_test'
GROUP BY test_name;

-- NULL tests
SELECT twr(NULL::double precision, 1000, '2023-01-01'::timestamptz);
SELECT twr(1000, NULL::double precision, '2023-01-01'::timestamptz);

-- Array length mismatch test
SELECT twr(-1000, 1000, '2023-01-01'::timestamptz) 
FROM (VALUES (1), (2)) t;

-- Invalid value tests
INSERT INTO twr_test VALUES
    ('negative_value_test', -1000, -1000, '2023-01-01'),
    ('negative_value_test', 0, 1000, '2023-02-01');

SELECT test_name, 
       round(twr(amount, value, ts)::numeric, 4) as twr_result
FROM twr_test
WHERE test_name = 'negative_value_test'
GROUP BY test_name;

INSERT INTO twr_test VALUES
    ('zero_value_test', -1000, 0, '2023-01-01'),
    ('zero_value_test', 0, 1000, '2023-02-01');

SELECT test_name, 
       round(twr(amount, value, ts)::numeric, 4) as twr_result
FROM twr_test
WHERE test_name = 'zero_value_test'
GROUP BY test_name;

-- Precision test
SELECT test_name, 
       round(twr(amount, value, ts)::numeric, 4) as twr_result
FROM twr_test
WHERE test_name = 'precision_test'
GROUP BY test_name;
