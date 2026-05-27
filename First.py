import streamlit as st
import sqlite3
import pandas as pd

# 1. CONNECT TO DATABASE & RUN YOUR SQL FILE
conn = sqlite3.connect("assets.db", check_same_thread=False)
cursor = conn.cursor()

# Read your Main.sql file and run it to create the tables
with open("Main.sql", "r") as sql_file:
    sql_script = sql_file.read()
cursor.executescript(sql_script)
conn.commit()


# 2. STREAMLIT USER INTERFACE
st.title("🛡️ Asset Management and Risk Assessment")

st.subheader("➕ Add New Asset Type")
with st.form("asset_type_form", clear_on_submit=True):
    asset_type_id = st.text_input("Asset ID")
    asset_type_name = st.text_input("Asset Type Name")
    description = st.text_input("Description")
    cia_default_rating = st.selectbox("Default CIA Rating", ["Low", "Medium", "High"])
    
    submit_button = st.form_submit_button("Insert into Database")


# 3. SAVE DATA WHEN BUTTON IS CLICKED
if submit_button:
    # Insert the user's input into the SQL table
    cursor.execute("""
        INSERT INTO asset_types (asset_id, asset_type_name, description, cia_default_rating) 
        VALUES (?, ?, ?, ?)
    """, (asset_type_id, asset_type_name, description, cia_default_rating))
    
    conn.commit()
    st.success("✅ Successfully added to the SQL Database!")


# 4. DISPLAY THE DATABASE AS A TABLE
st.subheader("🗃️ Registered Asset Types Table")

# Fetch all data from the asset_types table
cursor.execute("SELECT * FROM asset_types")
data = cursor.fetchall()

if data:
    # Convert the raw SQL data into a beautiful Pandas DataFrame table
    df = pd.DataFrame(data, columns=["Asset ID", "Asset Type Name", "Description", "CIA Rating"])
    
    # Display it as an interactive table in Streamlit
    st.dataframe(df, use_container_width=True)
else:
    st.info("The database table is currently empty.")