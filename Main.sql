--CREATE THE MASTER LOCKUP TABLES TABLES

CREATE TABLE IF NOT EXISTS asset_types (
    asset_type_id SERIAL PRIMARY KEY,
    asset_type_name VARCHAR(255) NOT NULL,
    asset_description TEXT,
    cia_default_rating VARCHAR(50));

CREATE TABLE IF NOT EXISTS asset_owner (
    owner_id SERIAL PRIMARY KEY,
    owner_anme VARCHAR(255) NOT NULL,
    department VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    owner_role VARCHAR(100),
    owner_status VARCHAR(50));

CREATE TABLE IF NOT EXISTS location_master (
    location_id SERIAL PRIMARY KEY, 
    location_name VARCHAR(255),
    country VARCHAR(100),
    region VARCHAR(100),
    data_residency_zone VARCHAR(100));

CREATE TABLE IF NOT EXISTS threat_actor (
    actor_id SERIAL PRIMARY KEY,
    actor_name VARCHAR(255),
    actor_type VARCHAR(100),
    motivation TEXT,
    sophistication_level VARCHAR(100));

CREATE TABLE IF NOT EXISTS impact_level (
    impact_id SERIAL PRIMARY KEY,
    impact_label VARCHAR(100),
    impact_score INT,
    financial_threshold DECIMAL(15,2),
    impact_description TEXT);

CREATE TABLE IF NOT EXISTS probability_level (
    probability_id SERIAL PRIMARY KEY,
    probability_label VARCHAR(100),
    probability_score INT,
    frequency_description TEXT);

CREATE TABLE IF NOT EXISTS risk_type (
    risk_type_id SERIAL PRIMARY KEY, 
    risk_type_name VARCHAR(100),
    risk_description TEXT);

CREATE TABLE IF NOT EXISTS control_type (
    control_type_id SERIAL PRIMARY KEY,
    control_type_name VARCHAR(100),
    control_description TEXT );

--CREATE PRIMARY TABLES
CREATE TABLE IF NOT EXISTS asset_register (
    asset_id SERIAL PRIMARY KEY,
    asset_name VARCHAR(255),
    FOREIGN KEY (asset_type_id SERIAL) REFERENCES asset_type(asset_type_id),
    FOREIGN KEY (owner_id SERIAL) REFERENCES asset_owner(owner_id),
    FOREIGN KEY (location_id SERIAL) REFERENCES location_master(location_id),
    FOREIGN KEY (parent_asset_id) REFERENCES asset_register(asset_id),
    confidentality_rating VARCHAR(50),
    integrity_rating VARCHAR(50),
    availability_rating VARCHAR(50),
    business_criticality VARCHAR(100),
    asset_status VARCHAR(50),
    onboarded_date DATE);

CREATE TABLE IF NOT EXISTS threat (
    threat_id SERIAL PRIMARY KEY,
    threat_name VARCHAR(255),
    FOREIGN KEY (actor_id SERIAL) REFERENCES threat_actor(actor_id),
    threat_category VARCHAR(100),
    mitre_attack_id VARCHAR(50),
    threat_description TEXT);

CREATE TABLE IF NOT EXISTS vulnerability_db (
    vulnerability_id SERIAL PRIMARY KEY,
    FOREIGN KEY (asset_id SERIAL) REFERENCES asset_register(asset_id),
    cve_reference VARCHAR(50),
    vulnerability_name VARCHAR(255),
    cvss_score DECIMAL(3,1),
    severity VARCHAR(50),
    discovered_date DATE,
    vulnerability_status VARCHAR(50));

CREATE TABLE IF NOT EXISTS control_db (
    control_id SERIAL PRIMARY KEY,
    control_name VARCHAR(255),
    FOREIGN KEY (control_type_id INT) REFERENCES control_type(control_type_id),
    FOREIGN KEY (control_owner_id INT) REFERENCES asset_owner(control_owner_id),
    iso27002_reference VARCHAR(50),
    implementation_status VARCHAR(100),
    effectiveness_rating INT,
    control_db_description TEXT);

--CREATE THE ASSOCIATIVE ENTITIES FOR RISK MANAGEMENT TABLES
