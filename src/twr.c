/*-------------------------------------------------------------------------
 *
 * twr.c
 *    Time-Weighted Return
 *
 * Copyright (c) 2025 [Your Name] <email>
 *
 *-------------------------------------------------------------------------
 */

#include <math.h>

#include "postgres.h"
#include "miscadmin.h"
#include "utils/timestamp.h"
#include "fmgr.h"

PG_MODULE_MAGIC;

/**** Declarations */

typedef struct TwrItem
{
    double      amount;         /* cash flow amount */
    double      value;          /* portfolio value at this point */
    TimestampTz time;          /* timestamp of the flow/valuation */
} TwrItem;

typedef struct TwrState
{
    int         alen;           /* allocated length of array */
    int         nelems;         /* number of elements filled in array */
    TwrItem     array[0];      /* array of values */
} TwrState;

PG_FUNCTION_INFO_V1(twr_tstz_transfn);
PG_FUNCTION_INFO_V1(twr_tstz_finalfn);

/**** Implementation */

/*
 * Aggregate state function for TWR. Accumulates amount+value+timestamp values in TwrState.
 */
Datum
twr_tstz_transfn(PG_FUNCTION_ARGS)
{
    MemoryContext oldcontext;
    MemoryContext aggcontext;
    TwrState   *state;
    double      amount;
    double      value;
    TimestampTz time;

    if (PG_ARGISNULL(1))
        elog(ERROR, "twr amount input cannot be NULL");
    if (PG_ARGISNULL(2))
        elog(ERROR, "twr value input cannot be NULL");
    if (PG_ARGISNULL(3))
        elog(ERROR, "twr timestamp input cannot be NULL");

    if (PG_ARGISNULL(0))
    {
        const int initlen = 64;

        if (!AggCheckCallContext(fcinfo, &aggcontext))
        {
            /* cannot be called directly because of internal-type argument */
            elog(ERROR, "twr_tstz_transfn called in non-aggregate context");
        }
        oldcontext = MemoryContextSwitchTo(aggcontext);

        state = palloc(sizeof(TwrState) + initlen * sizeof(TwrItem));
        state->alen = initlen;
        state->nelems = 0;

        MemoryContextSwitchTo(oldcontext);
    }
    else
    {
        state = (TwrState *) PG_GETARG_POINTER(0);
    }

    amount = PG_GETARG_FLOAT8(1);
    value = PG_GETARG_FLOAT8(2);
    time = PG_GETARG_TIMESTAMPTZ(3);

    /* Coalesce cash flows with the previous one if it's at the same time */
    if (state->nelems > 0 && time == state->array[state->nelems-1].time)
    {
        state->array[state->nelems-1].amount += amount;
        state->array[state->nelems-1].value = value;  /* Update to latest value */
        PG_RETURN_POINTER(state);
    }

    /* Have to append a new record */
    if (state->nelems >= state->alen)
    {
        if (!AggCheckCallContext(fcinfo, &aggcontext))
        {
            /* cannot be called directly because of internal-type argument */
            elog(ERROR, "twr_tstz_transfn called in non-aggregate context");
        }
        oldcontext = MemoryContextSwitchTo(aggcontext);

        state->alen *= 2;
        state = repalloc(state, sizeof(TwrState) + state->alen * sizeof(TwrItem));

        MemoryContextSwitchTo(oldcontext);
    }

    state->array[state->nelems].amount = amount;
    state->array[state->nelems].value = value;
    state->array[state->nelems].time = time;
    state->nelems++;

    PG_RETURN_POINTER(state);
}

/*
 * Aggregate finalize function for TWR. Takes the accumulated array and calculates
 * the time-weighted return.
 */
Datum
twr_tstz_finalfn(PG_FUNCTION_ARGS)
{
    const TwrState *state;
    double      ret = 1.0;
    int         i;

    /* no input rows */
    if (PG_ARGISNULL(0))
        PG_RETURN_NULL();

    state = (TwrState *) PG_GETARG_POINTER(0);

    if (state->nelems < 2)
        PG_RETURN_NULL();

    elog(DEBUG1, "Calculating TWR over %d records, %ld MB memory",
         state->nelems, (long)((state->nelems*sizeof(TwrItem))/(1024*1024)));

    /*
     * Calculate TWR by multiplying the holding period returns
     * For each period: (End Value - Cash Flow) / (Start Value)
     */
    for (i = 1; i < state->nelems; i++)
    {
        double start_value = state->array[i-1].value;
        double end_value = state->array[i].value;
        double cash_flow = state->array[i].amount;
        double period_return;

        /* Skip zero-length periods */
        if (state->array[i].time == state->array[i-1].time)
            continue;

        if (start_value <= 0.0)
            PG_RETURN_NULL();  /* Invalid starting value */

        period_return = (end_value - cash_flow) / start_value;
        
        /* Check for invalid returns */
        if (!isfinite(period_return) || period_return <= -1.0)
            PG_RETURN_NULL();

        ret *= period_return;

        CHECK_FOR_INTERRUPTS();
    }

    /* Convert to percentage return */
    ret = ret - 1.0;

    if (isnan(ret))
        PG_RETURN_NULL();
    else
        PG_RETURN_FLOAT8(ret);
}
