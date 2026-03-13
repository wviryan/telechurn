--------- FOR TESTABILITY ---------

DROP VIEW IF EXISTS analysis_master;

DROP PROCEDURE IF EXISTS add_customer;

DROP TABLE IF EXISTS customers_raw;
DROP TABLE IF EXISTS zip_codes_raw;

DROP TABLE IF EXISTS customer_choices;
DROP TABLE IF EXISTS customer_financials;
DROP TABLE IF EXISTS churn_outcomes;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS locations;

DROP TYPE IF EXISTS OFFER_TYPE;
DROP TYPE IF EXISTS CHURN_CATEGORY_TYPE;
DROP TYPE IF EXISTS CHURN_REASON_TYPE;

--------- REQUIRED ENUMS ---------

CREATE TYPE CHURN_CATEGORY_TYPE AS ENUM(
	'Competitor',
	'Dissatisfaction',
	'Other',
	'Price',
	'Attitude'
);

CREATE TYPE CHURN_REASON_TYPE AS ENUM(
	'Competitor had better devices',
	'Product dissatisfaction',
	'Network reliability',
	'Limited range of services',
	'Competitor made better offer',
	'Don''t know',
	'Long distance charges',
	'Attitude of service provider',
	'Attitude of support person',
	'Competitor offered higher download speeds',
	'Competitor offered more data',
	'Lack of affordable download/upload speed',
	'Deceased',
	'Moved',
	'Service dissatisfaction',
	'Price too high',
	'Lack of self-service on Website',
	'Poor expertise of online support',
	'Extra data charges',
	'Poor expertise of phone support'
);

CREATE TYPE OFFER_TYPE AS ENUM(
	'None',
	'Offer E',
	'Offer D',
	'Offer A',
	'Offer B',
	'Offer C'
);

--------- SCHEMA CREATION ---------

CREATE TABLE IF NOT EXISTS customers_raw(
	customer_id VARCHAR(50) PRIMARY KEY,
	gender VARCHAR(50) NOT NULL CHECK (gender IN ('Male', 'Female')),
	age INT NOT NULL CHECK (age >= 18),
	married BOOLEAN NOT NULL,
	number_of_dependents INT NOT NULL,
	city VARCHAR(50) NOT NULL,
	zip_code VARCHAR(5) NOT NULL CHECK (LENGTH(zip_code) = 5),
	latitude DECIMAL(11,8) NOT NULL,
	longitude DECIMAL(11,8) NOT NULL,
	number_of_referrals INT,
	tenure_in_months INT NOT NULL,
	offer OFFER_TYPE NOT NULL,
	phone_service BOOLEAN NOT NULL,
	average_monthly_long_distance_charges DECIMAL(10,2),
	multiple_lines BOOLEAN,
	internet_service BOOLEAN NOT NULL,
	internet_type VARCHAR(50) CHECK (internet_type IN ('Cable', 'DSL', 'Fiber Optic')),
	average_monthly_gb_download INT,
	online_security BOOLEAN,
	online_backup BOOLEAN,
	device_protection_plan BOOLEAN,
	premium_tech_support BOOLEAN,
	streaming_tv BOOLEAN,
	streaming_movies BOOLEAN,
	streaming_music BOOLEAN,
	unlimited_data BOOLEAN,
	contract VARCHAR(50) NOT NULL CHECK (contract IN ('Month-to-Month', 'One Year', 'Two Year')),
	paperless_billing BOOLEAN NOT NULL,
	payment_method VARCHAR(50) NOT NULL CHECK (payment_method IN ('Bank Withdrawal', 'Credit Card', 'Mailed Check')),
	monthly_charge DECIMAL(10,2) NOT NULL,
	total_charges DECIMAL(10,2),
	total_refunds DECIMAL(10,2),
	total_extra_data_charges DECIMAL(10,2),
	total_long_distance_charges DECIMAL(10,2),
	total_revenue DECIMAL(10,2),
	customer_status VARCHAR(50) NOT NULL CHECK (customer_status IN ('Churned', 'Joined', 'Stayed')),
	churn_category CHURN_CATEGORY_TYPE,
	churn_reason CHURN_REASON_TYPE
);

CREATE TABLE IF NOT EXISTS zip_codes_raw(
	zip_code VARCHAR(5) PRIMARY KEY CHECK (LENGTH(zip_code) = 5),
	population INT
);

--------- DATA INGESTION ---------

/*
	Update file locations according to your files before running!
*/
COPY customers_raw
FROM 'C:\teledata\customers.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'WIN1252');

COPY zip_codes_raw
FROM 'C:\teledata\zipcodes.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'WIN1252');

--------- FOREIGN KEYS ---------

