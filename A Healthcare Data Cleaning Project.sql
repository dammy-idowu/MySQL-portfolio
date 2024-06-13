					/*HEALTHCARE DATA CLEANING PROJECT   
Data source: Kaggle  
Dataset link: https://www.kaggle.com/datasets/prasad22/healthcare-dataset*/

-- IMPORTING RAW DATA 

-- Create new schema and import raw data using the table import wizard
-- Select schema
USE patient_data;

-- View original dataset after import 
SELECT *
FROM `patient record`;

-- Create clone of original dataset framework for analysis
CREATE TABLE `patient_info`
LIKE `patient record`;

-- Copy raw data from original database to cloned database for analysis
INSERT patient_info
SELECT *
FROM `patient record`;

-- DATASET OVERVIEW

-- View all in dataset
SELECT *
FROM patient_info;

-- View columns
DESCRIBE patient_info;
/* Name, Age, Gender, Blood Type, Medical Condition, Date of Admission, Doctor, Hospital
Insurance Provider, Billing Amount, Room Number, Admission Type, Discharge Date
Medication, Test Results*/

-- View column datatypes
SELECT DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = "patient_data" AND TABLE_NAME = 'patient_info'; 
-- 17 rows returned
-- Date of Admission and Discharge date columns have type error (TEXT datatype inplace of DATE)

-- Unique value in Billing amount column                                    
SELECT `Billing Amount`  
FROM patient_info
LIMIT 10;
-- The billing amount having 10 decimal places is unnecessary

-- Unique value in name column    
SELECT name   
FROM patient_info
LIMIT 10;
-- inconsistent capitalization 

-- Unique value in hospital column    
SELECT DISTINCT(hospital)
FROM patient_info;
-- There are some unnecessary commas at the beginning and end of string

-- Check for missing values
SELECT *
FROM patient_info
WHERE Name IS NULL
	OR Age IS NULL
	OR Gender IS NULL
	OR `Blood Type` IS NULL
	OR `Medical Condition` IS NULL
	OR `Date of Admission` IS NULL
	OR Doctor IS NULL
	OR Hospital IS NULL
	OR `Insurance Provider` IS NULL
	OR `Billing Amount` IS NULL
	OR `Room Number` IS NULL
	OR `Admission Type` IS NULL
	OR `Discharge Date` IS NULL
	OR `Medication` IS NULL
	OR `Test Results` IS NULL;
-- No NULL values

-- Check for duplicates
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY `Name`,Age, Gender, `Blood Type`, `Medical Condition`, `Date of Admission`,	Doctor, 
Hospital, `Insurance Provider`, `Billing Amount`, `Room Number`, `Admission Type`, `Discharge Date`, Medication,	`Test Results`
) AS row_num
FROM patient_info;

-- Identify duplicate using CTE
WITH duplicate_patient_info AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY `Name`,Age, Gender, `Blood Type`, `Medical Condition`, `Date of Admission`,	Doctor, 
Hospital, `Insurance Provider`, `Billing Amount`, `Room Number`, `Admission Type`, `Discharge Date`, Medication,	`Test Results`
) AS row_num
FROM patient_info
)
SELECT *
FROM duplicate_patient_info
WHERE row_num > 1;
-- 534 rows returned
-- There are 534 duplicate rows in the dataset


-- DATA CLEANING

-- View table
SELECT *
FROM patient_info;

-- FIX STRUCTURAL ERROR 
-- Split Name column into two (first and last name)
SELECT SUBSTRING_INDEX(`name`,' ', 1) AS first_name,
       SUBSTRING_INDEX(`name`,' ', -1) AS last_name
	   FROM patient_info;
-- 55500 rows returned

-- Add new columns (first and last name) to schema table
ALTER TABLE patient_info
ADD COLUMN `first name` VARCHAR(20) AFTER `name`,
ADD COLUMN `last name` VARCHAR(20) AFTER `first name`;

-- Insert values in new columns
UPDATE patient_info
SET `first name` = SUBSTRING_INDEX(`name`,' ', 1)
WHERE `first name` IS NULL;
UPDATE patient_info
SET `last name` = SUBSTRING_INDEX(`name`,' ', -1)
WHERE `last name` IS NULL;

-- Fix capitalization inconsistency
UPDATE patient_info
SET `first name` = CONCAT(UCASE(SUBSTRING(`first name`, 1, 1)), LOWER(SUBSTRING(`first name`, 2)));
-- 53929 rows affected

UPDATE patient_info
SET `last name` = CONCAT(UCASE(SUBSTRING(`last name`, 1, 1)), LOWER(SUBSTRING(`last name`, 2)));
-- 53929 rows affected

-- Fix extra character (',') error in hospital column
UPDATE patient_info
SET hospital = TRIM(BOTH ',' FROM hospital);
-- 4776 rows affected

-- Assign billing amount to two decimal places
UPDATE patient_info
SET `Billing Amount` = ROUND(`Billing Amount`, 2); 
-- 55500 rows affected

-- REMOVE DUPLICATE DATA
-- Patient_info table was cloned in order to delete duplicate from CTE

CREATE TABLE `patient_information` (
  `Name` text,
  `first name` varchar(20) DEFAULT NULL,
  `last name` varchar(20) DEFAULT NULL,
  `Age` int DEFAULT NULL,
  `Gender` text,
  `Blood Type` text,
  `Medical Condition` text,
  `Date of Admission` text,
  `Doctor` text,
  `Hospital` text,
  `Insurance Provider` text,
  `Billing Amount` double DEFAULT NULL,
  `Room Number` int DEFAULT NULL,
  `Admission Type` text,
  `Discharge Date` text,
  `Medication` text,
  `Test Results` text,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- New table created 
INSERT INTO `patient_information`
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY `Name`,Age, Gender, `Blood Type`, `Medical Condition`, `Date of Admission`,	Doctor, 
Hospital, `Insurance Provider`, `Billing Amount`, `Room Number`, `Admission Type`, `Discharge Date`, Medication,	`Test Results`
) AS row_num
FROM patient_info;

-- Duplicate row deleted from CTE
SELECT *
FROM `patient_information`
WHERE row_num > 1;
-- 534 rows returned

DELETE
FROM `patient_information`
WHERE row_num > 1;
-- 534 duplicate rows are deleted

SELECT *
FROM `patient_information`;
--  54966 rows returned

-- STANDARDIZE DATA (TYPE CONVERSION ERROR)
ALTER TABLE patient_information
MODIFY COLUMN `Date of Admission` DATE;
-- 54966 rows returned

ALTER TABLE patient_information
MODIFY COLUMN `Discharge Date` DATE;
-- 54966 rows returned

-- REMOVE IRRELEVANT DATA
-- Name and row_num column are no longer relevant in this table
ALTER TABLE `patient_information`
DROP COLUMN `Name`,
DROP COLUMN `row_num`,
DROP COLUMN `Room Number`;
-- 3 columns removed
