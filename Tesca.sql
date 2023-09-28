
-- SCHEMA CREATION IN Staging
-- this is important to distinquish where data is coming from. 
-- if no schemas are created, data from different sources will lumped together

Use TescaStaging

CREATE SCHEMA retail --for data coming from the OLTP

CREATE SCHEMA hr   --for data coming from CSV

---- SCHEMA CREATION IN EDW
Use [TescaEDW]

CREATE SCHEMA edw --for all data coming from the Staging



---------------LOADING STORE------------------------------------------------------------------------------
-- From OLTP and other sources to Staging

--extract a denormalized data from using the necessary table(s). It may may require combining tables
USE TescaOLTP
SELECT s.StoreID, s.StoreName, s.StreetAddress, c.CityName, st.State, GETDATE() AS LoadDate FROM Store s
INNER JOIN City c ON s.CityID = c.CityID
INNER JOIN	State st ON st.StateID = c.StateID

--moving to the designated schema in Staging
USE TescaStaging

 IF OBJECT_ID ('retail.Store') IS NOT NULL	--before loading data into Staging, truncate it.
 TRUNCATE TABLE retail.Store

CREATE TABLE retail.Store  --schema.tableName
 (
	StoreID INT, 
	StoreName NVARCHAR (50),
	StreetAddress NVARCHAR (50),
	CityName NVARCHAR (50),
	State NVARCHAR (50),
	LoadDate DATETIME DEFAULT GETDATE(),					--to obtain an audit info wrt loading date
	CONSTRAINT retail_store_pk PRIMARY KEY (StoreID)		--make the StoreID the PK, name according to convention schema_table_pk 
 )

 --From Staging to EDW

 --to define the data to be moved from Staging to EDW
 USE TescaStaging

SELECT StoreID, StoreName, StreetAddress, CityName, State FROM retail.Store 

--establish the structure in EDW to receive the data from Staging
 USE TescaEDW

 CREATE TABLE edw.dimStore  --schema.tableName
 (
	StoreSK INT IDENTITY(1, 1),
	StoreID INT,
	StoreName NVARCHAR (50),
	StreetAddress NVARCHAR (50),
	CityName NVARCHAR (50),
	State NVARCHAR (50),
	EffectiveStartDate DATETIME DEFAULT GETDATE(),					--to obtain an audit info wrt loading date
	CONSTRAINT edw_dimStore_sk PRIMARY KEY (StoreSK)		--a surrogate key is introduced as data is moved into the EDW
 )

---------------------------- LOADING PRODUCT ----------------------------------------------------------------------

----Loading STAGING from OLTP

--extract/define the data to be loaded from OLTP into STAGING
USE TescaOLTP
SELECT p.ProductID, p.ProductNumber, p.Product, d.Department, p.UnitPrice, GETDATE() AS LoadDate FROM Product p
INNER JOIN Department d ON p.DepartmentID = d.DepartmentID

USE TescaStaging
 IF OBJECT_ID ('retail.Product') IS NOT NULL	--before loading data into Staging, truncate it.
 TRUNCATE TABLE retail.Product

 --establish a structure in the STAGING where data is to be loaded
CREATE TABLE retail.Product
(
	productID INT,
	productNumber NVARCHAR(50),
	product NVARCHAR(50),
	department NVARCHAR(50),
	UnitPrice FLOAT,
	LoadDate DATETIME DEFAULT GETDATE(),
	CONSTRAINT retail_product_pk PRIMARY KEY (productID)
)

----Loading from STAGING into EDW
--extract/define data to be loaded from STAGING into EDW
USE TescaStaging
SELECT productID, productNumber, product, department, UnitPrice FROM retail.Product

--establish a structure to receive the data in EDW
USE TescaEDW
CREATE TABLE edw.dimProduct
(
	productSK INT IDENTITY (1, 1),
	roductID INT,
	productNumber NVARCHAR(50),
	product NVARCHAR(50),
	department NVARCHAR(50),
	UnitPrice FLOAT,
	EffectiveStartDate DATETIME,
	EffectiveEndDate DATETIME,
	CONSTRAINT edw_product_sk PRIMARY KEY (productSK)
)


------------------------------------ LOADING PROMOTION ----------------------------------------------------

--to define/extract data from OLTP going into the STAGING
USE TescaOLTP
SELECT	
		p.PromotionID, t.Promotion, p.StartDate AS PromoStartDate, 
		p.EndDate AS PromoEndDate, p.DiscountPercent, GETDATE() AS LoadDate 
FROM Promotion p
INNER JOIN PromotionType t ON p.PromotionTypeID = t.PromotionTypeID

USE TescaStaging

IF OBJECT_ID('retail.Promotion') IS NOT NULL
	TRUNCATE TABLE retail.Promotion


CREATE TABLE retail.Promotion
(
	PromotionID INT,
	Promotion NVARCHAR (50),
	PromoStartDate DATE, 
	PromoEndDate DATE, 
	DiscountPercent FLOAT, 
	LoadDate DATETIME DEFAULT GETDATE(),
	CONSTRAINT retail_promotion_pk PRIMARY KEY (PromotionID)
)

--extract/define data from STAGING going to EDW
SELECT PromotionID, Promotion, PromoStartDate, PromoEndDate, DiscountPercent FROM retail.Promotion
--WHERE CAST(LoadDate as DATE) = CAST(GETDATE() AS DATE)  --to further ensure the right data is picked. Today's data

