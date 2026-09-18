import streamlit as st
import psycopg2
import pandas as pd
import numpy as np
import datetime

def get_connection():
    return psycopg2.connect(**st.secrets["postgres"])

def fetch_table_data(table_name):
    try:
        conn = get_connection()
        try:
            query = f"SELECT * FROM {table_name}"
            df = pd.read_sql_query(query, conn)
        finally:
            conn.close()
        return df
    except Exception as e:
        st.error(f"Could not load '{table_name}': {e}")
        st.stop()

def to_safe_date(raw_value):
    if pd.isna(raw_value) or raw_value is None:
        return datetime.date.today()
    try:
        return pd.to_datetime(raw_value).date()
    except Exception:
        return datetime.date.today()

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
        st.error(f"Database Error: {e}")
        return False

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
        st.error(f"Database Error: {e}")
        return False

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
        st.error(f"Database Error: {e}")
        return False

st.set_page_config(layout="wide")
st.title("🛡️ Cybersecurity Risk Management Database Portal")

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

data = fetch_table_data(selected_table)
id_col = data.columns[0]

tab_view, tab_add, tab_update, tab_delete = st.tabs(["🔍 View Data", "➕ Add Entry", "✏️ Update Entry", "❌ Delete Entry"])

with tab_view:
    st.dataframe(data, use_container_width=True, hide_index=True)         

with tab_add:
    with st.form("new_entry_form"):
        new_data_dict = {}
        for col in data.columns:
            if col.lower() == id_col.lower():
                continue 
            
            if pd.api.types.is_integer_dtype(data[col]) or pd.api.types.is_float_dtype(data[col]):
                new_data_dict[col] = st.number_input(f"Enter numeric value for {col}:", step=1, value=0)
            elif pd.api.types.is_datetime64_any_dtype(data[col]) or col.lower().endswith("_date"):
                new_data_dict[col] = st.date_input(f"Select date for {col}:", value=datetime.date.today())
            else:
                new_data_dict[col] = st.text_input(f"Enter value for {col}:")
                
        submit_new_entry = st.form_submit_button("Submit Entry")
        if submit_new_entry:
            success = add_entry(selected_table, new_data_dict)
            if success:
                st.success("Record added successfully! Switch tabs to view.")

with tab_update:
    record_id = st.number_input(f"Enter the {id_col} to update:", step=1, value=1, key="update_record_id_selector")
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
                if column.lower() == id_col.lower():
                    continue 
                
                raw_value = row_to_update[column].values[0]
                
                if pd.api.types.is_integer_dtype(current_df[column]) or pd.api.types.is_float_dtype(current_df[column]):
                    if pd.isna(raw_value) or raw_value is None:
                        existing_value = 0
                    else:
                        try:
                            existing_value = int(float(raw_value))
                        except ValueError:
                            existing_value = 0
                    user_input = st.number_input(f"Modify {column}:", value=existing_value, step=1)
                
                elif pd.api.types.is_datetime64_any_dtype(current_df[column]) or column.lower().endswith("_date"):
                    existing_value = to_safe_date(raw_value)
                    user_input = st.date_input(f"Modify {column}:", value=existing_value)
                
                else:
                    if pd.isna(raw_value) or raw_value is None:
                        existing_value = ""
                    else:
                        existing_value = str(raw_value)
                    user_input = st.text_input(f"Modify {column}:", value=existing_value)
                
                updated_values_dict[column] = user_input
                
            submit_update = st.form_submit_button("Save Changes")
            if submit_update:
                success = update_record(selected_table, id_col, record_id, updated_values_dict)
                if success:
                    st.success("Record updated successfully! Switch tabs to view.")

with tab_delete:
    st.info(f"Using identifier column: **{id_col}**")
    delete_view_df = fetch_table_data(selected_table)
    st.dataframe(delete_view_df, use_container_width=True, hide_index=True)
    record_id_del = st.number_input("Enter the numeric ID of the record to delete:", step=1, value=0, key="delete_id_input_unique")
    
    if st.button("Confirm Delete", type="primary"):
        if record_id_del > 0:
            success = delete_record(selected_table, id_col, record_id_del)
            if success:
                st.success("Record deleted successfully! Switch tabs to view.")
        else:
            st.warning("Please enter a valid ID greater than 0.")