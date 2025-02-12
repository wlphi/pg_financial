#include "postgres.h"
#include "fmgr.h"
#include <math.h>

PG_MODULE_MAGIC;

PG_FUNCTION_INFO_V1(twr);

Datum
twr(PG_FUNCTION_ARGS)
{
    ArrayType *dates = PG_GETARG_ARRAYTYPE_P(0);
    ArrayType *values = PG_GETARG_ARRAYTYPE_P(1);

    int num_periods = ARR_DIMS(dates)[0];
    double *date_vals = (double *)ARR_DATA_PTR(dates);
    double *value_vals = (double *)ARR_DATA_PTR(values);

    if (num_periods < 2) {
        PG_RETURN_NULL();
    }

    double twr = 1.0;

    for (int i = 1; i < num_periods; i++) {
        double previous_value = value_vals[i - 1];
        double current_value = value_vals[i];

        if (previous_value == 0.0) {
            continue;
        }

        double sub_period_return = (current_value - previous_value) / previous_value;
        twr *= (1.0 + sub_period_return);
    }

    PG_RETURN_FLOAT8(twr - 1.0);
}
