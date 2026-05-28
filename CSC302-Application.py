import streamlit as st
import sqlite3
import pandas as pd
import os

st.set_page_config(page_title="GRC Portal", layout="wide")

# ============================================================================
# 1. DATABASE INIT (Converts PostgreSQL schema safely to SQLite)
# ============================================================================
DB_NAME = "assets.db"
SQL_FILE = "Main.sql"

@st.cache_resource
def init_db():
    conn = sqlite3.connect(DB_NAME, check_same_thread=False)
    cursor = conn.cursor()
    
    if os.path.exists(SQL_FILE):
        with open(SQL_FILE, "r") as f:
            sql_script = f.read()
        
        # Translate PostgreSQL SERIAL types over to SQLite syntax cleanly
        sql_script = sql_script.replace("SERIAL PRIMARY KEY", "INTEGER PRIMARY KEY AUTOINCREMENT")
        sql_script = sql_script.replace("SERIAL", "INTEGER")
        
        try:
            cursor.executescript(sql_script)
            conn.commit()
        except sqlite3.Error as e:
            st.error(f"Schema deployment error: {e}")
    else:
        st.error(f"Missing '{SQL_FILE}' file in this directory.")
    return conn

conn = init_db()
cursor = conn.cursor()

# Helper function to easily read tables into DataFrames
def view_table(query):
    try:
        return pd.read_sql_query(query, conn)
    except Exception as e:
        st.error(f"Error loading table view: {e}")
        return pd.DataFrame()


# ============================================================================
# 2. SIDEBAR NAVIGATION
# ============================================================================
st.sidebar.title("🛡️ Governance, Risk & Compliance")
app_mode = st.sidebar.radio("Navigate Workspace", [
    "📦 Asset Categories", 
    "🖥️ Asset Register", 
    "⚠️ Risk Register", 
    "🚨 Incident Log"
])


# ============================================================================
# MODULE 1: ASSET CATEGORIES
# ============================================================================
if app_mode == "📦 Asset Categories":
    st.title("Asset Configurations & Typologies")
    
    left_col, right_col = st.columns([1, 2], gap="large")
    
    with left_col:
        st.subheader("➕ Create Category")
        with st.form("asset_type_form", clear_on_submit=True):
            name = st.text_input("Asset Type Name")
            desc = st.text_area("Description")
            cia = st.selectbox("Default CIA Rating", ["Low", "Medium", "High"])
            submit = st.form_submit_button("Save Category")
            
            if submit and name.strip():
                cursor.execute("INSERT INTO asset_types (asset_type_name, asset_description, cia_default_rating) VALUES (?, ?, ?)", (name, desc, cia))
                conn.commit()
                st.success("Category written successfully!")
                st.rerun()

    with right_col:
        st.subheader("🗃️ Current Registered Categories")
        df = view_table("SELECT asset_type_id AS ID, asset_type_name AS Name, asset_description AS Description, cia_default_rating AS CIA FROM asset_types")
        st.dataframe(df, use_container_width=True, hide_index=True)


# ============================================================================
# MODULE 2: ASSET REGISTER (Demonstrates Foreign Key Selection Dropdowns)
# ============================================================================
elif app_mode == "🖥️ Asset Register":
    st.title("Corporate Asset Register")
    
    left_col, right_col = st.columns([1, 2], gap="large")
    
    # Dynamic Querying to populate UI Dropdowns
    categories_df = view_table("SELECT asset_type_id, asset_type_name FROM asset_types")
    
    with left_col:
        st.subheader("➕ Onboard Corporate Asset")
        
        if categories_df.empty:
            st.warning("⚠️ Please populate 'Asset Categories' first before onboarding assets.")
        else:
            with st.form("asset_reg_form", clear_on_submit=True):
                asset_name = st.text_input("Asset Reference/Name")
                
                # Show the clean text name, but compile its true SQL ID in the backend
                cat_select = st.selectbox("Asset Classification Type", categories_df['asset_type_name'].tolist())
                crit = st.selectbox("Business Criticality", ["Tier 1 - Mission Critical", "Tier 2 - Operational", "Tier 3 - Non-Essential"])
                status = st.selectbox("Operational Lifecycle Status", ["Active", "In-Development", "Decommissioned"])
                
                submit = st.form_submit_button("Register Asset")
                
                if submit and asset_name.strip():
                    # Look up corresponding ID for chosen name category
                    cat_id = int(categories_df[categories_df['asset_type_name'] == cat_select]['asset_type_id'].values[0])
                    
                    cursor.execute("""
                        INSERT INTO asset_register (asset_name, asset_type_id, business_criticality, asset_status) 
                        VALUES (?, ?, ?, ?)
                    """, (asset_name, cat_id, crit, status))
                    conn.commit()
                    st.success("Asset logged successfully!")
                    st.rerun()

    with right_col:
        st.subheader("🗃️ Inventory Overview")
        # SQL Join query to present related table structural lookups smoothly
        query = """
            SELECT a.asset_id AS ID, a.asset_name AS Name, t.asset_type_name AS Type, a.business_criticality AS Criticality, a.asset_status AS Status 
            FROM asset_register a
            LEFT JOIN asset_types t ON a.asset_type_id = t.asset_type_id
        """
        df = view_table(query)
        st.dataframe(df, use_container_width=True, hide_index=True)


