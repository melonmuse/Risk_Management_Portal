# Cybersecurity Risk Management Portal

**A PostgreSQL database with 17 tables for cybersecurity risk management, and a Streamlit web portal for managing every table without writing SQL.**



https://github.com/user-attachments/assets/dc531d85-9e7b-4ef2-8e86-323c412705a5





## Overview
Organisations need to connect their IT assets to the threats and vulnerabilities that affect them, the risks those create, and the controls, treatments, and incidents that follow. In many organisations this information sits in separate spreadsheets. This project designs a normalised relational database for the whole risk management process and adds a web front end so non-technical users can view and manage it.

## Highlights
- **Normalised schema with 17 tables:**
  - Lookup tables: asset types, owners, locations, threat actors, impact and probability levels, risk and control types
  - Core tables: asset register, threats, vulnerabilities, controls, risk register, risk–control mapping, risk treatment, incident register, and call tree
- **Re-runnable setup script** that drops and rebuilds every table and inserts sample data.
- **One interface for every table:** View, Add, Update, and Delete tabs work with any of the 17 tables.
- **Forms that adapt to the data:** each field is shown as a number, date, or text input based on the column's type.
- **Safe database writes** using parameterised queries, with clear messages when the database rejects a change (for example, a foreign key violation).

## Skills Demonstrated
- Relational database design and normalisation (lookup tables, foreign keys, a many-to-many mapping table)
- Writing SQL DDL and DML in PostgreSQL
- Building generic CRUD operations in Python with psycopg2
- Building a data app quickly with Streamlit and pandas
- Handling secrets: database credentials are kept out of the repository with Streamlit secrets

## Tech Stack
PostgreSQL · Python · Streamlit · psycopg2 · pandas · NumPy

## Getting Started
**Prerequisites:** Python 3 and a running PostgreSQL server

```bash
git clone https://github.com/melonmuse/Risk_Management_Portal.git
cd Risk_Management_Portal
pip install -r requirements.txt
psql -d your_database_name -f Main.sql   # creates the tables and sample data
```

Create `.streamlit/secrets.toml` with your database credentials. This file is listed in `.gitignore`.
```toml
[postgres]
host = "localhost"
port = 5432
dbname = "your_database_name"
user = "your_username"
password = "your_password"
```

Start the portal:
```bash
streamlit run CSC302-Application.py
```
Choose a table from the dropdown, then use the **View**, **Add**, **Update**, or **Delete** tab.

## Testing
- [ ] Run `Main.sql` twice. The second run should finish without errors.
- [ ] Select each table and check that its sample data loads.
- [ ] Add, update, and delete a record, and check that each change appears in the View tab.
- [ ] Delete a lookup record that another table still references. The portal should show a database error instead of crashing.

## Author
**Abeer Abu Shiekah**