USE TescaEDW

CREATE TABLE edw.dimPromotion
(
	PromotionSK INT IDENTITY(1, 1),
	PromotionID INT,
	Promotion NVARCHAR (50),
	PromoStartDate DATE, 
	PromoEndDate DATE, 
	DiscountPercent FLOAT, 
	EffectiveStartDate DATETIME,
	CONSTRAINT edw_dimPromotion_sk PRIMARY KEY (PromotionSK)
)


------------------------------------ LOADING CUSTOMER ----------------------------------------------------
------Loading from OLTP to STAGING
--Extract/define data to be moved from OLTP into STAGING
--Business rule: Combine LastName (in upper case) and FirstName, LastName first, separate with comma.

USE TescaOLTP
SELECT c.CustomerID, CONCAT_WS(', ', UPPER(c.LastName), c.FirstName) AS CustomerName, c.CustomerAddress, ct.CityName, s.State, GETDATE() AS LoadDate FROM Customer c 
INNER JOIN City ct ON ct.CityID = c.CityID
INNER JOIN State s ON s.StateID = ct.StateID

USE TescaStaging
--Establish a structure in the STAGING to receive incoming data
IF OBJECT_ID('retail.Customer') IS NOT NULL		-- to truncate and load into the STAGING
	TRUNCATE TABLE retail.Customer

CREATE TABLE retail.Customer
(
	CustomerID INT,
	CustomerName NVARCHAR(250),
	CustomerAddress	NVARCHAR(50),
	CityName NVARCHAR(50),
	State NVARCHAR(50),
	LoadDate DATETIME DEFAULT GETDATE(),
	CONSTRAINT retail_customer_pk PRIMARY KEY (CustomerID)
)

-------Loading from STAGING to EDW
--extract/define data to be loaded from STAGING into EDW
USE TescaStaging
SELECT CustomerID, CustomerName, CustomerAddress, CityName, State 
FROM retail.Customer

--establish a structure to receive the incoming data
USE TescaEDW
CREATE TABLE edw.dimCustomer
(
	CustomerSK INT IDENTITY(1, 1),
	CustomerID INT,
	CustomerName NVARCHAR(250),
	CustomerAddress	NVARCHAR(50),
	CityName NVARCHAR(50),
	State NVARCHAR(50),
	EffectiveStartDate DATETIME,
	CONSTRAINT edw_customer_sk PRIMARY KEY (CustomerSK)
)


---------------- LOADING POSChannel--------------------------------------------------------------
----Loading from OLTP into STAGING

--extract/define data to be moved from OLTP
USE TescaOLTP
SELECT ChannelID, ChannelNo, DeviceModel, InstallationDate, SerialNo, GETDATE() AS LoadDate 
FROM POSChannel

--establish a structure to receive the data into STAGING
USE TescaStaging
IF OBJECT_ID('retail.POSChannel') IS NOT NULL
	TRUNCATE TABLE retail.POSChannel

CREATE TABLE retail.POSChannel
(
	ChannelID INT, 
	ChannelNo NVARCHAR(50), 
	DeviceModel NVARCHAR(50), 
	InstallationDate DATE, 
	SerialNo NVARCHAR(50), 
	LoadDate DATETIME DEFAULT GETDATE(),
	CONSTRAINT retail_Poshannel_pk PRIMARY KEY (ChannelID)
)

----Loading From STAGING into EDW
--extract data that would be moved from STAGING into EDW
USE TescaStaging
SELECT ChannelID, ChannelNo, DeviceModel, InstallationDate, SerialNo 
FROM retail.POSChannel

--establish a structure to receive the data in EDW

USE TescaEDW

CREATE TABLE edw.dimPOSChannel
(
	ChannelSK INT IDENTITY(1, 1),
	ChannelID INT, 
	ChannelNo NVARCHAR(50), 
	DeviceModel NVARCHAR(50), 
	InstallationDate DATE, 
	SerialNo NVARCHAR(50), 
	EffectiveStartDate DATETIME,
	EffectiveEndDate DATETIME
	CONSTRAINT edw_dimPoshannel_sk PRIMARY KEY (ChannelSK)
)


-----------------LOADING VENDOR-------------------------------------------------------------------------
--------Loading from OLTP to STAGING
-----extract data to be Load into STAGING from OLTP 
--Business rule: Combine LastName (in upper case) and FirstName, LastName first, separate with comma.
USE TescaOLTP
SELECT v.VendorID, v.VendorNo, CONCAT_WS(', ', UPPER(v.LastName), v.FirstName) AS VendorName, 
v.RegistrationNo, v.VendorAddress, C.CityName, s.State, GETDATE() AS LoadDate 
FROM Vendor v
INNER JOIN City c ON c.CityID = v.CityID
INNER JOIN State s ON s.StateID = C.StateID

--establish a structure in STAGING to receive data from OLTP.
USE TescaStaging
IF OBJECT_ID('retail.Vendor') IS NOT NULL
	TRUNCATE TABLE retail.Vendor

CREATE TABLE retail.Vendor
(
	VendorID INT,
	VendorNo NVARCHAR(50),
	VendorName NVARCHAR(250),
	RegistrationNo NVARCHAR(50),
	VendorAddress NVARCHAR(50),
	CityName NVARCHAR(50),
	State NVARCHAR(50),
	LoadDate DATETIME DEFAULT GETDATE(),
	CONSTRAINT retail_vendor_pk PRIMARY KEY (VendorID)
)