ALTER TABLE customers_raw
ADD CONSTRAINT fk_zip_code FOREIGN KEY (zip_code) REFERENCES zip_codes_raw(zip_code) ON DELETE CASCADE;

--------- CONTROL ---------

SELECT *
FROM customers_raw
LIMIT 10;

SELECT *
FROM zip_codes_raw
LIMIT 10;

--------- DATA NORMALIZATION: Customers ---------

CREATE TABLE IF NOT EXISTS customers(
	customer_id VARCHAR(50) PRIMARY KEY,
	gender VARCHAR(50) NOT NULL CHECK (gender IN ('Male', 'Female')),
	age INT NOT NULL CHECK (age >= 18),
	married BOOLEAN NOT NULL,
	number_of_dependents INT NOT NULL,
	zip_code VARCHAR(5) NOT NULL,
	number_of_referrals INT,
	tenure_in_months INT NOT NULL
);

INSERT INTO customers (customer_id, gender, age, married, number_of_dependents, zip_code, number_of_referrals, tenure_in_months)
SELECT customer_id, gender, age, married, number_of_dependents, zip_code, number_of_referrals, tenure_in_months
FROM customers_raw;

--------- DATA NORMALIZATION: Customer Choices ---------

CREATE TABLE IF NOT EXISTS customer_choices(
	customer_id VARCHAR(50) PRIMARY KEY,
	offer OFFER_TYPE NOT NULL,
	phone_service BOOLEAN NOT NULL,
	multiple_lines BOOLEAN,
	internet_service BOOLEAN NOT NULL,
	internet_type VARCHAR(50) CHECK (internet_type IN ('Cable', 'DSL', 'Fiber Optic')),
	online_security BOOLEAN,
	online_backup BOOLEAN,
	device_protection_plan BOOLEAN,
	premium_tech_support BOOLEAN,
	streaming_tv BOOLEAN,
	streaming_movies BOOLEAN,
	streaming_music BOOLEAN,
	unlimited_data BOOLEAN,
	contract VARCHAR(50) NOT NULL CHECK (contract IN ('Month-to-Month', 'One Year', 'Two Year')),
	paperless_billing BOOLEAN NOT NULL,
	payment_method VARCHAR(50) NOT NULL CHECK (payment_method IN ('Bank Withdrawal', 'Credit Card', 'Mailed Check'))
);

INSERT INTO customer_choices (customer_id, offer, phone_service, multiple_lines, internet_service, internet_type, online_security, online_backup, device_protection_plan, premium_tech_support, streaming_tv, streaming_movies, streaming_music, unlimited_data, contract, paperless_billing, payment_method)
SELECT customer_id, offer, phone_service, multiple_lines, internet_service, internet_type, online_security, online_backup, device_protection_plan, premium_tech_support, streaming_tv, streaming_movies, streaming_music, unlimited_data, contract, paperless_billing, payment_method
FROM customers_raw;

--------- DATA NORMALIZATION: Customer Financials ---------

CREATE TABLE IF NOT EXISTS customer_financials(
	customer_id VARCHAR(50) PRIMARY KEY,
	average_monthly_long_distance_charges DECIMAL(10,2),
	average_monthly_gb_download INT,
	monthly_charge DECIMAL(10,2) NOT NULL,
	total_charges DECIMAL(10,2),
	total_refunds DECIMAL(10,2),
	total_extra_data_charges DECIMAL(10,2),
	total_long_distance_charges DECIMAL(10,2),
	total_revenue DECIMAL(10,2)
);

INSERT INTO customer_financials (customer_id, average_monthly_long_distance_charges, average_monthly_gb_download, monthly_charge, total_charges, total_refunds, total_extra_data_charges, total_long_distance_charges, total_revenue)
SELECT customer_id, average_monthly_long_distance_charges, average_monthly_gb_download, monthly_charge, total_charges, total_refunds, total_extra_data_charges, total_long_distance_charges, total_revenue
FROM customers_raw;

--------- DATA NORMALIZATION: Locations ---------

CREATE TABLE IF NOT EXISTS locations(
    zip_code VARCHAR(5) PRIMARY KEY,
    city VARCHAR(50),
    latitude DECIMAL(11,8),
    longitude DECIMAL(11,8),
    population INT
);

/*
	Selecting all possible zip code values from the zip codes table
	Joining them with information on the customers table
*/

INSERT INTO locations (
	zip_code,
	city,
	latitude,
	longitude,
	population
	)
SELECT DISTINCT 
	z.zip_code,
	c.city,
	c.latitude,
	c.longitude,
	z.population
FROM zip_codes_raw z
LEFT JOIN customers_raw c ON z.zip_code = c.zip_code;

--------- DATA NORMALIZATION: Churn Outcomes ---------

