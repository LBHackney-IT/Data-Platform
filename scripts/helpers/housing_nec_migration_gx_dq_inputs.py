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
        "properties_3a",
        "properties_4a",
        "properties_4b",
        "properties_4c",
        "properties_7a",
        "properties_all_tranches"
    ],
    "tenancies": ["tenancies_1a",
                  "tenancies_1c"]
}

partition_keys = ["import_date"]