-------Loading from STAGING into EDW
---extract the data to be moved
USE TescaStaging
SELECT VendorID, VendorNo, VendorName, RegistrationNo, VendorAddress, CityName, State 
FROM retail.Vendor 

--establish a struture to receive the data from STAGING
USE TescaEDW
CREATE TABLE edw.dimVendor
(
	VendorSK INT IDENTITY(1, 1),
	VendorID INT,
	VendorNo NVARCHAR(50),
	VendorName NVARCHAR(250),
	RegistrationNo NVARCHAR(50),
	VendorAddress NVARCHAR(50),
	CityName NVARCHAR(50),
	State NVARCHAR(50),
	EffectiveStartDate DATETIME,
	EffectiveEndDate DATETIME
	CONSTRAINT edw_vendor_sk PRIMARY KEY (VendorSK)	
)


--------------------------------LOADING EMPLOYEE-------------------------------------------------------------
-------Loading from OLTP to STAGING
--extract data to be moved
--Business rule: Combine LastName (in upper case) and FirstName, LastName first, separate with comma., DoB as Dateof Birth
USE TescaOLTP
SELECT e.EmployeeID, e.EmployeeNo, CONCAT_WS(', ', UPPER(e.LastName), e.FirstName) AS EmployeeName, 
e.DoB AS DateofBirth, e.MaritalStatus, GETDATE() AS LoadDate FROM Employee e
INNER JOIN MaritalStatus m ON m.MaritalStatusID = e.MaritalStatus   --note: there is a mixup in the design

--establish a structure to receive the incoming data
USE TescaStaging
IF OBJECT_ID('retail.employee') IS NOT NULL
	TRUNCATE TABLE retail.employee

CREATE TABLE retail.employee
(
	EmployeeID INT,
	EmployeeNo NVARCHAR(50),
	EmployeeName NVARCHAR(250),
	DateofBirth DATE,
	MaritalStatus NVARCHAR(50),
	LoadDate DATETIME DEFAULT GETDATE(),
	CONSTRAINT retail_employee_pk PRIMARY KEY (EmployeeID)
)

---------Loading from STAGING to EDW
--extract data to moved
USE TescaStaging
SELECT EmployeeID, EmployeeNo, EmployeeName, DateofBirth, MaritalStatus 
FROM retail.employee

--establish a structure to receive the incoming data
USE TescaEDW
CREATE TABLE edw.dimEmployee
(
	EmployeeSK INT IDENTITY(1, 1),
	EmployeeID INT,
	EmployeeNo NVARCHAR(50),
	EmployeeName NVARCHAR(250),
	DateofBirth DATE,
	MaritalStatus NVARCHAR(50),
	EffectiveStartDate DATETIME,
	EffectiveEndDate DATETIME,
	CONSTRAINT edw_dimEmployee_sk PRIMARY KEY (EmployeeSK)
)


------------------------------LOADING MISCONDUCT-----------------------------------------
--------the source is a CSV and not the OLTP 
----establish a structure in the STAGING to receive data
USE TescaStaging
IF OBJECT_ID('hr.Misconduct') IS NOT NULL
	TRUNCATE TABLE hr.Misconduct

CREATE TABLE hr.Misconduct
(	
	ID INT IDENTITY(1, 1),	--an auto increment ID is generated to cater for any form of irregularity and enable sorting
	misconductID INT,
	misconductDesc NVARCHAR(250),
	LoadDate DATETIME DEFAULT GETDATE()
	CONSTRAINT hr_misconduct_sk PRIMARY KEY (ID)
)

----Loading from STAGING into EDW
--introducing a SK or ROW_NUMBER and applying MAX
USE TescaStaging
SELECT misconductID, misconductDesc FROM hr.Misconduct
WHERE ID IN (SELECT MAX(ID) FROM hr.Misconduct GROUP BY misconductID)

USE TescaEDW
CREATE TABLE edw.dimMisconduct
(
	misconductSK INT IDENTITY(1, 1),
	misconductID INT,
	misconductDesc NVARCHAR(250),
	EffectiveStartDate DATETIME,
	CONSTRAINT edw_dimMisconduct_sk PRIMARY KEY (misconductSK)
)


---------------------------- LOADING DECISION-----------------------------------------------------

--------Loading from SOURCE(CSV) to STAGING
----establish a structure in the STAGING to receive data
USE TescaStaging
IF OBJECT_ID('hr.Misconduct') IS NOT NULL
	TRUNCATE TABLE hr.Misconduct

CREATE TABLE hr.Decision
(	
	DecisionID INT,
	Decision NVARCHAR(250),
	LoadDate DATETIME DEFAULT GETDATE()
	CONSTRAINT hr_decision_pk PRIMARY KEY (DecisionID)
)

----Loading from STAGING into EDW
--extract data to be moved
USE TescaStaging
SELECT DecisionID, Decision FROM hr.Decision

--establsih a structure to receive the incoming data
USE TescaEDW
CREATE TABLE edw.dimDecision
(	
	DecisionSK INT IDENTITY(1, 1),
	DecisionID INT,
	Decision NVARCHAR(250),
	EffectiveStartDate DATETIME,
	CONSTRAINT edw_dimDecision_sk PRIMARY KEY (DecisionSK)
)


------------------------------LOADING ABSENT-----------------------------------------------------

--------Loading from SOURCE(CSV) to STAGING
----establish a structure in the STAGING to receive data

