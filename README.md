# pg_financial: Financial Functions for PostgreSQL

## Overview
`pg_financial` is a PostgreSQL extension providing financial functions, including `XIRR` (Extended Internal Rate of Return) and `TWR` (Time-Weighted Return), optimized for large-scale portfolio and investment analytics.

## Features
- **XIRR**: Calculates the internal rate of return for irregular cash flows.
- **TWR**: Computes time-weighted returns, useful for performance measurement without cash flow bias.

## Installation
### Prerequisites
Ensure you have PostgreSQL installed along with development tools:
```sh
sudo apt install postgresql-server-dev-XX # Replace XX with your PostgreSQL version
```

### Build and Install
```sh
git clone https://github.com/intgr/pg_financial.git
cd pg_financial
make
make install
```

### Enable Extension
```sql
CREATE EXTENSION pg_financial;
```

## Usage
### XIRR Calculation
```sql
SELECT xirr(
    ARRAY[date '2023-01-01', date '2023-06-01', date '2023-12-31'],
    ARRAY[-1000.0, 200.0, 1500.0]
);
```

### TWR Calculation
```sql
SELECT twr(
    ARRAY[date '2023-01-01', date '2023-06-01', date '2023-12-31'],
    ARRAY[1000.0, 1200.0, 1500.0]
);
```

## Example Queries
### Compute XIRR for Financial Assets
```sql
WITH cash_flows_combined AS (
    SELECT asset_id, flow_date, amount FROM cash_flows
    UNION ALL
    SELECT asset_id, price_date AS flow_date, market_value AS amount FROM asset_prices
)
SELECT asset_id,
       xirr(
           ARRAY_AGG(flow_date ORDER BY flow_date),
           ARRAY_AGG(amount ORDER BY flow_date)
       ) AS irr
FROM cash_flows_combined
GROUP BY asset_id;
```

### Compute TWR for Financial Assets
```sql
WITH asset_values AS (
    SELECT asset_id, flow_date, market_value FROM asset_prices
    UNION ALL
    SELECT asset_id, flow_date, amount AS market_value FROM cash_flows
)
SELECT asset_id,
       twr(
           ARRAY_AGG(flow_date ORDER BY flow_date),
           ARRAY_AGG(market_value ORDER BY flow_date)
       ) AS twr
FROM asset_values
GROUP BY asset_id;
```

## Performance Considerations
- Implemented in **C** for high efficiency.
- Uses **array-based processing** to avoid expensive window functions.
- Suitable for large-scale financial datasets.

## Contributions
Pull requests are welcome! To contribute:
1. Fork the repository.
2. Implement improvements or bug fixes.
3. Submit a PR with detailed explanations.

## License
See `LICENSE` for details.
