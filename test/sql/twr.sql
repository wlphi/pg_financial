\set QUIET 1
-- Adjust precision settings for consistent test output
SET extra_float_digits = 0;

-- TWR Test Cases

-- Test basic TWR calculation with appreciation
SELECT round(twr(
    ARRAY[date '2023-01-01', date '2023-06-01', date '2023-12-31'],
    ARRAY[1000.0, 1200.0, 1500.0]
)::numeric, 4) AS appreciation_test;

-- Test TWR with depreciation
SELECT round(twr(
    ARRAY[date '2023-01-01', date '2023-06-01', date '2023-12-31'],
    ARRAY[1000.0, 900.0, 800.0]
)::numeric, 4) AS depreciation_test;

-- Test TWR with no value change
SELECT round(twr(
    ARRAY[date '2023-01-01', date '2023-06-01', date '2023-12-31'],
    ARRAY[1000.0, 1000.0, 1000.0]
)::numeric, 4) AS no_change_test;

-- Test TWR with large fluctuations
SELECT round(twr(
    ARRAY[date '2023-01-01', date '2023-06-01', date '2023-12-31'],
    ARRAY[1000.0, 5000.0, 2500.0]
)::numeric, 4) AS volatility_test;

-- Test single data point (expect NULL)
SELECT twr(
    ARRAY[date '2023-01-01'],
    ARRAY[1000.0]
) AS single_point_test;

-- Test error cases
\set ON_ERROR_STOP 0

-- Test NULL inputs
SELECT twr(NULL, ARRAY[1000.0]) AS null_dates_test;
SELECT twr(ARRAY[date '2023-01-01'], NULL) AS null_values_test;

-- Test mismatched array lengths
SELECT twr(
    ARRAY[date '2023-01-01', date '2023-06-01'],
    ARRAY[1000.0]
) AS mismatch_test;

-- Test zero values
SELECT twr(
    ARRAY[date '2023-01-01', date '2023-06-01'],
    ARRAY[0.0, 1000.0]
) AS zero_value_test;

-- Test negative values
SELECT twr(
    ARRAY[date '2023-01-01', date '2023-06-01'],
    ARRAY[1000.0, -1000.0]
) AS negative_value_test;

\set ON_ERROR_STOP 1

-- Test precision with small changes
SELECT round(twr(
    ARRAY[date '2023-01-01', date '2023-06-01'],
    ARRAY[1000.0, 1001.0]
)::numeric, 4) AS precision_test;
