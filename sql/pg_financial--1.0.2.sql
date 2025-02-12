CREATE FUNCTION twr(dates date[], values double precision[]) RETURNS double precision
    AS 'MODULE_PATHNAME', 'twr'
    LANGUAGE C IMMUTABLE;
