-- ============================================================================
-- 0.TEARDOWN (AUTOMATICALLY DROPS ALL TABLES IF THEY EXIST TO ENSURE CLEAN RE-RUNS)
-- ============================================================================
DROP TABLE IF EXISTS 
    call_tree, incident_register, risk_treatment, risk_control_mapping, 
    risk_register, control_db, vulnerability_db, threat, asset_register, 
    control_type, risk_type, probability_level, impact_level, threat_actor, 
    location_master, asset_owner, asset_types
CASCADE;

-- ============================================================================
-- 1. MASTER LOOKUP TABLES
-- ============================================================================
CREATE TABLE IF NOT EXISTS ASSET_TYPES (
    asset_type_id SERIAL PRIMARY KEY,
    asset_type_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    cia_default_rating VARCHAR(50)
);
CREATE TABLE IF NOT EXISTS ASSET_OWNER (
    owner_id SERIAL PRIMARY KEY,
    owner_name VARCHAR(255) NOT NULL,
    department VARCHAR(255),
    email VARCHAR(255) UNIQUE NOT NULL,
    role VARCHAR(100),
    status VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS LOCATION_MASTER (
    location_id SERIAL PRIMARY KEY,
    location_name VARCHAR(255) NOT NULL,
    country VARCHAR(100),
    region VARCHAR(100),
    data_residency_zone VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS THREAT_ACTOR (
    actor_id SERIAL PRIMARY KEY,
    actor_name VARCHAR(255) UNIQUE NOT NULL,
    actor_type VARCHAR(100),
    motivation TEXT,
    sophistication_level VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS IMPACT_LEVEL (
    impact_id SERIAL PRIMARY KEY,
    impact_label VARCHAR(100) UNIQUE NOT NULL,
    impact_score INT NOT NULL,
    financial_threshold DECIMAL(15, 2),
    description TEXT
);

CREATE TABLE IF NOT EXISTS PROBABILITY_LEVEL (
    probability_id SERIAL PRIMARY KEY,
    probability_label VARCHAR(100) UNIQUE NOT NULL,
    probability_score INT NOT NULL,
    frequency_description TEXT
);

CREATE TABLE IF NOT EXISTS RISK_TYPE (
    risk_type_id SERIAL PRIMARY KEY,
    risk_type_name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS CONTROL_TYPE (
    control_type_id SERIAL PRIMARY KEY,
    control_type_name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT
);
-- ============================================================================
-- 2. PRIMARY DATA TABLES
-- ============================================================================
CREATE TABLE IF NOT EXISTS ASSET_REGISTER (
    asset_id SERIAL PRIMARY KEY,
    asset_name VARCHAR(255) NOT NULL,
    asset_type_id INT,
    owner_id INT,
    location_id INT,
    parent_asset_id INT,
    confidentiality_rating VARCHAR(50),
    integrity_rating VARCHAR(50),
    availability_rating VARCHAR(50),
    business_criticality VARCHAR(100),
    asset_status VARCHAR(50),
    onboarded_date DATE,
    FOREIGN KEY (asset_type_id) REFERENCES ASSET_TYPES(asset_type_id),
    FOREIGN KEY (owner_id) REFERENCES ASSET_OWNER(owner_id),
    FOREIGN KEY (location_id) REFERENCES LOCATION_MASTER(location_id),
    FOREIGN KEY (parent_asset_id) REFERENCES ASSET_REGISTER(asset_id) 
);

CREATE TABLE IF NOT EXISTS THREAT (
    threat_id SERIAL PRIMARY KEY,
    threat_name VARCHAR(255) NOT NULL,
    actor_id INT,
    threat_category VARCHAR(100),
    mitre_attack_id VARCHAR(50),
    description TEXT,
    FOREIGN KEY (actor_id) REFERENCES THREAT_ACTOR(actor_id)
);

CREATE TABLE IF NOT EXISTS VULNERABILITY_DB (
    vulnerability_id SERIAL PRIMARY KEY,
    asset_id INT,
    cve_reference VARCHAR(50),
    vulnerability_name VARCHAR(255) NOT NULL,
    cvss_score DECIMAL(3, 1),
    severity VARCHAR(50),
    discovered_date DATE,
    status VARCHAR(50),
    FOREIGN KEY (asset_id) REFERENCES ASSET_REGISTER(asset_id)
);

CREATE TABLE IF NOT EXISTS CONTROL_DB (
    control_id SERIAL PRIMARY KEY,
    control_name VARCHAR(255) NOT NULL,
    control_type_id INT,
    control_owner_id INT,
    iso27002_reference VARCHAR(50),
    implementation_status VARCHAR(100),
    effectiveness_rating INT,
    description TEXT,
    FOREIGN KEY (control_type_id) REFERENCES CONTROL_TYPE(control_type_id),
    FOREIGN KEY (control_owner_id) REFERENCES ASSET_OWNER(owner_id)
);

-- ============================================================================
-- 3. RISK ARCHITECTURE TABLES
-- ============================================================================
CREATE TABLE IF NOT EXISTS RISK_REGISTER (
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
    FOREIGN KEY (risk_type_id) REFERENCES RISK_TYPE(risk_type_id),
    FOREIGN KEY (asset_id) REFERENCES ASSET_REGISTER(asset_id),
    FOREIGN KEY (threat_id) REFERENCES THREAT(threat_id),
    FOREIGN KEY (vulnerability_id) REFERENCES VULNERABILITY_DB(vulnerability_id),
    FOREIGN KEY (inherent_impact_id) REFERENCES IMPACT_LEVEL(impact_id),
    FOREIGN KEY (inherent_probability_id) REFERENCES PROBABILITY_LEVEL(probability_id),
    FOREIGN KEY (residual_impact_id) REFERENCES IMPACT_LEVEL(impact_id),
    FOREIGN KEY (residual_probability_id) REFERENCES PROBABILITY_LEVEL(probability_id),
    FOREIGN KEY (risk_owner_id) REFERENCES ASSET_OWNER(owner_id)
);

CREATE TABLE IF NOT EXISTS RISK_CONTROL_MAPPING (
    mapping_id SERIAL PRIMARY KEY,
    risk_id INT,
    control_id INT,
    control_objective TEXT,
    effectiveness_score INT,
    FOREIGN KEY (risk_id) REFERENCES RISK_REGISTER(risk_id),
    FOREIGN KEY (control_id) REFERENCES CONTROL_DB(control_id)
);

CREATE TABLE IF NOT EXISTS RISK_TREATMENT (
    treatment_id SERIAL PRIMARY KEY,
    risk_id INT,
    treatment_decision VARCHAR(100),
    rationale TEXT,
    approver_id INT,
    approval_date DATE,
    target_completion_date DATE,
    status VARCHAR(50),
    FOREIGN KEY (risk_id) REFERENCES RISK_REGISTER(risk_id),
    FOREIGN KEY (approver_id) REFERENCES ASSET_OWNER(owner_id)
);
-- ============================================================================
-- 4. INCIDENT MANAGEMENT TABLES
-- ============================================================================
CREATE TABLE IF NOT EXISTS INCIDENT_REGISTER (
    incident_id SERIAL PRIMARY KEY,
    incident_title VARCHAR(255) NOT NULL,
    asset_id INT,
    threat_id INT,
    related_risk_id INT,
    severity VARCHAR(50),
    detection_date DATE,
    resolution_date DATE,
    status VARCHAR(50),
    FOREIGN KEY (asset_id) REFERENCES ASSET_REGISTER(asset_id),
    FOREIGN KEY (threat_id) REFERENCES THREAT(threat_id),
    FOREIGN KEY (related_risk_id) REFERENCES RISK_REGISTER(risk_id)
);

CREATE TABLE IF NOT EXISTS CALL_TREE (
    call_tree_id SERIAL PRIMARY KEY,
    incident_id INT,
    escalation_level INT NOT NULL,
    contact_name VARCHAR(255) NOT NULL,
    contact_role VARCHAR(100),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    notify_order INT,
    FOREIGN KEY (incident_id) REFERENCES INCIDENT_REGISTER(incident_id)
);
-- ============================================================================
-- 5. INSERTING DATA
-- ============================================================================
-- INSERTING MASTER DATA
INSERT INTO ASSET_TYPES (asset_type_name, description, cia_default_rating) VALUES
('Cloud Database', 'Managed relational or non-relational cloud data stores hosting production data.', 'High-High-Moderate'),
('On-Premise Server', 'Physical bare-metal or virtualized server infrastructure located in local data centers.', 'High-Moderate-Moderate'),
('SaaS Application', 'Third-party hosted software solutions utilized across business units.', 'Moderate-Moderate-Low'),
('Networking Equipment', 'Core switches, routers, firewalls, and load balancers managing infrastructure traffic.', 'High-High-High'),
('User Endpoint', 'Corporate-issued workstations, laptops, and mobile devices assigned to personnel.', 'Moderate-Low-Low');

INSERT INTO ASSET_OWNER (owner_name, department, email, role, status) VALUES
('Alice Vance', 'Information Security', 'alice.vance@enterprise.com', 'CISO', 'Active'),
('Bob Miller', 'Infrastructure Engineering', 'bob.miller@enterprise.com', 'Director of Infrastructure', 'Active'),
('Charlie Green', 'Data Analytics & BI', 'charlie.green@enterprise.com', 'Lead Data Architect', 'Active'),
('Diana Prince', 'DevOps & Cloud Operations', 'diana.prince@enterprise.com', 'Principal Cloud Engineer', 'Active'),
('Evan Wright', 'Legal & Compliance', 'evan.wright@enterprise.com', 'Compliance Manager', 'Active');

INSERT INTO LOCATION_MASTER (location_name, country, region, data_residency_zone) VALUES
('AWS us-east-1', 'United States', 'North America', 'US-East'),
('Azure westeurope', 'Netherlands', 'Europe', 'EU-West (GDPR compliant)'),
('Primary Datacenter DC-01', 'United Kingdom', 'Europe', 'UK-Mainland'),
('Corporate HQ Office', 'Australia', 'APAC', 'APAC-AU'),
('GCP asia-east1', 'Taiwan', 'APAC', 'APAC-East');

INSERT INTO THREAT_ACTOR (actor_name, actor_type, motivation, sophistication_level) VALUES
('APT29 (Cozy Bear)', 'State-Sponsored', 'Espionage, intelligence gathering, and political influence.', 'Advanced / Nation-State'),
('LockBit Syndicate', 'Cybercriminal Organization', 'Financial extortion via ransomware deployments.', 'High / Professional'),
('Disgruntled Insider', 'Internal Employee', 'Sabotage, data theft, or personal grievance retaliation.', 'Low to Moderate'),
('Script Kiddies / Opportunistic', 'External Amateur', 'Clout, minor disruption, or simple automated vulnerability scanning.', 'Low'),
('Anonymous Affiliate', 'Hacktivist', 'Ideological, political statements, or public embarrassment.', 'Moderate');

INSERT INTO IMPACT_LEVEL (impact_label, impact_score, financial_threshold, description) VALUES
('Negligible', 1, 5000.00, 'Minimal operational disruption; no regulatory penalties or data exposure.'),
('Minor', 2, 50000.00, 'Brief localized system downtime; easily managed within internal operational buffers.'),
('Moderate', 3, 250000.00, 'Partial outages affecting core business operations; minor compliance reporting triggered.'),
('Major', 4, 1000000.00, 'Widespread outages; customer SLA breaches; significant customer data leakage.'),
('Critical', 5, 5000000.00, 'Complete business halt; catastrophic brand damage; severe board-level legal liability.');

INSERT INTO PROBABILITY_LEVEL (probability_label, probability_score, frequency_description) VALUES
('Rare', 1, 'Highly unlikely to occur; happens less than once every 5 to 10 years.'),
('Unlikely', 2, 'Possible, but unexpected under normal operating conditions; once every 2 to 5 years.'),
('Possible', 3, 'Likely to happen at least once in a typical calendar year.'),
('Likely', 4, 'Expected to occur multiple times throughout a calendar year.'),
('Almost Certain', 5, 'Highly persistent occurrence; happens weekly, daily, or continuously.');

INSERT INTO RISK_TYPE (risk_type_name, description) VALUES
('Compliance & Regulatory', 'Risks involving fines, penalties, or legal action due to failure to meet legal frameworks like GDPR, HIPAA, or PCI-DSS.'),
('Operational Interruption', 'Risks that directly degrade or halt core day-to-day business functionality and infrastructure services.'),
('Data Exfiltration & Privacy', 'Risks related to unauthorized access, theft, or leaking of sensitive intellectual property or personally identifiable information (PII).'),
('Financial Extortion', 'Risks linked to monetary loss via ransomware, wire-fraud, or direct financial manipulation.'),
('Third-Party Supply Chain', 'Risks originating from vendors, SaaS solutions, or external dependencies integrated into internal ecosystems.');

INSERT INTO CONTROL_TYPE (control_type_name, description) VALUES
('Technical / Logical', 'Hardware or software-based solutions configured directly inside system architectures (e.g., Firewalls, MFA, Encryption).'),
('Administrative / Managerial', 'Policies, standard operating procedures, guidelines, and training designed to dictate human behavior and security posture.'),
('Physical', 'Tangible security measures safeguarding physical environments, facilities, and hardware assets (e.g., Badging systems, CCTV, Biometric locks).'),
('Preventative', 'Proactive barriers designed to block a threat actor from successfully exploiting a weakness.'),
('Detective', 'Monitoring and logging mechanisms deployed to discover anomalies and alert teams to active security breaches.');

--INSERTING PRIMARY DATA
INSERT INTO ASSET_REGISTER (asset_name, asset_type_id, owner_id, location_id, parent_asset_id, confidentiality_rating, integrity_rating, availability_rating, business_criticality, asset_status, onboarded_date) VALUES
('Primary AWS Environment', 1, 4, 1, NULL, 'High', 'High', 'High', 'Critical', 'Active', '2025-01-15'),
('On-Prem Production Rack Alpha', 2, 2, 3, NULL, 'High', 'Moderate', 'High', 'High', 'Active', '2024-06-10'),
('Corporate ERP System', 3, 3, 2, NULL, 'High', 'High', 'Moderate', 'High', 'Active', '2025-03-22'),
('Customer PII Production Database', 1, 3, 1, 1, 'High', 'High', 'High', 'Critical', 'Active', '2025-01-20'),
('Legacy Active Directory Server', 2, 2, 3, 2, 'High', 'High', 'High', 'High', 'Active', '2024-06-12');

INSERT INTO THREAT (threat_name, actor_id, threat_category, mitre_attack_id, description) VALUES
('Targeted Ransomware Deployment', 2, 'Malware / Extortion', 'T1486', 'Encryption of operational data stores to extort financial payment.'),
('Spear-Phishing Campaign', 1, 'Social Engineering', 'T1566', 'Highly targeted malicious emails designed to steal administrative credentials.'),
('SQL Injection (SQLi) Attempt', 4, 'Web Application Attack', 'T1190', 'Exploitation of unvetted application inputs to manipulate background relational databases.'),
('Privileged Credential Leaks', 3, 'Insider Threat / Misconfiguration', 'T1552', 'Internal leaks or deliberate exposure of high-level cloud access keys.'),
('Distributed Denial of Service', 5, 'Availability Disruption', 'T1498', 'Volumetric traffic saturation targeting public-facing networking firewalls.');

INSERT INTO VULNERABILITY_DB (asset_id, cve_reference, vulnerability_name, cvss_score, severity, discovered_date, status) VALUES
(4, 'CVE-2026-2143', 'Unauthenticated Remote Code Execution in Database Engine', 9.8, 'Critical', '2026-02-14', 'Open'),
(5, 'CVE-2024-3094', 'Backdoor in Core SSH/Authentication Utility Daemon', 10.0, 'Critical', '2026-04-01', 'Mitigated'),
(2, 'CVE-2025-8891', 'Local Privilege Escalation via Hardware Firmware Flaw', 7.2, 'High', '2026-01-10', 'In Progress'),
(3, 'CVE-2023-44487', 'HTTP/2 Rapid Reset Multi-Stream Vulnerability', 7.5, 'High', '2026-05-18', 'Open'),
(1, 'N/A', 'Improper S3 Bucket Public Read Permissions Policy', 5.3, 'Medium', '2026-05-20', 'Open');

INSERT INTO CONTROL_DB (control_name, control_type_id, control_owner_id, iso27002_reference, implementation_status, effectiveness_rating, description) VALUES
('Mandatory Phishing Simulation Training', 2, 1, 'A.6.3', 'Fully Implemented', 85, 'Quarterly baseline training and test simulations for all computing personnel.'),
('Next-Gen Web Application Firewall (WAF)', 1, 4, 'A.8.20', 'Fully Implemented', 90, 'Real-time monitoring and blocking of malicious web payloads on cloud gateways.'),
('Automated Patch Management Engine', 4, 2, 'A.8.19', 'Partially Implemented', 70, 'Central software deployment system tracking and updating critical operating systems vendor fixes.'),
('Hardware Token Multi-Factor Auth (MFA)', 1, 4, 'A.5.15', 'Fully Implemented', 98, 'Enforcement of hardware keys for accessing systems flagged with High business criticality.'),
('Security Operations Center (SOC) Log Monitoring', 5, 1, 'A.8.16', 'Fully Implemented', 80, '24/7/365 active log review and ingestion using centralized security alerting infrastructure.');

--INSERTING RISK MANAGEMENT DATA
INSERT INTO RISK_REGISTER (risk_title, risk_type_id, asset_id, threat_id, vulnerability_id, inherent_impact_id, inherent_probability_id, residual_impact_id, residual_probability_id, risk_owner_id, inherent_risk_score, residual_risk_score, identified_date, next_review_date, status) VALUES
('Ransomware Attack on Production Database Server', 4, 4, 1, 1, 5, 3, 5, 1, 3, 15, 5, '2026-05-01', '2026-11-01', 'Open'),
('SQL Injection Vulnerability Exploitation on Cloud Web App', 3, 1, 3, 5, 4, 4, 2, 2, 4, 16, 4, '2026-05-10', '2026-11-10', 'Open'),
('Insider credential theft via leaked admin keys', 3, 5, 4, 2, 4, 2, 4, 1, 2, 8, 4, '2026-04-15', '2026-10-15', 'Mitigated'),
('DDoS Volumetric Outage Targeting ERP System Infrastructure', 2, 3, 5, 4, 3, 4, 3, 2, 3, 12, 6, '2026-05-12', '2026-08-12', 'Under Review');

INSERT INTO RISK_CONTROL_MAPPING (risk_id, control_id, control_objective, effectiveness_score) VALUES
(1, 4, 'Mitigate ransomware threat by enforcing hardware tokens to block compromised credential entry.', 95),
(1, 3, 'Ensure secondary mitigation using system patch management to patch the RCE flaw.', 75),
(2, 2, 'Enforce real-time web traffic filtering to drop SQL injection payloads before hitting database tables.', 90),
(3, 4, 'Require multifactor access strings for structural administrative changes.', 98),
(4, 5, 'Track traffic spikes via active SOC monitoring logs to flag volumetric denial attacks.', 80);

INSERT INTO RISK_TREATMENT (risk_id, treatment_decision, rationale, approver_id, approval_date, target_completion_date, status) VALUES
(1, 'Mitigate', 'Deploying mandatory air-gapped server backup routines to secure historical records and prevent absolute encryption failure.', 1, '2026-05-03', '2026-06-15', 'In Progress'),
(2, 'Mitigate', 'Applying immediate cloud security configurations and code revision to scrub unvetted user parameter entries.', 4, '2026-05-11', '2026-05-30', 'In Progress'),
(3, 'Transfer', 'Purchasing extended high-tier corporate cyber liability protection coverage specifically for localized hardware exposure.', 5, '2026-04-20', '2026-05-01', 'Completed'),
(4, 'Accept', 'The operational cost to block extreme volumetric edge spikes entirely exceeds the financial threshold buffer for temporary short system blips.', 1, '2026-05-14', NULL, 'Approved');

--INSERTING INCIDENT MANAGEMENT DATA
INSERT INTO INCIDENT_REGISTER (incident_title, asset_id, threat_id, related_risk_id, severity, detection_date, resolution_date, status) VALUES
('Suspicious Inbound Database Payload Activity Detect', 4, 3, 2, 'High', '2026-05-25', '2026-05-25', 'Resolved'),
('Critical Core System Access Outage Event', 3, 5, 4, 'Critical', '2026-05-27', NULL, 'Active');

INSERT INTO CALL_TREE (incident_id, escalation_level, contact_name, contact_role, contact_email, contact_phone, notify_order) VALUES
(2, 1, 'On-Call Infrastructure Support Desk', 'L1 Cloud Engineer', 'noc@enterprise.com', '+1-555-0100', 1),
(2, 2, 'Diana Prince', 'Principal Cloud Engineer', 'diana.prince@enterprise.com', '+1-555-0144', 2),
(2, 3, 'Bob Miller', 'Director of Infrastructure', 'bob.miller@enterprise.com', '+1-555-0122', 3),
(2, 4, 'Alice Vance', 'CISO / Executive Crisis Lead', 'alice.vance@enterprise.com', '+1-555-0111', 4);