# ============================================================================
# MODULE 3: RISK REGISTER
# ============================================================================
elif app_mode == "⚠️ Risk Register":
    st.title("Enterprise Risk Ledger")
    
    left_col, right_col = st.columns([1, 2], gap="large")
    assets_df = view_table("SELECT asset_id, asset_name FROM asset_register")
    
    with left_col:
        st.subheader("➕ Document Core Risk Vectors")
        if assets_df.empty:
            st.warning("⚠️ Onboard hardware/software items inside the Asset Register before mapping risks.")
        else:
            with st.form("risk_form", clear_on_submit=True):
                title = st.text_input("Risk Scenario Title")
                target_asset = st.selectbox("Impacted Corporate Asset", assets_df['asset_name'].tolist())
                inherent_score = st.slider("Inherent Risk Score Assessment", 1, 25, 12)
                status = st.selectbox("Mitigation Tracking Status", ["Open / Unmitigated", "Under Review", "Mitigated & Closed"])
                
                submit = st.form_submit_button("Log Risk Context")
                
                if submit and title.strip():
                    asset_id = int(assets_df[assets_df['asset_name'] == target_asset]['asset_id'].values[0])
                    cursor.execute("""
                        INSERT INTO risk_register (risk_title, asset_id, inherent_risk_score, status) 
                        VALUES (?, ?, ?, ?)
                    """, (title, asset_id, inherent_score, status))
                    conn.commit()
                    st.success("Risk scenario registered!")
                    st.rerun()

    with right_col:
        st.subheader("🗃️ Active Profiles")
        query = """
            SELECT r.risk_id AS ID, r.risk_title AS Scenario, a.asset_name AS Affected_Asset, r.inherent_risk_score AS Score, r.status AS Status 
            FROM risk_register r
            LEFT JOIN asset_register a ON r.asset_id = a.asset_id
        """
        df = view_table(query)
        st.dataframe(df, use_container_width=True, hide_index=True)


# ============================================================================
# MODULE 4: INCIDENT LOG
# ============================================================================
elif app_mode == "🚨 Incident Log":
    st.title("Incident Management Ledger")
    
    left_col, right_col = st.columns([1, 2], gap="large")
    risks_df = view_table("SELECT risk_id, risk_title FROM risk_register")
    
    with left_col:
        st.subheader("➕ Log Security Event")
        if risks_df.empty:
            st.warning("⚠️ Document baseline risk thresholds in the Risk Register before indexing real-time incidents.")
        else:
            with st.form("incident_form", clear_on_submit=True):
                title = st.text_input("Incident Header Event")
                linked_risk = st.selectbox("Root Risk Vector", risks_df['risk_title'].tolist())
                severity = st.selectbox("Operational Severity Impact", ["Low Impact", "Medium Impact", "High Priority Crippling"])
                status = st.selectbox("Containment Progress", ["Triage", "Active Containment", "Resolved & Evaluated"])
                
                submit = st.form_submit_button("Record Incident Context")
                
                if submit and title.strip():
                    risk_id = int(risks_df[risks_df['risk_title'] == linked_risk]['risk_id'].values[0])
                    cursor.execute("""
                        INSERT INTO incident_register (incident_title, related_risk_id, severity, status) 
                        VALUES (?, ?, ?, ?)
                    """, (title, risk_id, severity, status))
                    conn.commit()
                    st.success("Incident registered!")
                    st.rerun()

    with right_col:
        st.subheader("🗃️ Historic Events Realtime Feed")
        query = """
            SELECT i.incident_id AS ID, i.incident_title AS Incident, r.risk_title AS Underlying_Risk, i.severity AS Severity, i.status AS Containment 
            FROM incident_register i
            LEFT JOIN risk_register r ON i.related_risk_id = r.risk_id
        """
        df = view_table(query)
        st.dataframe(df, use_container_width=True, hide_index=True)