USE TescaStaging
IF OBJECT_ID('hr.Absent') IS NOT NULL
	TRUNCATE TABLE hr.Absent

CREATE TABLE hr.Absent
(	
	CategoryID INT,
	Category NVARCHAR(250),
	LoadDate DATETIME DEFAULT GETDATE()
	CONSTRAINT hr_absent_pk PRIMARY KEY (CategoryID)
)

----Loading from STAGING into EDW
--extract data to be moved
USE TescaStaging
SELECT CategoryID, Category 
FROM hr.Absent

--establsih a structure to receive the incoming data
USE TescaEDW
CREATE TABLE edw.dimAbsent
(	
	CategorySK INT IDENTITY(1, 1),
	CategoryID INT,
	Category NVARCHAR(250),
	EffectiveStartDate DATETIME,
	CONSTRAINT edw_dimAbsent_sk PRIMARY KEY (CategorySK)
)

---------------------------------CREATE A DIM FOR TIME----------------------------------------
---Time and Date are created as standards
--moved directly into the EDW

USE TescaEDW
CREATE TABLE edw.dimTime
(
	TimeSK INT IDENTITY (1, 1),
	DayHour INT,
	DayPeriod NVARCHAR(50),
	DailyDayHour NVARCHAR(50),
	WeekendDayHour NVARCHAR(50),
	EffectiveStartDate DATETIME,
	CONSTRAINT edw_dimTime_sk PRIMARY KEY (TimeSK)
)

/*Biz rules:
	Hour = 0 - 23
	DayPeriod  0=Midnight, 1-4 = Early hour, 5 - 11 = Morning, 12 = Noon, 13 - 17 = Afternoon, 18 - 20 = Evening, 21 - 23 = Night
	DailyHour 0 - 6 = Closed, 7 to 18 = Open, 19 - 23 = Closed
	WeekendDayHour 0 - 2 = Closed, 3 - 21 = Open, 22 - 23 = Closed
*/
CREATE PROCEDURE edw.spTimeGenerator
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @StartHour INT = 0

	IF OBJECT_ID('edw.dimTime') IS NOT NULL
		TRUNCATE TABLE edw.dimTime

		WHILE @StartHour <= 23
			BEGIN
				INSERT INTO edw.dimTime(DayHour, DayPeriod, DailyDayHour, WeekendDayHour, EffectiveStartDate)
					SELECT	
						@StartHour AS DayHour,
						CASE 
							WHEN @StartHour = 0 THEN 'Midnight' 
							WHEN @StartHour >= 1 AND @StartHour <= 4 THEN 'EarlyHour'
							WHEN @StartHour >= 5 AND @StartHour <= 11 THEN 'EarlyHour'
							WHEN @StartHour = 12 THEN 'Noon'
							WHEN @StartHour >= 13 AND @StartHour <= 17 THEN 'Afternoon'
							WHEN @StartHour >= 18 AND @StartHour <= 20 THEN 'Evening'
							WHEN @StartHour >= 21 AND @StartHour <= 23 THEN 'Night'
						END AS DayPeriod,
						CASE 
							WHEN @StartHour >= 0 AND @StartHour <= 6 THEN 'Closed'
							WHEN @StartHour >= 7 AND @StartHour <= 18 THEN 'Open'
							WHEN @StartHour >= 19 AND @StartHour <= 23 THEN 'Closed'
						END AS DailyHour,
						CASE 
							WHEN @StartHour >= 0 AND @StartHour <= 2 THEN 'Closed'
							WHEN @StartHour >= 3 AND @StartHour <= 21 THEN 'Open'
							WHEN @StartHour >= 22 AND @StartHour <= 23 THEN 'Closed'
						END AS WeekendDayHour,
						GETDATE() AS EffectiveStartDate
	
					SELECT @StartHour += 1
			END
END

EXEC edw.spTimeGenerator

SELECT * FROM edw.dimTime

---------------------------------CREATE A DIMDATE----------------------------------------
--moved directly into the EDW


USE TescaEDW
CREATE TABLE edw.dimDate
(
	DateKey INT,
	BusinessDate DATE,
	BusinessYear INT,
	BusinessMonth INT,
	BusinessDay INT,
	EnglishMonth NVARCHAR (50),
	EnglishDayOfWeek NVARCHAR (50),
	BusinessQuarter NVARCHAR (2),
	FrenchMonth NVARCHAR (50),
	FrenchDayOfWeek NVARCHAR (50),
	EffectiveStartDate DATETIME,
	
	CONSTRAINT edw_dim_date_sk PRIMARY KEY (DateKey)
)

SELECT * FROM edw.dimDate

