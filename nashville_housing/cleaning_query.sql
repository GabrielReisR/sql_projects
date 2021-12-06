----------------------------------------------------------------
-- Show all
----------------------------------------------------------------
SELECT *
FROM NashvilleHousing..data

/* Data cleaninig */
----------------------------------------------------------------
-- Standardize sale date format
----------------------------------------------------------------
-- Seeing target result
SELECT 
	SaleDate,
	CONVERT(Date, SaleDate)
FROM NashvilleHousing..data

-- Adding another column
ALTER TABLE NashvilleHousing..data
ADD SaleDateConverted Date

UPDATE NashvilleHousing..data
SET SaleDateConverted = CONVERT(Date, SaleDate)

-- Seeing final result
SELECT 
	SaleDate,
	SaleDateConverted, -- new column
	CONVERT(Date, SaleDate)
FROM NashvilleHousing..data

----------------------------------------------------------------
-- Populate property address data
----------------------------------------------------------------
SELECT *
FROM NashvilleHousing..data
WHERE PropertyAddress is null

-- There are null values because some owners appear twice. Sometimes, the property address
-- is added on all the owner data lines - sometimes it is not. Let's populate this data.

-- Checking this assumption
SELECT
	a.ParcelID, 
	a.PropertyAddress, 
	b.ParcelID, 
	b.PropertyAddress
FROM NashvilleHousing..data AS a
JOIN NashvilleHousing..data AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ] -- owners are the same, lines are different
WHERE a.PropertyAddress is null

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing..data AS a
JOIN NashvilleHousing..data AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ] -- owners are the same, lines are different
WHERE a.PropertyAddress is null

----------------------------------------------------------------
-- Breaking out PropriertyAddress in two variables: (Address, City)
----------------------------------------------------------------
-- Seeing PropertyAddress column
SELECT PropertyAddress
FROM NashvilleHousing..data

-- Checking PropertyAddress without after comma (Address)
SELECT
	SUBSTRING(
		PropertyAddress, 
		1, 
		CHARINDEX(',', PropertyAddress) - 1) -- one position before (-1) our target (,) 
		AS Address
FROM NashvilleHousing..data

-- Checking PropertyAddress after comma (City)
SELECT
	SUBSTRING(
		PropertyAddress, 
		CHARINDEX(',', PropertyAddress) + 1, -- one position after (+1) our target (,) 
		LEN(PropertyAddress)) -- end of PropertyAddress
		AS City
FROM NashvilleHousing..data

-- Create Address
ALTER TABLE NashvilleHousing..data
ADD PropertySplitAddress nvarchar(255)

UPDATE NashvilleHousing..data
SET PropertySplitAddress = 
		SUBSTRING(
			PropertyAddress,
			1,
			CHARINDEX(',', PropertyAddress) - 1)

-- Create City
ALTER TABLE NashvilleHousing..data
ADD PropertySplitCity nvarchar(255)

UPDATE NashvilleHousing..data
SET PropertySplitCity = 
		SUBSTRING(
			PropertyAddress, 
			CHARINDEX(',', PropertyAddress) + 1, -- one position after (+1) our target (,) 
			LEN(PropertyAddress))

SELECT PropertySplitCity
FROM NashvilleHousing..data

----------------------------------------------------------------
-- Breaking out OwnerAddress in three variables: (Address, City, State)
----------------------------------------------------------------
-- Seeing OwnerAddress column
SELECT OwnerAddress
FROM NashvilleHousing..data

-- Using name parser to divide into three columns
SELECT
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3), -- Address
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2), -- City
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) -- State
FROM NashvilleHousing..data

-- Adding columns Address, City, and State
ALTER TABLE NashvilleHousing..data
ADD OwnerSplitAddress nvarchar(255),
	OwnerSplitCity nvarchar(255),
	OwnerSplitState nvarchar(255)

-- Populating columns
UPDATE NashvilleHousing..data
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- Seeing final result
SELECT OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
FROM NashvilleHousing..data

----------------------------------------------------------------
-- Change Y and N to 'Yes' and 'No' in SoldAsVacant field
----------------------------------------------------------------
-- Counting responses to SoldAsVacant column
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing..data
GROUP BY SoldAsVacant
ORDER BY 2

-- Changing 'Y' to 'Yes' and 'N' to 'No'
SELECT 
	SoldAsVacant,
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM NashvilleHousing..data

-- Updating SoldAsVacant
UPDATE NashvilleHousing..data
SET SoldAsVacant = CASE 
					WHEN SoldAsVacant = 'Y' THEN 'Yes'
					WHEN SoldAsVacant = 'N' THEN 'No'
					ELSE SoldAsVacant
					END

-- Checking final results
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing..data
GROUP BY SoldAsVacant
ORDER BY 2

----------------------------------------------------------------
-- Dealing with duplicate cases
----------------------------------------------------------------
-- Creating CTE to assess row_num
WITH RowNumCTE 
AS(
SELECT
	*,
	ROW_NUMBER() OVER(
		PARTITION BY
			ParcelID,
			PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
		ORDER BY UniqueID) AS row_num
FROM NashvilleHousing..data)
SELECT *
FROM RowNumCTE
WHERE row_num > 1 -- 104 duplicates

-- Creating CTE to DELETE duplicates
WITH RowNumCTE 
AS(
SELECT
	*,
	ROW_NUMBER() OVER(
		PARTITION BY
			ParcelID,
			PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
		ORDER BY UniqueID) AS row_num
FROM NashvilleHousing..data)
DELETE
FROM RowNumCTE
WHERE row_num > 1

-- Assessing CTE again to see our final results
WITH RowNumCTE 
AS(
SELECT
	*,
	ROW_NUMBER() OVER(
		PARTITION BY
			ParcelID,
			PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
		ORDER BY UniqueID) AS row_num
FROM NashvilleHousing..data)
SELECT *
FROM RowNumCTE
WHERE row_num > 1 -- 0 duplicates!

----------------------------------------------------------------
-- Deleting unused columns
----------------------------------------------------------------
-- IMPORTANT: this is generally done in a view

-- Deleting PropriertyAddress & OwnerAddres
ALTER TABLE NashvilleHousing..data
DROP COLUMN
	PropertyAddress,
	OwnerAddress,
	TaxDistrict,
	SaleDate