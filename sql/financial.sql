-- xirr(amount, time)
CREATE FUNCTION xirr_tstz_transfn (internal, float8, timestamptz)
RETURNS internal IMMUTABLE LANGUAGE C AS 'financial';

CREATE FUNCTION xirr_tstz_finalfn (internal)
RETURNS float8 IMMUTABLE LANGUAGE C AS 'financial';

CREATE AGGREGATE xirr (float8, timestamptz) (
    SFUNC = xirr_tstz_transfn,
    STYPE = internal,
    FINALFUNC = xirr_tstz_finalfn
);

-- xirr(amount, time, guess)
CREATE FUNCTION xirr_tstz_transfn (internal, float8, timestamptz, float8)
RETURNS internal IMMUTABLE LANGUAGE C AS 'financial';

CREATE AGGREGATE xirr (float8, timestamptz, float8) (
    SFUNC = xirr_tstz_transfn,
    STYPE = internal,
    FINALFUNC = xirr_tstz_finalfn
);

-- twr(amount, value, timestamp)
CREATE FUNCTION twr_tstz_transfn(internal, double precision, double precision, timestamp with time zone)
RETURNS internal
AS 'MODULE_PATHNAME', 'twr_tstz_transfn'
LANGUAGE C IMMUTABLE;

CREATE FUNCTION twr_tstz_finalfn(internal)
RETURNS double precision
AS 'MODULE_PATHNAME', 'twr_tstz_finalfn'
LANGUAGE C IMMUTABLE;

CREATE AGGREGATE twr(amount double precision, value double precision, "time" timestamp with time zone) (
    SFUNC = twr_tstz_transfn,
    STYPE = internal,
    FINALFUNC = twr_tstz_finalfn
);
