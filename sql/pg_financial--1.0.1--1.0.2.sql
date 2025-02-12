-- Aggregate function for TWR calculation
CREATE FUNCTION twr_tstz_transfn(internal, float8, timestamptz)
RETURNS internal IMMUTABLE LANGUAGE C AS 'financial';

CREATE FUNCTION twr_tstz_finalfn(internal)
RETURNS float8 IMMUTABLE LANGUAGE C AS 'financial';

CREATE AGGREGATE twr (float8, timestamptz) (
    SFUNC = twr_tstz_transfn,
    STYPE = internal,
    FINALFUNC = twr_tstz_finalfn
);
