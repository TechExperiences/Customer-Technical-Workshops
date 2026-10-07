/*
  OperationalData source schema.
  Load order: Supplier, Material, PurchaseOrder, ManufacturingBatch, Inventory,
  PurchaseOrderItem, QualityInspection, Shipment.
*/

CREATE TABLE dbo.Supplier (
    SupplierID INT NOT NULL PRIMARY KEY,
    SupplierName NVARCHAR(200) NOT NULL,
    Country NVARCHAR(100) NOT NULL,
    ContactEmail NVARCHAR(320) NOT NULL,
    QualityRating DECIMAL(4,2) NOT NULL,
    OnboardedDate DATE NOT NULL
);

CREATE TABLE dbo.Material (
    MaterialID INT NOT NULL PRIMARY KEY,
    MaterialName NVARCHAR(200) NOT NULL,
    MaterialType NVARCHAR(100) NOT NULL,
    UnitOfMeasure NVARCHAR(20) NOT NULL,
    UnitCost DECIMAL(18,2) NOT NULL,
    SupplierID INT NOT NULL,
    CONSTRAINT FK_Material_Supplier FOREIGN KEY (SupplierID) REFERENCES dbo.Supplier(SupplierID)
);

CREATE TABLE dbo.PurchaseOrder (
    PurchaseOrderID INT NOT NULL PRIMARY KEY,
    SupplierID INT NOT NULL,
    PlantID INT NOT NULL,
    OrderDate DATE NOT NULL,
    ExpectedDeliveryDate DATE NOT NULL,
    Status NVARCHAR(50) NOT NULL,
    CONSTRAINT FK_PurchaseOrder_Supplier FOREIGN KEY (SupplierID) REFERENCES dbo.Supplier(SupplierID)
);

CREATE TABLE dbo.ManufacturingBatch (
    BatchID INT NOT NULL PRIMARY KEY,
    ProductID INT NOT NULL,
    PlantID INT NOT NULL,
    PrimaryMaterialID INT NOT NULL,
    BatchSize INT NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NULL,
    YieldPercentage DECIMAL(5,2) NOT NULL,
    Status NVARCHAR(50) NOT NULL,
    CONSTRAINT FK_ManufacturingBatch_Material FOREIGN KEY (PrimaryMaterialID) REFERENCES dbo.Material(MaterialID)
);

CREATE TABLE dbo.Inventory (
    InventoryID INT NOT NULL PRIMARY KEY,
    -- An inventory row represents either a finished product or a raw material.
    -- The source deliberately leaves the non-applicable identifier empty.
    ProductID INT NULL,
    MaterialID INT NULL,
    PlantID INT NOT NULL,
    QuantityOnHand INT NOT NULL,
    ReorderThreshold INT NOT NULL,
    SafetyStock INT NOT NULL,
    LastUpdated DATE NOT NULL,
    CONSTRAINT FK_Inventory_Material FOREIGN KEY (MaterialID) REFERENCES dbo.Material(MaterialID),
    CONSTRAINT CK_Inventory_ExactlyOneItemType CHECK (
        (ProductID IS NOT NULL AND MaterialID IS NULL) OR
        (ProductID IS NULL AND MaterialID IS NOT NULL)
    )
);

CREATE TABLE dbo.PurchaseOrderItem (
    PurchaseOrderItemID INT NOT NULL PRIMARY KEY,
    PurchaseOrderID INT NOT NULL,
    MaterialID INT NOT NULL,
    QuantityOrdered INT NOT NULL,
    QuantityReceived INT NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    LineTotal DECIMAL(18,2) NOT NULL,
    CONSTRAINT FK_PurchaseOrderItem_PurchaseOrder FOREIGN KEY (PurchaseOrderID) REFERENCES dbo.PurchaseOrder(PurchaseOrderID),
    CONSTRAINT FK_PurchaseOrderItem_Material FOREIGN KEY (MaterialID) REFERENCES dbo.Material(MaterialID)
);

CREATE TABLE dbo.QualityInspection (
    InspectionID INT NOT NULL PRIMARY KEY,
    BatchID INT NOT NULL,
    InspectionDate DATE NOT NULL,
    InspectorName NVARCHAR(200) NOT NULL,
    Result NVARCHAR(50) NOT NULL,
    DefectCount INT NOT NULL,
    Notes NVARCHAR(1000) NULL,
    CONSTRAINT FK_QualityInspection_ManufacturingBatch FOREIGN KEY (BatchID) REFERENCES dbo.ManufacturingBatch(BatchID)
);

CREATE TABLE dbo.Shipment (
    ShipmentID INT NOT NULL PRIMARY KEY,
    BatchID INT NOT NULL,
    ProductID INT NOT NULL,
    PlantID INT NOT NULL,
    DestinationLocationID INT NOT NULL,
    ShipDate DATE NOT NULL,
    DeliveryDate DATE NULL,
    Quantity INT NOT NULL,
    Carrier NVARCHAR(100) NOT NULL,
    Status NVARCHAR(50) NOT NULL,
    CONSTRAINT FK_Shipment_ManufacturingBatch FOREIGN KEY (BatchID) REFERENCES dbo.ManufacturingBatch(BatchID)
);
