# DiSaMart Database Setup

The scripts in this folder define one SQL Server database per service. Schema creation and seed scripts are safe to rerun: they do not drop existing tables.

## Files

- `001-create-databases.sql`: creates all service databases.
- `002-product-catalog.sql`: creates catalog tables and seed data.
- `003-service-schemas.sql`: creates schemas for the remaining services.
- `004-static-service-seed.sql`: creates initial currency, email, advertisement, campaign, and customization seed data.
- `seed-data.json`: static catalog data in frontend and tooling-friendly JSON.

## Manual Execution

Run the scripts with SQL Server Management Studio or `sqlcmd` in numerical order:

```powershell
sqlcmd -S localhost,1433 -U sa -P "<password>" -i database/001-create-databases.sql
sqlcmd -S localhost,1433 -U sa -P "<password>" -i database/002-product-catalog.sql
sqlcmd -S localhost,1433 -U sa -P "<password>" -i database/003-service-schemas.sql
sqlcmd -S localhost,1433 -U sa -P "<password>" -i database/004-static-service-seed.sql
```

The scripts are idempotent and do not contain real credentials.
