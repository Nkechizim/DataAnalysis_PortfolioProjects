-- Data Cleaning in SQL
SELECT * FROM nashville_housing;


-- Convert Datetime format to Date
SELECT 
	sale_date2,
	DATE(sale_date),
	sale_date
FROM nashville_housing;

ALTER TABLE nashville_housing
ADD COLUMN sale_date2 DATE;

UPDATE nashville_housing
SET sale_date2 = DATE(sale_date);


-- Populate Null Property Address Data
SELECT 
	DISTINCT housing1.parcel_id,
	housing1.property_address,
	housing2.parcel_id,
	housing2.property_address,
	COALESCE(housing1.property_address, housing2.property_address)
FROM nashville_housing AS housing1
JOIN nashville_housing AS housing2 
	ON housing1.parcel_id = housing2.parcel_id
	AND housing1.unique_id != housing2.unique_id
WHERE housing1.property_address IS NULL;

UPDATE nashville_housing AS housing1
SET property_address = housing2.property_address
FROM nashville_housing AS housing2
WHERE housing1.parcel_id = housing2.parcel_id
	AND housing1.unique_id != housing2.unique_id
	AND housing1.property_address IS NULL;


-- Breaking out Property Address into Individual Columns (Address & City)
ALTER TABLE nashville_housing
ADD COLUMN property_address1 VARCHAR(50);

UPDATE nashville_housing
SET property_address1 = SUBSTRING(property_address, 1, POSITION(',' IN property_address) -1);

ALTER TABLE nashville_housing
ADD COLUMN property_city VARCHAR(50);

UPDATE nashville_housing
SET property_city = SUBSTRING(property_address, POSITION(',' IN property_address) +1, LENGTH(property_address));


-- Breaking out Owner Address into Individual Columns (Address, City, State)
ALTER TABLE nashville_housing
ADD COLUMN owner_address1 VARCHAR(50);

UPDATE nashville_housing
SET owner_address1 = SPLIT_PART(owner_address, ',', 1);

ALTER TABLE nashville_housing
ADD COLUMN owner_city VARCHAR(50);

UPDATE nashville_housing
SET owner_city = SPLIT_PART(owner_address, ',', 2);

ALTER TABLE nashville_housing
ADD COLUMN owner_state VARCHAR(50);

UPDATE nashville_housing
SET owner_state = SPLIT_PART(owner_address, ',', 3);


-- Change Y and N to Yes and No in SoldAsVacant Field
UPDATE nashville_housing
SET sold_as_vacant = 
CASE sold_as_vacant
	WHEN 'Y' THEN 'Yes'
	WHEN 'N' THEN 'No'
	ELSE sold_as_vacant
END;


-- Trim Extra Whitespaces in Text Fields (land use, owner name, tax district)
UPDATE nashville_housing
SET land_use = TRIM(land_use)

UPDATE nashville_housing
SET owner_name = TRIM(owner_name)

UPDATE nashville_housing
SET tax_discrit = TRIM(tax_discrit)


-- Cleaning Land Use Field
SELECT DISTINCT land_use, COUNT(land_use)
FROM nashville_housing
GROUP BY land_use
ORDER BY land_use;

UPDATE nashville_housing
SET land_use =
CASE land_use
	WHEN 'VACANT RESIENTIAL LAND' THEN 'VACANT RESIDENTIAL LAND'
	WHEN 'VACANT RES LAND' THEN 'VACANT RESIDENTIAL LAND'
	ELSE land_use
END;


-- Check if Total Value is equal to Land Value + Building Value
-- Noticed Some Discrepancies between Total Values and the addition of Land & Building Values
SELECT 
	land_value, 
	building_value, 
	total_value, 
	(land_value + building_value),
	NULLIF(total_value, (land_value + building_value))
FROM nashville_housing
WHERE NULLIF(total_value, (land_value + building_value)) IS NOT NULL;


-- Remove Duplicate Rows
-- Step 1: Identify Duplicates
WITH row_num_cte AS (
	SELECT
		ROW_NUMBER() OVER(
		PARTITION BY parcel_id,
			property_address,
			sale_price,
			sale_date,
			legal_reference
			ORDER BY unique_id
		) AS row_num,
		*
	FROM nashville_housing
	ORDER BY parcel_id
)

SELECT *
FROM row_num_cte
WHERE row_num > 1;

-- Step 2: Create Temp Table to Store Clean Data without Duplicates
CREATE TEMP TABLE IF NOT EXISTS temp_nashvile_housing_no_duplicates(LIKE nashville_housing);

INSERT INTO temp_nashvile_housing_no_duplicates(
	WITH row_num_cte AS (
		SELECT
			ROW_NUMBER() OVER(
			PARTITION BY parcel_id,
				property_address,
				sale_price,
				sale_date,
				legal_reference
				ORDER BY unique_id
			) AS row_num,
			*
		FROM nashville_housing
		ORDER BY parcel_id
	)

	SELECT 
		unique_id, parcel_id, land_use, 
		property_address, sale_date, sale_price, 
		legal_reference, sold_as_vacant, owner_name, 
		owner_address, acreage, tax_discrit, land_value, 
		building_value, total_value, year_built, bedrooms, 
		full_bath, half_bath, sale_date2, property_address1, 
		property_city, owner_address1, owner_city, owner_state
	FROM row_num_cte
	WHERE row_num = 1
);

SELECT * FROM temp_nashvile_housing_no_duplicates;


-- Drop Unused Columns in Temp Table
ALTER TABLE temp_nashvile_housing_no_duplicates
DROP property_address, 
DROP sale_date, 
DROP owner_address;

---- Rename Some Columns in Temp Table
ALTER TABLE temp_nashvile_housing_no_duplicates
RENAME sale_date2 TO sale_date;

ALTER TABLE temp_nashvile_housing_no_duplicates
RENAME property_address1 TO property_address;

ALTER TABLE temp_nashvile_housing_no_duplicates
RENAME owner_address1 TO owner_address;