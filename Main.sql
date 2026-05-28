-- 1. MASTER LOOKUP TABLES
-- ============================================================================

CREATE TABLE IF NOT EXISTS asset_types (
    asset_type_id SERIAL PRIMARY KEY,
    asset_type_name VARCHAR(255) NOT NULL,
    asset_description TEXT,
    cia_default_rating VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS asset_owner (
    owner_id SERIAL PRIMARY KEY,
    owner_name VARCHAR(255) NOT NULL, 
    department VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    owner_role VARCHAR(100),
    owner_status VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS location_master (
    location_id SERIAL PRIMARY KEY, 
    location_name VARCHAR(255),
    country VARCHAR(100),
    region VARCHAR(100),
    data_residency_zone VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS threat_actor (
    actor_id SERIAL PRIMARY KEY,
    actor_name VARCHAR(255),
    actor_type VARCHAR(100),
    motivation TEXT,
    sophistication_level VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS impact_level (
    impact_id SERIAL PRIMARY KEY,
    impact_label VARCHAR(100),
    impact_score INT,
    financial_threshold DECIMAL(15,2),
    impact_description TEXT
);

CREATE TABLE IF NOT EXISTS probability_level (
    probability_id SERIAL PRIMARY KEY,
    probability_label VARCHAR(100),
    probability_score INT,
    frequency_description TEXT
);

CREATE TABLE IF NOT EXISTS risk_type (
    risk_type_id SERIAL PRIMARY KEY, 
    risk_type_name VARCHAR(100),
    risk_description TEXT
);

CREATE TABLE IF NOT EXISTS control_type (
    control_type_id SERIAL PRIMARY KEY,
    control_type_name VARCHAR(100),
    control_description TEXT 
);

-- 2. PRIMARY DATA TABLES
-- ============================================================================

CREATE TABLE IF NOT EXISTS asset_register (
    asset_id SERIAL PRIMARY KEY,
    asset_name VARCHAR(255),
    asset_type_id INT,
    owner_id INT,
    location_id INT,
    parent_asset_id INT,
    confidentality_rating VARCHAR(50),
    integrity_rating VARCHAR(50),
    availability_rating VARCHAR(50),
    business_criticality VARCHAR(100),
    asset_status VARCHAR(50),
    onboarded_date DATE,
    FOREIGN KEY (asset_type_id) REFERENCES asset_types(asset_type_id),
    FOREIGN KEY (owner_id) REFERENCES asset_owner(owner_id),
    FOREIGN KEY (location_id) REFERENCES location_master(location_id),
    FOREIGN KEY (parent_asset_id) REFERENCES asset_register(asset_id)
);

CREATE TABLE IF NOT EXISTS threat (
    threat_id SERIAL PRIMARY KEY,
    threat_name VARCHAR(255),
    actor_id INT,
    threat_category VARCHAR(100),
    mitre_attack_id VARCHAR(50),
    threat_description TEXT,
    FOREIGN KEY (actor_id) REFERENCES threat_actor(actor_id)
);

CREATE TABLE IF NOT EXISTS vulnerability_db (
    vulnerability_id SERIAL PRIMARY KEY,
    asset_id INT,
    cve_reference VARCHAR(50),
    vulnerability_name VARCHAR(255),
    cvss_score DECIMAL(3,1),
    severity VARCHAR(50),
    discovered_date DATE,
    vulnerability_status VARCHAR(50),
    FOREIGN KEY (asset_id) REFERENCES asset_register(asset_id)
);

CREATE TABLE IF NOT EXISTS control_db (
    control_id SERIAL PRIMARY KEY,
    control_name VARCHAR(255),
    control_type_id INT,
    control_owner_id INT,
    iso27002_reference VARCHAR(50),
    implementation_status VARCHAR(100),
    effectiveness_rating INT,
    control_db_description TEXT,
    FOREIGN KEY (control_type_id) REFERENCES control_type(control_type_id),
    FOREIGN KEY (control_owner_id) REFERENCES asset_owner(owner_id)
);


-- 3. RISK ARCHITECTURE TABLES
-- ============================================================================

CREATE TABLE IF NOT EXISTS risk_register (
    risk_id SERIAL PRIMARY KEY,
    risk_title VARCHAR(255) NOT NULL,
    risk_type_id INT,
    asset_id INT,
    threat_id INT,
    vulnerability_id INT,
    inherent_impact_id INT,
    inherent_probability_id INT,
    residual_impact_id INT,
    residual_probability_id INT,
    risk_owner_id INT,
    inherent_risk_score INT,
    residual_risk_score INT,
    identified_date DATE,
    next_review_date DATE,
    status VARCHAR(50),
    -- Foreign Key constraints matching image configurations
    FOREIGN KEY (risk_type_id) REFERENCES risk_type(risk_type_id),
    FOREIGN KEY (asset_id) REFERENCES asset_register(asset_id),
    FOREIGN KEY (threat_id) REFERENCES threat(threat_id),
    FOREIGN KEY (vulnerability_id) REFERENCES vulnerability_db(vulnerability_id),
    FOREIGN KEY (inherent_impact_id) REFERENCES impact_level(impact_id),
    FOREIGN KEY (inherent_probability_id) REFERENCES probability_level(probability_id),
    FOREIGN KEY (residual_impact_id) REFERENCES impact_level(impact_id),
    FOREIGN KEY (residual_probability_id) REFERENCES probability_level(probability_id),
    FOREIGN KEY (risk_owner_id) REFERENCES asset_owner(owner_id)
);

CREATE TABLE IF NOT EXISTS risk_control_mapping (
    mapping_id SERIAL PRIMARY KEY,
    risk_id INT,
    control_id INT,
    control_objective TEXT,
    effectiveness_score INT,
    FOREIGN KEY (risk_id) REFERENCES risk_register(risk_id),
    FOREIGN KEY (control_id) REFERENCES control_db(control_id)
);

CREATE TABLE IF NOT EXISTS risk_treatment (
    treatment_id SERIAL PRIMARY KEY,
    risk_id INT,
    treatment_decision VARCHAR(100),
    rationale TEXT,
    approver_id INT,
    approval_date DATE,
    target_completion_date DATE,
    status VARCHAR(50),
    FOREIGN KEY (risk_id) REFERENCES risk_register(risk_id),
    FOREIGN KEY (approver_id) REFERENCES asset_owner(owner_id)
);

-- 4. INCIDENT MANAGEMENT TABLES
-- ============================================================================

CREATE TABLE IF NOT EXISTS incident_register (
    incident_id SERIAL PRIMARY KEY,
    incident_title VARCHAR(255) NOT NULL,
    asset_id INT,
    threat_id INT,
    related_risk_id INT,
    severity VARCHAR(50),
    detection_date DATE,
    resolution_date DATE,
    status VARCHAR(50),
    FOREIGN KEY (asset_id) REFERENCES asset_register(asset_id),
    FOREIGN KEY (threat_id) REFERENCES threat(threat_id),
    FOREIGN KEY (related_risk_id) REFERENCES risk_register(risk_id)
);

CREATE TABLE IF NOT EXISTS call_tree (
    call_tree_id SERIAL PRIMARY KEY,
    incident_id INT,
    escalation_level INT,
    contact_name VARCHAR(255),
    contact_role VARCHAR(100),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    notify_order INT,
    FOREIGN KEY (incident_id) REFERENCES incident_register(incident_id)
);