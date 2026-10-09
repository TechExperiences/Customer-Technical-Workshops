# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "__LAKEHOUSE_ID__",
# META       "default_lakehouse_name": "__LAKEHOUSE_NAME__",
# META       "default_lakehouse_workspace_id": "__WORKSPACE_ID__"
# META     }
# META   }
# META }

# CELL ********************

# Load the governed Lakehouse representation used by the semantic model.  The
# BusinessApplication JSON is also retained in Fabric SQL Database through the
# Logic App; materializing it here avoids an external DirectQuery credential
# dependency in the semantic model.

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
BUSINESS_APPLICATION_TABLES = ["CustomerDetails", "CustomerAddress"]

# Direct Lake maps directly to the physical Delta schema.  CSV inference otherwise
# produces 32-bit integers and date values that do not match the model's int64 and
# dateTime declarations, leaving every Direct Lake table unavailable at query time.
TEMPORAL_COLUMNS = {
    "DimDate": {"FullDate"}, "DimProduct": {"LaunchDate"}, "DimSupplier": {"OnboardedDate"},
    "FactInventory": {"SnapshotDate"}, "FactSales": {"SalesDate"}, "Supplier": {"OnboardedDate"},
    "PurchaseOrder": {"OrderDate", "ExpectedDeliveryDate"},
    "ManufacturingBatch": {"StartDate", "EndDate"}, "Inventory": {"LastUpdated"},
    "QualityInspection": {"InspectionDate"}, "Shipment": {"ShipDate", "DeliveryDate"},
    "CustomerDetails": {"CreatedDate"},
}

spark.sql(f"CREATE SCHEMA IF NOT EXISTS {TARGET_SCHEMA}")

def write_table(dataframe, table_name):
    (dataframe.write
        .format("delta")
        .mode("overwrite")
        .option("overwriteSchema", "true")
        .saveAsTable(f"{TARGET_SCHEMA}.{table_name.lower()}"))


def normalize_for_direct_lake(dataframe, table_name):
    """Make physical Delta types match the semantic model's Direct Lake contract."""
    for field in dataframe.schema.fields:
        if field.dataType.simpleString() in {"tinyint", "smallint", "int"}:
            dataframe = dataframe.withColumn(field.name, F.col(field.name).cast("long"))
        elif field.dataType.simpleString() == "float":
            dataframe = dataframe.withColumn(field.name, F.col(field.name).cast("double"))
    for column in TEMPORAL_COLUMNS.get(table_name, set()):
        if table_name == "FactSales" and column == "SalesDate":
            dataframe = dataframe.withColumn(
                column,
                F.coalesce(F.to_timestamp(column, "M/d/yyyy h:mm:ss a"), F.to_timestamp(column)),
            )
        else:
            dataframe = dataframe.withColumn(column, F.to_timestamp(F.col(column)))
    return dataframe

for table in ANALYTICAL_TABLES:
    df = (spark.read.option("header", "true").option("inferSchema", "true")
          .csv(f"{PACKAGE_ROOT}/Analytical/{table}.csv"))
    write_table(normalize_for_direct_lake(df, table), table)

for table in OPERATIONAL_TABLES:
    df = (spark.read.option("header", "true").option("inferSchema", "true")
          .csv(f"{PACKAGE_ROOT}/Operational/{table}.csv"))
    write_table(normalize_for_direct_lake(df, table), table)

for table in BUSINESS_APPLICATION_TABLES:
    # Source files are JSON arrays, so multiLine is required for Spark to read
    # each array as records rather than treating the whole document as one row.
    df = spark.read.option("multiLine", "true").json(f"{PACKAGE_ROOT}/BusinessApplication/{table}.json")
    write_table(normalize_for_direct_lake(df, table), table)

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

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
