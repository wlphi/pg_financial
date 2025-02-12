#include "postgres.h"
#include "fmgr.h"
#include "utils/timestamp.h"
#include <math.h>

PG_MODULE_MAGIC;

/*
 * Structure to accumulate values for TWR calculation
 */
typedef struct TwrItem {
    double market_value;
    TimestampTz time;
} TwrItem;

typedef struct TwrState {
    int alen;       /* Allocated length of array */
    int nelems;     /* Number of elements stored */
    TwrItem array[0]; /* Dynamically sized array */
} TwrState;

PG_FUNCTION_INFO_V1(twr_tstz_transfn);
PG_FUNCTION_INFO_V1(twr_tstz_finalfn);

/*
 * Aggregate transition function - accumulates market values & timestamps.
 */
Datum
twr_tstz_transfn(PG_FUNCTION_ARGS)
{
    MemoryContext oldcontext;
    MemoryContext aggcontext;
    TwrState *state;
    double market_value;
    TimestampTz time;

    if (PG_ARGISNULL(1) || PG_ARGISNULL(2)) {
        PG_RETURN_POINTER(PG_ARGISNULL(0) ? NULL : PG_GETARG_POINTER(0));
    }

    if (PG_ARGISNULL(0)) {
        const int initlen = 64;

        if (!AggCheckCallContext(fcinfo, &aggcontext))
            elog(ERROR, "twr_tstz_transfn called in non-aggregate context");

        oldcontext = MemoryContextSwitchTo(aggcontext);
        state = palloc(sizeof(TwrState) + initlen * sizeof(TwrItem));
        state->alen = initlen;
        state->nelems = 0;
        MemoryContextSwitchTo(oldcontext);
    } else {
        state = (TwrState *) PG_GETARG_POINTER(0);
    }

    market_value = PG_GETARG_FLOAT8(1);
    time = PG_GETARG_TIMESTAMPTZ(2);

    /* Ensure portfolio values are positive */
    if (market_value <= 0.0)
        ereport(ERROR, (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                        errmsg("Portfolio values must be positive")));

    /* Prevent duplicate timestamps */
    if (state->nelems > 0 && time == state->array[state->nelems - 1].time)
        PG_RETURN_POINTER(state);

    /* Expand array if needed */
    if (state->nelems >= state->alen) {
        if (!AggCheckCallContext(fcinfo, &aggcontext))
            elog(ERROR, "twr_tstz_transfn called in non-aggregate context");

        oldcontext = MemoryContextSwitchTo(aggcontext);
        state->alen *= 2;
        state = repalloc(state, sizeof(TwrState) + state->alen * sizeof(TwrItem));
        MemoryContextSwitchTo(oldcontext);
    }

    state->array[state->nelems].market_value = market_value;
    state->array[state->nelems].time = time;
    state->nelems++;

    PG_RETURN_POINTER(state);
}

/*
 * Final function - computes TWR from accumulated market values.
 */
Datum
twr_tstz_finalfn(PG_FUNCTION_ARGS)
{
    const TwrState *state;
    double twr = 1.0;
    int i;

    if (PG_ARGISNULL(0))
        PG_RETURN_NULL();

    state = (TwrState *) PG_GETARG_POINTER(0);

    if (state->nelems < 2)
        PG_RETURN_NULL();

    /* Calculate compounded returns */
    for (i = 1; i < state->nelems; i++) {
        double previous_value = state->array[i - 1].market_value;
        double current_value = state->array[i].market_value;

        if (previous_value <= 0.0) {
            ereport(ERROR, (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                            errmsg("Portfolio values must be positive")));
        }

        double sub_period_return = (current_value - previous_value) / previous_value;

        if (isinf(sub_period_return) || isnan(sub_period_return)) {
            ereport(ERROR, (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                            errmsg("Calculation resulted in invalid value")));
        }

        twr *= (1.0 + sub_period_return);
    }

    PG_RETURN_FLOAT8(twr - 1.0);
}
