/* 
  DATA CLEANING IN SQL 

  USING A NASHVILLE HOUSING DATA SET

*/

-- Preview the uploaded data set
SELECT * 
FROM `portfolio1-337505.Nashville_housing.V5`

-- Converting the date into a standard format
SELECT 
  PARSE_DATE('%m/%d/%Y', SaleDate) AS SaleDate2
FROM `portfolio1-337505.Nashville_housing.V5` 

ALTER TABLE `portfolio1-337505.Nashville_housing.V5`
ADD COLUMN SalesDate2 DATE 

UPDATE `portfolio1-337505.Nashville_housing.V5`
SET SalesDate2 = PARSE_DATE('%m/%d/%Y', SaleDate) 

-- Populating the NULL values in the PropertyAddress column
-- Using a SELFJOIN for this
SELECT *
FROM `portfolio1-337505.Nashville_housing.V5`
ORDER BY ParcelID --this will show that there are duplicate entries, which could uncover the missing addresses


-- using a self-join to identify the addresses with duplicates
SELECT 
  selfjoinA.ParcelID, selfjoinA.PropertyAddress, selfjoinB.ParcelID, selfjoinB.PropertyAddress,
  IFNULL(selfjoinA.PropertyAddress, selfjoinB.PropertyAddress) --IFNULL() function lets you return an alternative value if an expression is NULL
FROM `portfolio1-337505.Nashville_housing.V5` AS selfjoinA
JOIN `portfolio1-337505.Nashville_housing.V5` AS selfjoinB
  ON selfjoinA.ParcelID = selfjoinB.ParcelID
  AND selfjoinA.UniqueID != selfjoinB.UniqueID --this ensures uniqueness of the duplication
WHERE SelfjoinA.PropertyAddress IS NULL 


-- Updating the table with the address replacements
UPDATE `portfolio1-337505.Nashville_housing.V5`
SET PropertyAddress = IFNULL(selfjoinA.PropertyAddress, selfjoinB.PropertyAddress)
FROM `portfolio1-337505.Nashville_housing.V5` AS selfjoinA
JOIN `portfolio1-337505.Nashville_housing.V5` AS selfjoinB
  ON selfjoinA.ParcelID = selfjoinB.ParcelID
  AND selfjoinA.UniqueID != selfjoinB.UniqueID --this ensures uniqueness of the duplication
WHERE SelfjoinA.PropertyAddress IS NULL 


-- TESTING: Re-run the self-join block to see if it worked. The query below should return no results
SELECT 
  selfjoinA.ParcelID,selfjoinA.PropertyAddress, selfjoinB.ParcelID, selfjoinB.PropertyAddress,
  IFNULL(selfjoinA.PropertyAddress, selfjoinB.PropertyAddress) --IFNULL() function lets you return an alternative value if an expression is NULL
FROM `portfolio1-337505.Nashville_housing.V5` AS selfjoinA
JOIN `portfolio1-337505.Nashville_housing.V5` AS selfjoinB
  ON selfjoinA.ParcelID = selfjoinB.ParcelID
  AND selfjoinA.UniqueID != selfjoinB.UniqueID --this ensures uniqueness of the duplication
WHERE SelfjoinA.PropertyAddress IS NULL 


-- Parsing the addresses to separate the City as a stand-alone column, to make it more useable 
-- 'safe' prefix returns NULL instead of a error for rows that the command doesn't work
SELECT
  (SPLIT(PropertyAddress, ','))[SAFE_ORDINAL(1)] AS StreetAddy,
  (SPLIT(PropertyAddress, ','))[SAFE_ORDINAL(2)] AS City 
FROM `portfolio1-337505.Nashville_housing.V5`

-- Adding the new split columns to the table
ALTER TABLE `portfolio1-337505.Nashville_housing.V5`
ADD COLUMN StreetAddy STRING

UPDATE `portfolio1-337505.Nashville_housing.V5`
SET StreetAddy = (SPLIT(PropertyAddress, ','))[SAFE_ORDINAL(1)]

ALTER TABLE `portfolio1-337505.Nashville_housing.V5`
ADD COLUMN City STRING

UPDATE `portfolio1-337505.Nashville_housing.V5`
SET City = (SPLIT(PropertyAddress, ','))[SAFE_ORDINAL(2)]

-- Similarly splitting the OwnerAddress to extract the State
SELECT
  (SPLIT(OwnerAddress, ','))[SAFE_ORDINAL(3)] AS State  
FROM `portfolio1-337505.Nashville_housing.V5`

ALTER TABLE `portfolio1-337505.Nashville_housing.V5`
ADD COLUMN State STRING

UPDATE `portfolio1-337505.Nashville_housing.V5`
SET StreetAddy = (SPLIT(OwnerAddress, ','))[SAFE_ORDINAL(3)]

-- Changing Y/N to Yes/No in the 'SoldAsVacant' column, for uniformity
SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM `portfolio1-337505.Nashville_housing.V5`
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
  CASE WHEN SoldAsVacant = 'Y'THEN 'Yes'
       WHEN SoldAsVacant = 'N' THEN 'No'
       ELSE SoldAsVacant
  END
FROM `portfolio1-337505.Nashville_housing.V5`

UPDATE `portfolio1-337505.Nashville_housing.V5`
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y'THEN 'Yes'
                        WHEN SoldAsVacant = 'N' THEN 'No'
                        ELSE SoldAsVacant
END


-- Removing Duplicates using CTE & Windows functions

WITH RowNumCTE AS(
  SELECT *,
    ROW_NUMBER() OVER(
      PARTITION BY ParcelID,
                   PropertyAddress,
                   Saleprice,
                   SaleDate,
                   Legalreference
      ORDER BY UniqueID
    ) row_num
 FROM `portfolio1-337505.Nashville_housing.V5`
)

SELECT *
FROM RowNumCTE 
WHERE row_num > 1
ORDER BY PropertyAddress

-- Deleting the 104 duplicates discovered by previous query
DELETE 
FROM RowNumCTE 
WHERE row_num > 1