ALTER PROCEDURE edw.spGenerateCalender (@GenerateYear INT)
AS 
BEGIN
	SET NOCOUNT ON;
	IF OBJECT_ID ('edw.dimDate') IS NOT NULL
		TRUNCATE TABLE edw.dimDate
	--to determine the start date from available data
	DECLARE @StartDate DATE = 
						(
							SELECT MIN(CONVERT(DATE, TransDate)) FROM TescaOLTP.dbo.SalesTransaction
								UNION
							SELECT MIN(CONVERT(DATE, TransDate)) FROM TescaOLTP.dbo.PurchaseTransaction
						)
	DECLARE @EndDate DATE
	DECLARE @NoOfDays INT
	DECLARE @CurrentDayNo INT = 0
	DECLARE @CurrentDate DATE
	SELECT @StartDate = DATEADD(YEAR, -1, @StartDate)
	SELECT @EndDate = DATEADD(YEAR, @GenerateYear, DATEFROMPARTS(YEAR(GETDATE()), 12, 31)) --the last term is just to ensure the last date is the end of 70 years time
	SELECT @NoOfDays = DATEDIFF(DAY, @StartDate, @EndDate)
	--SELECT @StartDate, @EndDate, @NoOfDays
	WHILE @CurrentDayNo <= @NoOfDays
		BEGIN
			SELECT @CurrentDate = DATEADD(DAY, @CurrentDayNo, @StartDate)
			INSERT INTO edw.dimDate(DateKey, BusinessDate, BusinessYear, BusinessMonth, BusinessDay, EnglishMonth,
									EnglishDayofWeek, BusinessQuarter, FrenchMonth, FrenchDayOfWeek, EffectiveStartDate)
			SELECT	CONVERT(NVARCHAR(8), @CurrentDate,112) AS DateKey, @CurrentDate AS BusinessDate, YEAR(@CurrentDate) AS BusinessYear,
					DATEPART(MONTH, @CurrentDate) AS BusinessMonth, DATENAME(DAY, @CurrentDate) AS BusinessDay, DATENAME(MONTH, @CurrentDate) AS EnglishMonth, 
					DATENAME(DW, @CurrentDate) AS EnglishDayofWeek, CONCAT('Q',DATEPART(Q, @CurrentDate)) AS BusinessQuarter,

					CASE DATEPART(MONTH, @CurrentDate)
						WHEN 1 THEN 'janvier' WHEN 2 THEN 'février'WHEN 3 THEN 'mars' WHEN 4 THEN 'avril' WHEN 5 THEN 'mai' WHEN 6 THEN 'juin'
						WHEN 7 THEN 'juillet' WHEN 8 THEN 'août'WHEN 9 THEN 'septembre' WHEN 10 THEN 'octobre' WHEN 11 THEN 'novembre' WHEN 12 THEN 'décembre'
					END AS FrenchMonth,

					CASE DATEPART(WEEKDAY, @CurrentDate)
						WHEN 1 THEN 'dimanche' WHEN 2 THEN 'lundi' WHEN 3 THEN 'mardi' WHEN 4 THEN 'mercredi' 
						WHEN 5 THEN 'jeudi' WHEN 6 THEN 'vendredi' WHEN 7 THEN 'samedi' 
					END AS FrenchDayOfWeek,
				
					GETDATE() AS EffectiveStartDate
					 
			SELECT @CurrentDayNo += 1 
		END
END

SELECT	CONVERT(NVARCHAR(8), GETDATE() ,112)

--to execute the stored procedure
EXEC edw.spGenerateCalender 20

--to query the table
SELECT * FROM [edw].[dimDate]


------------------------------------------------------LOADING SALES ANALYSIS FACT TABLE--------------------------
--to check the min and max dates
/*USE TescaOLTP
SELECT MIN(TransDate), MAX(TransDate) FROM SalesTransaction
SELECT * FROM SalesTransaction WHERE CONVERT(DATE, TransDate) = '2023-09-23'
--The available data is not up to date, for this purpose of this project, the date is shifted by 2 years to have data for processing
UPDATE SalesTransaction
SET TransDate = DATEADD(YEAR, 2, TransDate),
	OrderDate = DATEADD(YEAR, 2, OrderDate),
	DeliveryDate = DATEADD(YEAR, 2, DeliveryDate)
*/

------Loading into STAGING
--define what to be moved from the OLTP into STAGING
USE TescaOLTP

IF (SELECT COUNT(*) FROM TescaEDW.edw.Fact_SalesAnalysis) = 0  --if nothing in the table, use this to start from begining of transaction to n-1
	SELECT 
		TransactionID, TransactionNO, CONVERT(DATE, TransDate) AS TransDate, DATEPART(HOUR, TransDate) AS TransHour,
		CONVERT(DATE, OrderDate) as OrderDate, DATEPART(HOUR, OrderDate) AS OrderHour, CONVERT(DATE, DeliveryDate) AS DeliveryDate,
		ChannelID, CustomerID, EmployeeID, ProductID, StoreID, PromotionID, Quantity, LineAmount 
	FROM SalesTransaction
	WHERE CONVERT(DATE, TransDate) <= CONVERT(DATE, DATEADD(DAY, -1, GETDATE())) 
ELSE --load n - 1 (delta loading). i.e., if table already has record(s), use this for delta loading
	SELECT 
		TransactionID, TransactionNO, CONVERT(DATE, TransDate) AS TransDate, DATEPART(HOUR, TransDate) AS TransHour,
		CONVERT(DATE, OrderDate) as OrderDate, DATEPART(HOUR, OrderDate) AS OrderHour, CONVERT(DATE, DeliveryDate) AS DeliveryDate,
		ChannelID, CustomerID, EmployeeID, ProductID, StoreID, PromotionID, Quantity, LineAmount 
	FROM SalesTransaction
	WHERE CONVERT(DATE, TransDate) = CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))


--establish a structure to receive the data in the STAGING
USE TescaStaging

IF OBJECT_ID ('retail.SalesTransaction') IS NOT NULL
	TRUNCATE TABLE retail.SalesTransaction

