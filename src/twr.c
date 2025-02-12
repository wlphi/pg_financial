#include "postgres.h"
#include "fmgr.h"
#include "utils/array.h"
#include "utils/builtins.h"
#include <math.h>

PG_MODULE_MAGIC;

/*
 * Calculate Time-Weighted Return (TWR) for a series of portfolio values
 * 
 * @param dates Array of dates (currently unused but kept for future enhancements)
 * @param values Array of portfolio values
 * @return TWR as a percentage (returns NULL for invalid inputs)
 */
PG_FUNCTION_INFO_V1(twr);
Datum
twr(PG_FUNCTION_ARGS)
{
    // Input validation
    if (PG_ARGISNULL(0) || PG_ARGISNULL(1)) {
        ereport(ERROR,
                (errcode(ERRCODE_NULL_VALUE_NOT_ALLOWED),
                 errmsg("NULL arrays are not allowed as input")));
    }

    ArrayType *dates = PG_GETARG_ARRAYTYPE_P(0);
    ArrayType *values = PG_GETARG_ARRAYTYPE_P(1);

    // Ensure arrays are 1-dimensional
    if (ARR_NDIM(dates) != 1 || ARR_NDIM(values) != 1) {
        ereport(ERROR,
                (errcode(ERRCODE_ARRAY_SUBSCRIPT_ERROR),
                 errmsg("Arrays must be 1-dimensional")));
    }

    // Get array dimensions
    int num_periods = ARR_DIMS(dates)[0];
    int num_values = ARR_DIMS(values)[0];

    // Ensure arrays have matching lengths
    if (num_periods != num_values) {
        ereport(ERROR,
                (errcode(ERRCODE_ARRAY_SUBSCRIPT_ERROR),
                 errmsg("Date and value arrays must have the same length")));
    }

    // Check minimum required periods
    if (num_periods < 2) {
        PG_RETURN_NULL();
    }

    // Get array data
    double *date_vals = (double *)ARR_DATA_PTR(dates);
    double *value_vals = (double *)ARR_DATA_PTR(values);

    // Calculate TWR
    double twr = 1.0;
    for (int i = 1; i < num_periods; i++) {
        double previous_value = value_vals[i - 1];
        double current_value = value_vals[i];

        // Handle zero or negative values
        if (previous_value <= 0.0) {
            ereport(ERROR,
                    (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                     errmsg("Portfolio values must be positive")));
        }

        double sub_period_return = (current_value - previous_value) / previous_value;
        
        // Check for potential overflow
        if (isinf(sub_period_return) || isnan(sub_period_return)) {
            ereport(ERROR,
                    (errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
                     errmsg("Calculation resulted in invalid value")));
        }

        twr *= (1.0 + sub_period_return);
    }

    // Return final TWR as a percentage
    PG_RETURN_FLOAT8(twr - 1.0);
}
