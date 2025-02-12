-- twr.sql
-- Test basic TWR calculation with appreciation
SELECT round(twr(
    ARRAY[date '2023-01-01', date '2023-06-01', date '2023-12-31'],
    ARRAY[1000.0, 1200.0, 1500.0]
)::numeric, 4);

-- Test TWR with depreciation
SELECT round(twr(
    ARRAY[date '2023-01-01', date '2023-06-01', date '2023-12-31'],
    ARRAY[1000.0, 900.0, 800.0]
)::numeric, 4);

-- Test TWR with no value change
SELECT round(twr(
    ARRAY[date '2023-01-01', date '2023-06-01', date '2023-12-31'],
    ARRAY[1000.0, 1000.0, 1000.0]
)::numeric, 4);

-- Test TWR with large fluctuations
SELECT round(twr(
    ARRAY[date '2023-01-01', date '2023-06-01', date '2023-12-31'],
    ARRAY[1000.0, 5000.0, 2500.0]
)::numeric, 4);

-- Test single data point (expect NULL)
SELECT twr(
    ARRAY[date '2023-01-01'],
    ARRAY[1000.0]
);

-- Test NULL inputs
SELECT twr(NULL, ARRAY[1000.0]);
SELECT twr(ARRAY[date '2023-01-01'], NULL);

-- Test mismatched array lengths
SELECT twr(
    ARRAY[date '2023-01-01', date '2023-06-01'],
    ARRAY[1000.0]
);

-- Test zero values
SELECT twr(
    ARRAY[date '2023-01-01', date '2023-06-01'],
    ARRAY[0.0, 1000.0]
);

-- Test negative values
SELECT twr(
    ARRAY[date '2023-01-01', date '2023-06-01'],
    ARRAY[1000.0, -1000.0]
);

-- Test precision with small changes
SELECT round(twr(
    ARRAY[date '2023-01-01', date '2023-06-01'],
    ARRAY[1000.0, 1001.0]
)::numeric, 4);