CREATE TABLE retail.SalesAnalysis
(
	TransactionID INT,
	TransactionNO NVARCHAR(50),
	TransDate DATE,
	TransHour INT,
	OrderDate DATE,
	OrderHour INT,
	DeliveryDate DATE,
	ChannelID INT,
	CustomerID INT,
	EmployeeID INT,
	ProductID INT,
	StoreID INT,
	PromotionID INT,
	Quantity FLOAT,
	LineAmount FLOAT,
	LoadDate DATETIME,
	CONSTRAINT retail_SalesTransaction_pk PRIMARY KEY (TransactionID)
)

------Loading into the EDW from STAGING
---define the data to be moved from STAGING
--Loading the fact table: SK of itself and associated dimensions, DD, metrics/facts and Audit information 
USE TescaStaging
SELECT
	TransactionID, TransactionNO, TransDate, TransHour, OrderDate, OrderHour, DeliveryDate, ChannelID, 
	CustomerID, EmployeeID, ProductID, StoreID, PromotionID, Quantity, LineAmount
FROM retail.SalesTransaction

--establish a structure to receive the data in the EDW
USE TescaEDW
CREATE TABLE edw.Fact_SalesAnalysis
(
	SalesAnalysisSK INT IDENTITY(1, 1),
	TransactionNO NVARCHAR(50),
	TransDateSK INT,
	TransHourSK INT,
	OrderDateSK INT,
	OrderhourSK INT,
	DeliveryDateSK INT,
	ChannelSK INT,
	CustomerSK INT,
	SalePersonSK INT,
	ProductSK INT,
	StoreSK INT,
	PromotionSK INT,
	Quantity FLOAT,
	LineAmount FLOAT,
	LoadDate DATETIME,
	CONSTRAINT edw_fact_SalesAnalysis_sk PRIMARY KEY (SalesAnalysisSK),
	CONSTRAINT fact_SalesAnalysis_TransDate_sk FOREIGN KEY (TransDateSK) REFERENCES edw.dimDate (DateKey),
	CONSTRAINT fact_SalesAnalysis_TransHour_sk FOREIGN KEY (TransHourSK) REFERENCES edw.dimTime (TimeSK),
	CONSTRAINT fact_SalesAnalysis_OrderDate_sk FOREIGN KEY (OrderDateSK) REFERENCES edw.dimDate (DateKey),
	CONSTRAINT fact_SalesAnalysis_OrderHour_sk FOREIGN KEY (OrderHourSK) REFERENCES edw.dimTime (TimeSK),
	CONSTRAINT fact_SalesAnalysis_DeliveryDate_sk FOREIGN KEY (DeliveryDateSK) REFERENCES edw.dimDate (DateKey),
	CONSTRAINT fact_SalesAnalysis_Channel_sk FOREIGN KEY (ChannelSK) REFERENCES edw.dimPOSChannel (ChannelSK),
	CONSTRAINT fact_SalesAnalysis_Customer_sk FOREIGN KEY (CustomerSK) REFERENCES edw.dimCustomer (CustomerSK),
	CONSTRAINT fact_SalesAnalysis_Employee_sk FOREIGN KEY (SalePersonSK) REFERENCES edw.dimEmployee (EmployeeSK),
	CONSTRAINT fact_SalesAnalysis_Product_sk FOREIGN KEY (ProductSK) REFERENCES edw.dimProduct (ProductSK),
	CONSTRAINT fact_SalesAnalysis_Store_sk FOREIGN KEY (StoreSK) REFERENCES edw.dimStore (StoreSK),
	CONSTRAINT fact_SalesAnalysis_Promotion_sk FOREIGN KEY (PromotionSK) REFERENCES edw.dimPromotion (PromotionSK)
)


-----------------------------------------LOADING PURCHASE ANALYSIS FACT TABLE -------------------------------------------------------------
--shifting data by 2 years
USE TescaOLTP
/*UPDATE PurchaseTransaction
SET
	TransDate = DATEADD(YEAR, 2, TransDate),
	OrderDate = DATEADD(YEAR, 2, OrderDate),
	DeliveryDate = DATEADD(YEAR, 2, DeliveryDate),
	ShipDate = DATEADD(YEAR, 2, ShipDate)
*/
SELECT * FROM PurchaseTransaction


---extract/define the data to be moved from OLTP into STAGING
USE TescaOLTP
IF (SELECT COUNT(*) FROM TescaEDW.edw.fact_PurchaseAnalysis) = 0
	SELECT
		TransactionID, TransactionNO, CONVERT(DATE, Transdate) AS Transdate, CONVERT(DATE, OrderDate) AS OrderDate, CONVERT(DATE, DeliveryDate) AS DeliveryDate,
		CONVERT(DATE, ShipDate) AS ShipDate, VendorID, EmployeeID, ProductID, StoreID, Quantity, LineAmount, DATEDIFF(DAY, OrderDate, DeliveryDate) + 1 AS DiffDays
	FROM PurchaseTransaction
	WHERE CONVERT(DATE, TransDate) <= DATEADD(DAY, -1, CONVERT(DATE, GETDATE()))
ELSE
	SELECT
		TransactionID, TransactionNO, CONVERT(DATE, Transdate) AS Transdate, CONVERT(DATE, OrderDate) AS OrderDate, CONVERT(DATE, DeliveryDate) AS DeliveryDate,
		CONVERT(DATE, ShipDate) AS ShipDate, VendorID, EmployeeID, ProductID, StoreID, Quantity, LineAmount, DATEDIFF(DAY, OrderDate, DeliveryDate) + 1 AS DiffDays
	FROM PurchaseTransaction
	WHERE CONVERT(DATE, TransDate) = DATEADD(DAY, -1, CONVERT(DATE, GETDATE()))


