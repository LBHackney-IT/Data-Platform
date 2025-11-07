sql_config = {
    "properties": {"id_field": "LPRO_PROPREF"},
    "tenancies": {"id_field": "LTCY_ALT_REF"},
    "people": {"id_field": "LPAR_PER_ALT_REF"},
    "contacts": {"id_field": "LCDE_LEGACY_REF"},
}

data_load_list = ["properties", "tenancies", "people", "contacts"]

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
        "properties_all_tranches",
    ],
    "tenancies": [
        "tenancies_1a",
        "tenancies_1c",
        "tenancies_2a",
        "tenancies_all",
        "tenancies_other",
    ],
    "people": ["people_1a", "people_1b", "people_1c", "people_2a"],
    "contacts": ["contacts_1a", "contacts_1b", "contacts_2a"]
}

partition_keys = ["import_date"]
