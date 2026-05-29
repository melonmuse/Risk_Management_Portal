import streamlit as st
import psycopg2
import pandas as pd

#----------------------------------------------------------------------
# Database connection function
#----------------------------------------------------------------------
def get_connection():
    return psycopg2.connect(
        host="localhost",          
        database="CSC302_Databases",     
        user="postgres",           
        password="Abeer2204",      
        port="5432"                
    )

#----------------------------------------------------------------------
# Create a title
#----------------------------------------------------------------------
st.title("🛡️ Cybersecurity Risk Management Database Portal")

#----------------------------------------------------------------------
# Functions
#----------------------------------------------------------------------

#Function to view a table's data
def fetch_table_data(table_name):
    conn = get_connection()
    query = f"SELECT * FROM {table_name}"
    df = pd.read_sql_query(query, conn)
    conn.close()
    return df

# Function to delete a record
def delete_record(table_name, id_column_name, record_id):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        query = f"DELETE FROM {table_name} WHERE {id_column_name} = %s;"
        cursor.execute(query, (record_id,))
        conn.commit()
        cursor.close()
        conn.close()
        return True
    except Exception as e:
        st.error(f"Error occurred: {e}")
        return False

#Function to add a new entry
def add_entry(table_name, data_dict):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        columns = data_dict.keys()
        column_names = ", ".join(columns)
        placeholders = ", ".join(["%s"] * len(columns))
        query = f"INSERT INTO {table_name} ({column_names}) VALUES ({placeholders});"
        cursor.execute(query, tuple(data_dict.values()))
        conn.commit()
        cursor.close()
        conn.close()
        return True
    except Exception as e:
        st.error(f"Error occurred: {e}")
        return False

#Function to update an existing record
def update_record(table_name, id_column_name, record_id, updated_values_dict):
    try:
        conn = get_connection()
        cursor = conn.cursor()
        set_clause = ", ".join([f"{col} = %s" for col in updated_values_dict.keys()])
        query = f"UPDATE {table_name} SET {set_clause} WHERE {id_column_name} = %s;"
        values = list(updated_values_dict.values()) + [record_id]
        cursor.execute(query, tuple(values))
        conn.commit()
        cursor.close()
        conn.close()
        return True
    except Exception as e:
        st.error(f"Error occurred: {e}")
        return False

#----------------------------------------------------------------------
# Application Development
#----------------------------------------------------------------------

tables_list = [
    "asset_types", "asset_owner", "location_master", "threat_actor", 
    "impact_level", "probability_level", "risk_type", "control_type",
    "asset_register", "threat", "vulnerability_db", "control_db", 
    "risk_register", "risk_control_mapping", "risk_treatment", 
    "incident_register", "call_tree"
]
selected_table = st.selectbox("Select a table to manage:", tables_list)
table_name = selected_table.replace("_", " ").title()
st.subheader(f"Records from: {table_name}")
tab_view, tab_add, tab_update, tab_delete = st.tabs(["🔍 View Data", "➕ Add Entry", "✏️ Update Entry", "❌ Delete Entry"])

# View data from the selected table
with tab_view:
    st.write(f"Viewing data from {selected_table}")
    data = fetch_table_data(selected_table)
    st.dataframe(data, use_container_width=True, hide_index=True)         

# Add entry to the selected table (placeholder)
with tab_add:
    st.write(f"Add a new entry to {selected_table}")
    id_col = data.columns[0]
    with st.form("new_entry_form"):
        new_data_dict = {}
        for col in data.columns:
            if col == id_col:
                continue 
            new_data_dict[col] = st.text_input(f"Enter value for {col}:")
        submit_new_entry = st.form_submit_button("Submit Entry")
        if submit_new_entry:
            success = add_entry(selected_table, new_data_dict)
            if success:
                st.success("Record added successfully!")

with tab_update:
    st.write(f"Update entries in {selected_table}")
    id_col = data.columns[0] 
    record_id = st.number_input(f"Enter the {id_col} to update:", step=1, value=1)
    current_df = fetch_table_data(selected_table)
    row_to_update = current_df[current_df[id_col] == record_id]
    if row_to_update.empty:
        st.warning(f"No record found with {id_col} = {record_id}")
    else:
        st.write("Current record data:")
        st.dataframe(row_to_update, use_container_width=True, hide_index=True)
        updated_values_dict = {}
        with st.form("update_form"):
            for column in current_df.columns:
                if column == id_col:
                    continue 
                existing_value = row_to_update[column].values[0]
                user_input = st.text_input(f"Modify {column}:", value=str(existing_value))
                updated_values_dict[column] = user_input
            submit_update = st.form_submit_button("Save Changes")
            if submit_update:
                success = update_record(selected_table, id_col, record_id, updated_values_dict)
                if success:
                    st.success("Record updated successfully!")

# Delete entries from the selected table
with tab_delete:
    st.write(f"Delete entries from {selected_table}")
    id_column_name = data.columns[0]
    st.info(f"Using identifier column: **{id_column_name}**")
    record_id = st.number_input("Enter the numeric ID of the record to delete:", step=1, value=0)
    if st.button("Confirm Delete", type="primary"):
        if record_id > 0:
            success = delete_record(selected_table, id_column_name, record_id)
            if success:
                st.success("Record deleted successfully! Refresh the page to see changes.")
        else:
            st.warning("Please enter a valid ID greater than 0.")