--Etablish a structure to receive data in STAGING
USE TescaStaging

IF OBJECT_ID ('retail.PurhaseAnalysis') IS NOT NULL
	TRUNCATE TABLE retail.PurhaseAnalysis

CREATE TABLE retail.PurhaseAnalysis
(
	TransactionID INT,
	TransactionNO NVARCHAR (50),
	TransDate DATE,
	OrderDate DATE,
	DeliveryDate DATE,
	ShipDate DATE,
	VendorID INT,
	EmployeeID INT,
	ProductID INT,
	StoreID INT,
	Quantity FLOAT,
	LineAmount FLOAT,
	DiffDays INT,
	CONSTRAINT retail_PurhaseAnalysis_pk PRIMARY KEY (TransactionID)
)

----define data to be moved from STAGING to EDW
SELECT 
	TransactionID, TransactionNO, TransDate, OrderDate, DeliveryDate, ShipDate, 
	VendorID, EmployeeID, ProductID, StoreID, Quantity, LineAmount, DiffDays
FROM retail.PurchaseAnalysis


USE TescaEDW
CREATE TABLE edw.Fact_PurchaseAnalysis
(
	PurchaseAnalysisSK INT IDENTITY(1, 1),
	TransactionNO NVARCHAR(50),
	TransDateSK INT,
	OrderDateSK INT,
	DeliveryDateSK INT,
	ShipDateSK INT, 
	VendorSK INT,
	PurchaserSK INT,
	ProductSK INT,
	StoreSK INT,
	Quantity FLOAT,
	LineAmount FLOAT,
	DiffDays INT,
	LoadDate DATETIME,
	CONSTRAINT edw_fact_PurchaseAnalysis_sk PRIMARY KEY (PurchaseAnalysisSK),
	CONSTRAINT fact_PurchaseAnalysis_TransDate_sk FOREIGN KEY (TransDateSK) REFERENCES edw.dimDate (DateKey),
	CONSTRAINT fact_PurchaseAnalysis_OrderDate_sk FOREIGN KEY (OrderDateSK) REFERENCES edw.dimDate (DateKey),
	CONSTRAINT fact_PurchaseAnalysis_DeliveryDate_sk FOREIGN KEY (DeliveryDateSK) REFERENCES edw.dimDate (DateKey),
	CONSTRAINT fact_PurchaseAnalysis_ShipDate_sk FOREIGN KEY (ShipDateSK) REFERENCES edw.dimDate (DateKey),
	CONSTRAINT fact_PurchaseAnalysis_Vendor_sk FOREIGN KEY (VendorSK) REFERENCES edw.dimVendor (VendorSK),
	CONSTRAINT fact_PurchaseAnalysis_PurchasePerson_sk FOREIGN KEY (PurchaserSK) REFERENCES edw.dimEmployee (EmployeeSK),
	CONSTRAINT fact_PurchaseAnalysis_Product_sk FOREIGN KEY (ProductSK) REFERENCES edw.dimProduct (ProductSK),
	CONSTRAINT fact_PurchaseAnalysis_Store_sk FOREIGN KEY (StoreSK) REFERENCES edw.dimStore (StoreSK),
)


---------------------------------------------LOADING OVERTIME--------------------------------------------------------

--Loading from CSV to STAGING
USE TescaStaging
IF OBJECT_ID ('hr.Overtime') IS NOT NULL
	TRUNCATE TABLE hr.Overtime

CREATE TABLE hr.Overtime
(
	OvertimeID INT,
	EmployeeNo NVARCHAR(50),
	FirstName NVARCHAR(50),
	LastName NVARCHAR(50),
	StartOvertime DATETIME,
	EndOvertime DATETIME,
	LoadDate DATETIME DEFAULT GETDATE(),
	CONSTRAINT hr_Overtime_Overtime_pk PRIMARY KEY (OvertimeID)
)

--Loading from STAGING into EDW

SELECT 
	EmployeeNo, CONVERT(DATE, StartOvertime) AS StartOvertimeDate, DATEPART(HOUR, StartOvertime) AS StartOvertimeHour,
	CONVERT(DATE, EndOvertime) AS EndOvertimeDate, DATEPART(HOUR, EndOvertime) AS EndOvertimeHour
FROM hr.Overtime

USE TescaEDW
CREATE TABLE edw.fact_OvertimeAnalysis
(
	OvertimeAnalysisSK INT IDENTITY (1, 1),
	EmployeeSK INT,
	StartOvertimeDateSK INT,
	StartOvertimeHourSK INT,
	EndOvertimeDateSK INT,
	EndOvertimeHourSK INT,
	LoadDate DATETIME,
	CONSTRAINT Fact_OvertimeAnalysis_SK PRIMARY KEY (OvertimeAnalysisSK),
	CONSTRAINT Fact_OvertimeAnalysis_Employee_SK FOREIGN KEY (EmployeeSK) REFERENCES edw.dimEmployee (EmployeeSK),
	CONSTRAINT Fact_OvertimeAnalysis_StartOvertimeDate_SK FOREIGN KEY (StartOvertimeDateSK) REFERENCES edw.dimDate (DateKey),
	CONSTRAINT Fact_OvertimeAnalysis_StartOvertimeHour_SK FOREIGN KEY (StartOvertimeHourSK) REFERENCES edw.dimTime (TimeSK),
	CONSTRAINT Fact_OvertimeAnalysis_EndOvertimeDate_SK FOREIGN KEY (EndOvertimeDateSK) REFERENCES edw.dimDate (DateKey),
	CONSTRAINT Fact_OvertimeAnalysis_EndOvertimeDateHour_SK FOREIGN KEY (EndOvertimeHourSK) REFERENCES edw.dimTime (TimeSK)
)

