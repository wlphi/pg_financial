CREATE OR REPLACE FUNCTION twr_tstz_transfn(internal, double precision, double precision, timestamp with time zone)
RETURNS internal
AS 'MODULE_PATHNAME', 'twr_tstz_transfn'
LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION twr_tstz_finalfn(internal)
RETURNS double precision
AS 'MODULE_PATHNAME', 'twr_tstz_finalfn'
LANGUAGE C IMMUTABLE;

CREATE AGGREGATE twr(amount double precision, value double precision, "time" timestamp with time zone) (
    SFUNC = twr_tstz_transfn,
    STYPE = internal,
    FINALFUNC = twr_tstz_finalfn
);
