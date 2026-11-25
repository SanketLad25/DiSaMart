#!/usr/bin/env bash
set -euo pipefail

SQLCMD=/opt/mssql-tools18/bin/sqlcmd
if [[ ! -x "$SQLCMD" ]]; then
    SQLCMD=/opt/mssql-tools/bin/sqlcmd
fi

if [[ ! -x "$SQLCMD" ]]; then
    echo "sqlcmd was not found in the SQL Server tools image." >&2
    exit 1
fi

attempt=0
until "$SQLCMD" -S "${DB_HOST},1433" -U sa -P "$SQLSERVER_SA_PASSWORD" -C -b -Q "SELECT 1" >/dev/null 2>&1; do
    attempt=$((attempt + 1))
    if [[ "$attempt" -ge 60 ]]; then
        echo "SQL Server did not become available within 5 minutes." >&2
        exit 1
    fi
    sleep 5
done

"$SQLCMD" -S "${DB_HOST},1433" -U sa -P "$SQLSERVER_SA_PASSWORD" -C -b -i /database/001-create-databases.sql
"$SQLCMD" -S "${DB_HOST},1433" -U sa -P "$SQLSERVER_SA_PASSWORD" -C -b -i /database/002-product-catalog.sql
"$SQLCMD" -S "${DB_HOST},1433" -U sa -P "$SQLSERVER_SA_PASSWORD" -C -b -i /database/003-service-schemas.sql
"$SQLCMD" -S "${DB_HOST},1433" -U sa -P "$SQLSERVER_SA_PASSWORD" -C -b -i /database/004-static-service-seed.sql

echo "DiSaMart databases and seed data are ready."