----------------------------------------LOADING ABSENCE DATA --------------------------------------------------------
---To be loaded into the STAGING from CSV

USE TescaStaging
IF OBJECT_ID('hr_Absent') IS NOT NULL
	TRUNCATE TABLE hr.AbsentAnalysis

CREATE TABLE hr.AbsentAnalysis
(
	AbsentID INT IDENTITY(1 ,1),
	EmpID INT,
	Store INT,
	Absent_Date DATE,
	Absent_Category INT,
	Absent_Hour INT,
	LoadDate DATETIME,
	CONSTRAINT hr_AbsentAnalysis_Absent_pk PRIMARY KEY (AbsentID)
)

--Biz rule: The first entry of absence data for a day is the right record to be retained
--There is a need for deduplication
SELECT EmpID, Store, Absent_Date, Absent_Category, Absent_Hour FROM hr.AbsentAnalysis
WHERE AbsentID IN (SELECT MIN(AbsentID) FROM hr.AbsentAnalysis GROUP BY EmpID, Store, Absent_Date, Absent_Category)

---To load EDW
USE TescaEDW

CREATE TABLE edw.Fact_AbsentAnalysis
(
	AbsentAnalysisSK INT IDENTITY(1, 1),
	EmployeeSK INT,
	StoreSK INT,
	Absent_DateSK INT,
	Absent_CategorySK INT,
	Absent_HourSK INT,
	LoadDate DATETIME

	CONSTRAINT Fact_AbsentAnalysis_SK PRIMARY KEY (AbsentAnalysisSK),
	CONSTRAINT Fact_AbsentAnalysis_Employee_SK FOREIGN KEY (EmployeeSK) REFERENCES edw.dimEmployee (EmployeeSK),
	CONSTRAINT Fact_AbsentAnalysis_Store_SK FOREIGN KEY (StoreSK) REFERENCES edw.dimStore (StoreSK),
	CONSTRAINT Fact_AbsentAnalysis_Absent_SK FOREIGN KEY (Absent_DateSK) REFERENCES edw.dimDate (Datekey),
	CONSTRAINT Fact_AbsentAnalysis_Absent_Category_SK FOREIGN KEY (Absent_CategorySK) REFERENCES edw.dimAbsent (CategorySK),
	CONSTRAINT Fact_AbsentAnalysis_Absent_Hour_SK FOREIGN KEY (Absent_HourSK) REFERENCES edw.dimTime (TimeSK)
)


---------------------------------------------LOADING MISCONDUCT DATA -------------------------------------------------
--Loading into STAGING
USE TescaStaging
IF OBJECT_ID('hr.MisconductAnalysis') IS NOT NULL
	TRUNCATE TABLE hr.MisconductAnalysis

CREATE TABLE hr.MisconductAnalysis
(
	MisconductPK INT IDENTITY(1, 1),
	EmpID INT,
	StoreID INT,
	Miscomduct_Date DATE,
	Misconduct_ID INT,
	Descision_ID INT,
	CONSTRAINT hr_MisconductAnalysis_PK PRIMARY KEY (MisconductPK)
)

--Loading into EDW
--define data to be moved from STAGING to EDW
--there is need for deduplication
SELECT EmpID, StoreID, Misconduct_Date, Misconduct_ID, Decision_ID FROM hr.MisconductAnalysis
WHERE MisconductPK IN (SELECT MAX(MisconductPK) FROM hr.MisconductAnalysis GROUP BY EmpID, StoreID, Misconduct_Date, Misconduct_ID)

--establish a structure to receive the incoming data
USE TescaEDW
CREATE TABLE edw.Fact_MisconductAnalysis
(
	MisconductAnalysisSK INT IDENTITY(1, 1),
	EmployeeSK INT,
	StoreSK INT,
	MisconductDateSK INT,
	MisconductSK INT, 
	DecisionSK INT,
	LoadDate DATETIME,
	CONSTRAINT Fact_MisconductAnalysis_SK PRIMARY KEY (MisconductAnalysisSK),
	CONSTRAINT Fact_MisconductAnalysis_Employee_SK FOREIGN KEY (EmployeeSK) REFERENCES edw.dimEmployee (EmployeeSK),
	CONSTRAINT Fact_MisconductAnalysis_Store_SK FOREIGN KEY (StoreSK) REFERENCES edw.dimStore (StoreSK),
	CONSTRAINT Fact_MisconductAnalysis_MisconductDate_SK FOREIGN KEY (MisconductDateSK) REFERENCES edw.dimDate (DateKey),
	CONSTRAINT Fact_MisconductAnalysis_Misconduct_SK FOREIGN KEY (MisconductSK) REFERENCES edw.dimMisconduct (MisconductSK),
	CONSTRAINT Fact_MisconductAnalysis_Decision_SK FOREIGN KEY (DecisionSK) REFERENCES edw.dimDecision (DecisionSK)
)

