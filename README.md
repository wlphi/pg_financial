I'll help improve the README formatting and organization. Here's the updated version:

# PostgreSQL Financial Extension

This is a PostgreSQL extension for financial calculations.

## Functions Provided

* `xirr(amounts, dates [, guess])` - Irregular Internal Rate of Return. Aggregate function, similar to XIRR in spreadsheet programs (Excel, LibreOffice, etc).
* `twr(amount, portfolio_value, timestamp)` - Time-Weighted Return calculation that requires cashflow amount, portfolio value and timestamp for every cashflow plus the current date (where cashflow may be zero).

## Installation

pg_financial is tested with PostgreSQL versions from 10 to 15.

To build and install this extension:

```bash
make
sudo make install
```

Then, activate the extension in your database:

```sql
CREATE EXTENSION financial;
```

If you encounter build problems, please see the [PostgreSQL wiki](wiki_link) for troubleshooting.

## Usage

### XIRR Aggregate Function

The basic form of the XIRR function is: `xirr(amounts, dates [, guess])`

Since XIRR is fundamentally an imprecise function, `amounts` is of type `float8` (double precision). `dates` is `timestamp with time zone`.

Basic example using a transaction table with columns `amount` and `time`:

```sql
SELECT xirr(amount, time ORDER BY time) FROM transaction;
```

Example output:
```
        xirr        
--------------------
 0.0176201237088334
```

The `guess` argument (also `float8`) is an optional initial guess. When omitted, the function uses annualized return as the guess, which is usually reliable. Excel and LibreOffice use a default guess of 0.1:

```sql
SELECT xirr(amount, time, 0.1 ORDER BY time) FROM transaction;
```

### XIRR Calculation Examples

#### Single Instrument XIRR
For a single instrument, XIRR calculates returns based on individual transaction cashflows:

```sql
SELECT xirr(
   CASE 
       WHEN type IN ('buy', 'contribution') THEN -amount
       WHEN type IN ('sell', 'withdrawal') THEN amount
   END,
   transaction_date 
   ORDER BY transaction_date
) 
FROM instrument_transactions;
```

#### Portfolio XIRR
For portfolio-level calculations, XIRR requires:

* All cashflows from constituent instruments combined
* Initial portfolio value as a negative cashflow at start date
* Final portfolio value as a positive cashflow at end date

Example with current portfolio value:

```sql
WITH portfolio_flows AS (
    SELECT transaction_date, 
           CASE 
               WHEN type IN ('buy', 'contribution') THEN -amount
               WHEN type IN ('sell', 'withdrawal') THEN amount
           END as cashflow
    FROM transactions
    UNION ALL
    SELECT CURRENT_TIMESTAMP, current_portfolio_value
    FROM portfolio_value
)
SELECT xirr(cashflow, transaction_date ORDER BY transaction_date)
FROM portfolio_flows;
```

### Advanced Usage

Like any aggregate function, you can use xirr with GROUP BY or as a window function:

```sql
SELECT portfolio, xirr(amount, time ORDER BY time)
    FROM transaction GROUP BY portfolio;

SELECT xirr(amount, time) OVER (ORDER BY time)
    FROM transaction;
```

### Important Notes

* There are situations where XIRR (Newton's method) fails to arrive at a result. In these cases, the function returns NULL. Sometimes providing a better guess helps, but some inputs are simply indeterminate.
* Because XIRR needs multiple passes over input data, all inputs to the aggregate function are held in memory (16 bytes per row). Be cautious with extremely large datasets to avoid server memory issues.

### TWR Function

The Time-Weighted Return function is implemented as:
TWR (Time-Weighted Return)
The twr(amount, portfolio_value, timestamp) aggregate function calculates time-weighted returns. It requires:
* Cashflow amount (cashflow may be zero)
* Portfolio value
* Timestamp for each cashflow

```sql
SELECT twr(amt, val, ts) OVER (ORDER BY ts)
FROM (VALUES
    (-1000::double precision, 1000::double precision, '2023-01-01'::timestamptz),
    (-500::double precision, 1600::double precision, '2023-02-01'),
    (200::double precision, 1500::double precision, '2023-03-01')
) x(amt, val, ts);
```
Here's the markdown code formatted for easy copying:

### Time-Weighted Return (TWR) Calculation

TWR calculations support portfolio-level analysis by aggregating transactions across multiple assets. Key points:

* Each transaction requires three inputs:
  * The cashflow amount
  * Total portfolio value (sum of all relevant assets) after the cashflow
  * Transaction timestamp

* Portfolio weights are automatically derived from the cashflow patterns, requiring no explicit weight specification

* For partial period calculations (starting after portfolio inception):
  * Include an initial transaction at your start date (t0)
  * Set the cashflow amount to 0
  * Include the total portfolio value at t0

This approach ensures accurate price return tracking while maintaining proper portfolio weightings through time.

## License

See `LICENSE` for details.
