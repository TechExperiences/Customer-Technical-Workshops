# Fabric notebook source
# Load only Analytical and Operational landing files into Lakehouse Delta tables.
# BusinessApplication JSON is intentionally loaded into Fabric SQL Database by Logic App.

from pyspark.sql import functions as F

PACKAGE_ROOT = "Files/raw"
TARGET_SCHEMA = "dbo"

ANALYTICAL_TABLES = [
    "DimDate", "DimLocation", "DimMaterial", "DimPlant", "DimProduct", "DimSupplier",
    "FactInventory", "FactInventorySnapshot", "FactProduction", "FactQuality", "FactSales",
    "FactShipment", "FactSupplyChain",
]
OPERATIONAL_TABLES = [
    "Inventory", "ManufacturingBatch", "Material", "PurchaseOrder",
    "PurchaseOrderItem", "QualityInspection", "Shipment", "Supplier",
]

spark.sql(f"CREATE SCHEMA IF NOT EXISTS {TARGET_SCHEMA}")

def write_table(dataframe, table_name):
    (dataframe.write
        .format("delta")
        .mode("overwrite")
        .option("overwriteSchema", "true")
        .saveAsTable(f"{TARGET_SCHEMA}.{table_name.lower()}"))

for table in ANALYTICAL_TABLES:
    df = (spark.read.option("header", "true").option("inferSchema", "true")
          .csv(f"{PACKAGE_ROOT}/Analytical/{table}.csv"))
    write_table(df, table)

for table in OPERATIONAL_TABLES:
    df = (spark.read.option("header", "true").option("inferSchema", "true")
          .csv(f"{PACKAGE_ROOT}/Operational/{table}.csv"))
    write_table(df, table)

# Normalize the one mixed-format source date before semantic-model use.
spark.sql(f"""
    CREATE OR REPLACE TABLE {TARGET_SCHEMA}.factsales AS
    SELECT * EXCEPT (SalesDate),
           COALESCE(to_date(SalesDate, 'M/d/yyyy h:mm:ss a'), to_date(SalesDate)) AS SalesDate
    FROM {TARGET_SCHEMA}.factsales
""")

# Extend DimDate for fact dates outside the supplied dimension calendar.
spark.sql(f"""
    MERGE INTO {TARGET_SCHEMA}.dimdate d
    USING (
        SELECT DISTINCT DateKey
        FROM (
            SELECT DateKey FROM {TARGET_SCHEMA}.factquality
            UNION ALL SELECT DateKey FROM {TARGET_SCHEMA}.factshipment
        )
        WHERE DateKey NOT IN (SELECT DateKey FROM {TARGET_SCHEMA}.dimdate)
    ) s
    ON d.DateKey = s.DateKey
    WHEN NOT MATCHED THEN INSERT (DateKey, FullDate, Year, Quarter, Month, MonthName, Day)
    VALUES (s.DateKey, to_date(cast(s.DateKey as string), 'yyyyMMdd'),
            year(to_date(cast(s.DateKey as string), 'yyyyMMdd')),
            quarter(to_date(cast(s.DateKey as string), 'yyyyMMdd')),
            month(to_date(cast(s.DateKey as string), 'yyyyMMdd')),
            date_format(to_date(cast(s.DateKey as string), 'yyyyMMdd'), 'MMMM'),
            dayofmonth(to_date(cast(s.DateKey as string), 'yyyyMMdd')))
""")

display(spark.sql(f"SHOW TABLES IN {TARGET_SCHEMA}"))