CREATE TABLE IF NOT EXISTS churn_outcomes (
	customer_id VARCHAR(50) PRIMARY KEY,
	customer_status VARCHAR(50) NOT NULL CHECK (customer_status IN ('Churned', 'Joined', 'Stayed')),
	churn_category CHURN_CATEGORY_TYPE,
	churn_reason CHURN_REASON_TYPE
);

INSERT INTO churn_outcomes (
	customer_id,
	customer_status,
	churn_category,
	churn_reason
	)
SELECT
	customer_id,
	customer_status,
	churn_category,
	churn_reason
FROM customers_raw;

--------- Master Analysis View ---------

CREATE OR REPLACE VIEW analysis_master AS
SELECT
	-- Customer table
	c.customer_id,
	gender,
	age,
	married,
	number_of_dependents,
	c.zip_code,
	tenure_in_months,
	number_of_referrals,

	-- Locations table
	city,

	-- Customer Choices table
	offer,
	phone_service,
	multiple_lines,
	internet_service,
	internet_type,
	online_security,
	online_backup,
	device_protection_plan,
	premium_tech_support,
	streaming_tv,
	streaming_movies,
	streaming_music,
	unlimited_data,
	contract,
	paperless_billing,
	payment_method,
	
	-- Customer Financials table
	average_monthly_gb_download,
	average_monthly_long_distance_charges,
	monthly_charge,
	total_charges,
	total_refunds,
	total_extra_data_charges,
	total_long_distance_charges,
	total_revenue,

	-- Churn Outcomes table
	customer_status,
	churn_category,
	churn_reason
	
FROM customers c
LEFT JOIN locations l ON c.zip_code = l.zip_code
LEFT JOIN customer_choices choices ON c.customer_id = choices.customer_id
LEFT JOIN customer_financials f ON c.customer_id = f.customer_id
LEFT JOIN churn_outcomes o ON c.customer_id = o.customer_id;

--------- DATA NORMALIZATION: Foreign Keys ---------

ALTER TABLE customers
ADD CONSTRAINT fk_zip_code FOREIGN KEY (zip_code) REFERENCES locations(zip_code) ON DELETE SET NULL;

ALTER TABLE customer_choices
ADD CONSTRAINT fk_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE;

ALTER TABLE customer_financials
ADD CONSTRAINT fk_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE;

ALTER TABLE churn_outcomes
ADD CONSTRAINT fk_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE;

--------- CONTROL ---------

SELECT *
FROM customers
LIMIT 10;

SELECT *
FROM customer_choices
LIMIT 10;

SELECT *
FROM customer_financials
LIMIT 10;

SELECT *
FROM locations
LIMIT 10;

SELECT *
FROM churn_outcomes
LIMIT 10;

SELECT *
FROM analysis_master
LIMIT 10;

--------- DATA INTEGRITY ---------

ALTER TABLE customer_choices
ADD CONSTRAINT internet_service_logic CHECK (
	(internet_service) 
	OR 
	(
	NOT internet_service
	AND internet_type IS NULL
	AND online_security IS NULL
	AND online_backup IS NULL
	AND device_protection_plan IS NULL
	AND premium_tech_support IS NULL
	AND streaming_tv IS NULL
	AND streaming_movies IS NULL
	AND streaming_music IS NULL
	AND unlimited_data IS NULL)
);

/*
	Note: churn category and reason can be null because some users do not fill them when churning
*/
ALTER TABLE churn_outcomes
ADD CONSTRAINT churn_logic CHECK (
	(	customer_status IN ('Stayed', 'Joined') 
		AND churn_category IS NULL 
		AND churn_reason IS NULL
	)
	OR 
	(	customer_status = 'Churned')
);

--------- INDEXES ---------

/*
	Faster query times for later use
*/
CREATE INDEX idx_churn_status ON churn_outcomes(customer_status);

--------- DATA INSERTION ---------

