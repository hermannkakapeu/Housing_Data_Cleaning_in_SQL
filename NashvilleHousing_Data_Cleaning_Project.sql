/*
Cleaning an processing Data with SQL Queries
*/

select * from Housing
order by ParcelID


--****************************************************************************************************************

-- Standardize Date Format

select SaleDate, convert(date, SaleDate) as standardDate
from Housing

alter table Housing
add standardDate Date;

update Housing 
set standardDate = convert(date, SaleDate)

select SaleDate, standardDate
from Housing

--****************************************************************************************************************

-- Populate Property Address data

select x1.[UniqueID ], x1.ParcelID, x1.PropertyAddress, x2.[UniqueID ], x2.ParcelID, x2.PropertyAddress
from Housing as x1 Join Housing as x2
on x1.ParcelID=x2.ParcelID
where x2.PropertyAddress is null and x1.[UniqueID ]<> x2.[UniqueID ]
order by 2

update x2
set PropertyAddress = ISNULL(x1.PropertyAddress,x2.PropertyAddress)
from Housing as x1 Join Housing as x2
on x1.ParcelID=x2.ParcelID and x1.[UniqueID ]<> x2.[UniqueID ]
where x2.PropertyAddress is null 
--order by 2

select *
from Housing
where PropertyAddress is null


-- ****************************************************************************************************

-- Breaking out Address into Individual Columns (Address, City, State)
/*
Here we used :
CHARINDEX, SUBSTRING, PARSENAME, REPLACE.
*/

select PropertyAddress
from Housing

select PropertyAddress,
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Adress,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, len(PropertyAddress)) as City
from Housing

with cte1 as (
select PropertyAddress,
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Adress,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, len(PropertyAddress)) as City
from Housing
)

select PropertyAddress,
SUBSTRING(Adress, CHARINDEX(' ', Adress)+1, len(Adress)) as State
from cte1


alter table Housing
add SplitAressCity Nvarchar(50);

update Housing
set SplitAressCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, len(PropertyAddress))


select SplitAressCity
from Housing

Select OwnerAddress
From Housing

Select OwnerAddress,
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From Housing

alter table Housing
add SplitOwnerAdress Nvarchar(255);

alter table Housing
add SplitOwnerState Nvarchar(255);

update Housing
set SplitOwnerAdress=PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)    

update Housing
set SplitOwnerState=PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)


select OwnerAddress, SplitOwnerAdress, SplitOwnerState
from Housing
where OwnerAddress is not null


--*******************************************************************************************************

-- Change Y and N to Yes and No in "Sold as Vacant" field

Select distinct(SoldAsVacant), COUNT(SoldAsVacant)
from Housing
group by SoldAsVacant
order by 2


Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From Housing
--where SoldAsVacant<>'No' or SoldAsVacant<>'Yes'


Update Housing
SET SoldAsVacant = CASE 
						When SoldAsVacant = 'Y' THEN 'Yes'
						When SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
				   END
				   
--*************************************************************************************************************

-- Remove Duplicates
/*
It is not a good practice to delete actual data, it will rather be a better thing 
to put it in a temp table and keep it but never delete.

Her are two others options to remove duplicates:
SELECT DISTINCT column1, column2, ...
FROM your_table;

SELECT column1, column2, ...
FROM your_table
GROUP BY column1, column2, ...;
*/

SELECT ParcelID, SalePrice, LegalReference
FROM Housing
GROUP BY ParcelID, SalePrice, LegalReference;

-- using CTE with ROW_NUMBER()
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From Housing
--order by ParcelID
)
delete
From RowNumCTE
Where row_num > 1
--Order by PropertyAddress



Select *
From Housing


--***********************************************************************************************************

-- Delete Unused Columns

Select *
From Housing


ALTER TABLE Housing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

--**************************************************************************************************************

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--- Importing Data using OPENROWSET and BULK INSERT	

--  More advanced and looks cooler, but have to configure server appropriately to do correctly
--  Wanted to provide this in case you wanted to try it


--sp_configure 'show advanced options', 1;
--RECONFIGURE;
--GO
--sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--GO


--USE PortfolioProject 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

--GO 


---- Using BULK INSERT

--USE PortfolioProject;
--GO
--BULK INSERT nashvilleHousing FROM 'C:\Temp\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv'
--   WITH (
--      FIELDTERMINATOR = ',',
--      ROWTERMINATOR = '\n'
--);
--GO


---- Using OPENROWSET
--USE PortfolioProject;
--GO
--SELECT * INTO nashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\alexf\OneDrive\Documents\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
--GO



