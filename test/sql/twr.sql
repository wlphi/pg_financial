DROP EXTENSION IF EXISTS financial CASCADE;
CREATE EXTENSION financial;
SET extra_float_digits = -4;

SELECT twr(amt, val, ts)
FROM (VALUES
    (-1000::double precision, 1000::double precision, '2023-01-01'::timestamptz),
    (0::double precision, 1500::double precision, '2023-02-01')
) x(amt, val, ts);

SELECT twr(amt, val, ts)
FROM (VALUES
    (-1000::double precision, 1000::double precision, '2023-01-01'::timestamptz),
    (0::double precision, 800::double precision, '2023-02-01')
) x(amt, val, ts);

SELECT twr(amt, val, ts)
FROM (VALUES
    (-1000::double precision, 1000::double precision, '2023-01-01'::timestamptz),
    (0::double precision, 1000::double precision, '2023-02-01')
) x(amt, val, ts);

SELECT twr(amt, val, ts)
FROM (VALUES
    (-1000::double precision, 1000::double precision, '2023-01-01'::timestamptz),
    (0::double precision, 2500::double precision, '2023-02-01')
) x(amt, val, ts);

SELECT twr(amt, val, ts)
FROM (VALUES
    (-1000::double precision, 1000::double precision, '2023-01-01'::timestamptz)
) x(amt, val, ts);

SELECT twr(NULL::double precision, 1000::double precision, '2023-01-01'::timestamptz);
SELECT twr(1000::double precision, NULL::double precision, '2023-01-01'::timestamptz);
SELECT twr(1000::double precision, 1000::double precision, NULL::timestamptz);

SELECT twr(amt, val, ts)
FROM (VALUES
    (-1000::double precision, -1000::double precision, '2023-01-01'::timestamptz),
    (0::double precision, 1000::double precision, '2023-02-01')
) x(amt, val, ts);

SELECT twr(amt, val, ts)
FROM (VALUES
    (-1000::double precision, 0::double precision, '2023-01-01'::timestamptz),
    (0::double precision, 1000::double precision, '2023-02-01')
) x(amt, val, ts);

SELECT twr(amt, val, ts)
FROM (VALUES
    (-1000::double precision, 1000::double precision, '2023-01-01'::timestamptz),
    (0::double precision, 1001::double precision, '2023-02-01')
) x(amt, val, ts);

SELECT twr(amt, val, ts) OVER (ORDER BY ts)
FROM (VALUES
    (-1000::double precision, 1000::double precision, '2023-01-01'::timestamptz),
    (-500::double precision, 1600::double precision, '2023-02-01'),
    (200::double precision, 1500::double precision, '2023-03-01')
) x(amt, val, ts);
