/*
  Fabric SQL database (Caldova_SQLDatabase) BusinessApplication schema.
  Mirrors BusinessApplication/CustomerDetails.json and CustomerAddress.json.
  The caldova-businessapp-ingest Logic App re-runs this file's statements on every
  invocation (guarded by OBJECT_ID checks) before loading rows from blob storage.
*/

IF OBJECT_ID('dbo.CustomerDetails', 'U') IS NULL
CREATE TABLE dbo.CustomerDetails (
    CustomerID INT NOT NULL PRIMARY KEY,
    CustomerName NVARCHAR(200) NOT NULL,
    Email NVARCHAR(320) NOT NULL,
    Phone NVARCHAR(50) NOT NULL,
    Segment NVARCHAR(100) NOT NULL,
    AccountManager NVARCHAR(200) NOT NULL,
    CreatedDate DATE NOT NULL
);

IF OBJECT_ID('dbo.CustomerAddress', 'U') IS NULL
CREATE TABLE dbo.CustomerAddress (
    AddressID INT NOT NULL PRIMARY KEY,
    CustomerID INT NOT NULL,
    AddressLine1 NVARCHAR(200) NOT NULL,
    City NVARCHAR(100) NOT NULL,
    State NVARCHAR(100) NOT NULL,
    PostalCode NVARCHAR(20) NOT NULL,
    Country NVARCHAR(100) NOT NULL,
    AddressType NVARCHAR(50) NOT NULL,
    CONSTRAINT FK_CustomerAddress_CustomerDetails FOREIGN KEY (CustomerID) REFERENCES dbo.CustomerDetails(CustomerID)
);
