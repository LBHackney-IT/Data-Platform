sql_config = {
    "properties": {"id_field": "LPRO_PROPREF"},
    "tenancies": {"id_field": "LTCY_ALT_REF"},
}

data_load_list = ["properties", "tenancies"]

table_list = {
    "properties": [
        "properties_1a",
        "properties_1b",
        "properties_1c",
        "properties_1d",
        "properties_1e",
        "properties_2a",
        "properties_4a",
        "properties_4b",
        "properties_4c"
    ],
    "tenancies": ["tenancies_1a"],
}

partition_keys = ["import_date"]