CREATE OR REPLACE PROCEDURE add_customer(
    -- General
    p_customer_id VARCHAR(50),
    p_zip_code VARCHAR(5),
    
    -- Customer table (required)
    p_gender VARCHAR(50),
    p_age INT,
    p_married BOOLEAN,

	-- Customer Financials (required)
	p_monthly_charge DECIMAL(10,2),

	-- Locations table
    p_city VARCHAR(50),
    p_latitude DECIMAL(11,8),
    p_longitude DECIMAL(11,8),
    p_population INT,

	-- Customer table
	p_number_of_dependents INT DEFAULT 0,
	p_number_of_referrals INT DEFAULT 0,
    p_tenure_in_months INT DEFAULT 0,

    -- Customer Choices table
    p_offer OFFER_TYPE DEFAULT 'None'::OFFER_TYPE,
    p_phone_service BOOLEAN DEFAULT FALSE,
    p_multiple_lines BOOLEAN DEFAULT FALSE,
    p_internet_service BOOLEAN DEFAULT FALSE,
    p_internet_type VARCHAR(50) DEFAULT NULL,
    p_online_security BOOLEAN DEFAULT NULL,
    p_online_backup BOOLEAN DEFAULT NULL,
    p_device_protection_plan BOOLEAN DEFAULT NULL,
    p_premium_tech_support BOOLEAN DEFAULT NULL,
    p_streaming_tv BOOLEAN DEFAULT NULL,
    p_streaming_movies BOOLEAN DEFAULT NULL,
    p_streaming_music BOOLEAN DEFAULT NULL,
    p_unlimited_data BOOLEAN DEFAULT NULL,
    p_contract VARCHAR(50) DEFAULT NULL,
    p_paperless_billing BOOLEAN DEFAULT FALSE,
    p_payment_method VARCHAR(50) DEFAULT NULL,

    -- Customer Financials
	p_average_monthly_long_distance_charges DECIMAL(10,2) DEFAULT 0,
    p_avg_gb INT DEFAULT 0,
    p_total_charges DECIMAL(10,2) DEFAULT 0,
    p_total_refunds DECIMAL(10,2) DEFAULT 0,
    p_extra_data_charges DECIMAL(10,2) DEFAULT 0,
    p_long_distance_charges DECIMAL(10,2) DEFAULT 0,
    p_total_revenue DECIMAL(10,2) DEFAULT 0,

	-- Churn Outcomes table
	p_customer_status VARCHAR(50) DEFAULT 'Joined'
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- 1. Locations (Handled first to avoid FK violations, with conflict check)
    INSERT INTO locations (zip_code, city, latitude, longitude, population)
    VALUES (p_zip_code, p_city, p_latitude, p_longitude, p_population)
    ON CONFLICT (zip_code) DO NOTHING;

    -- 2. Customers
    INSERT INTO customers (customer_id, gender, age, married, number_of_dependents, zip_code, number_of_referrals, tenure_in_months)
    VALUES (p_customer_id, p_gender, p_age, p_married, p_number_of_dependents, p_zip_code, p_number_of_referrals, p_tenure_in_months);

    -- 3. Choices
    INSERT INTO customer_choices (customer_id, offer, phone_service, multiple_lines, internet_service, internet_type, online_security, online_backup, device_protection_plan, premium_tech_support, streaming_tv, streaming_movies, streaming_music, unlimited_data, contract, paperless_billing, payment_method)
    VALUES (p_customer_id, p_offer, p_phone_service, p_multiple_lines, p_internet_service, p_internet_type, p_online_security, p_online_backup, p_device_protection_plan, p_premium_tech_support, p_streaming_tv, p_streaming_movies, p_streaming_music, p_unlimited_data, p_contract, p_paperless_billing, p_payment_method);

    -- 4. Financials
	INSERT INTO customer_financials (customer_id, average_monthly_long_distance_charges, average_monthly_gb_download, monthly_charge, total_charges, total_refunds, total_extra_data_charges, total_long_distance_charges, total_revenue)
	VALUES (p_customer_id, p_average_monthly_long_distance_charges, p_avg_gb, p_monthly_charge, p_total_charges, p_total_refunds, p_extra_data_charges, p_long_distance_charges, p_total_revenue);

    -- 5. Outcomes
    INSERT INTO churn_outcomes (customer_id, customer_status)
    VALUES (p_customer_id, p_customer_status);

EXCEPTION
WHEN unique_violation THEN
	RAISE EXCEPTION 'Customer % already exists.', p_customer_id;
WHEN foreign_key_violation THEN
	RAISE EXCEPTION 'FK violation inserting customer %. Check zip_code and dependencies.', p_customer_id;
WHEN OTHERS THEN
	RAISE EXCEPTION 'Unexpected error for customer %: %', p_customer_id, SQLERRM;
END; $$;

/*
	Example usage
*/
CALL add_customer(
    p_customer_id       => '0007-BOND',
    p_zip_code          => '34000',
    p_gender            => 'Male',
    p_age               => 56,
    p_married           => FALSE,
    p_contract          => 'Month-to-Month',
    p_payment_method    => 'Credit Card',
    p_monthly_charge    => 75.83,
    p_customer_status   => 'Joined',
    p_city              => 'Istanbul',
    p_latitude          => 41.00820000,
    p_longitude         => 28.97840000,
    p_population        => 16000000
);

SELECT *
FROM customers
WHERE customer_id = '0007-BOND';

SELECT *
FROM customer_choices
WHERE customer_id = '0007-BOND';

SELECT *
FROM customer_financials
WHERE customer_id = '0007-BOND';

SELECT *
FROM churn_outcomes
WHERE customer_id = '0007-BOND';

SELECT *
FROM locations
WHERE city = 'Istanbul';