sql_config = {
    "properties": {"id_field": "LPRO_PROPREF"},
    "tenancies": {"id_field": "LTCY_ALT_REF"},
    "people": {"id_field": "LPAR_PER_ALT_REF"},
    "contacts": {"id_field": "LCDE_LEGACY_REF"},
    "arrears_actions": {"id_field": "LACA_PAY_REF"},
    "revenue_accounts": {"id_field": "LRAC_PAY_REF"},
    "transactions": {"id_field": "LTRN_ALT_REF"},
    "addresses": {"id_field": "LAUS_LEGACY_REF"},
}

data_load_list = [
    "properties"
    # "tenancies",
    # "people",
    # "contacts",
    # "arrears_actions",
    # "revenue_accounts",
    # # "transactions",
    # "addresses",
]

table_list = {
    "properties": [
        # "properties_1a",
        # "properties_1b",
        # "properties_1c",
        # "properties_1d",
        # "properties_1e",
        # "properties_2a",
        # "properties_3a",
        # "properties_4a",
        # "properties_4b",
        # "properties_4c",
        # "properties_7a",
        "full_full_hem_pro_all_dq",
    ],
    "tenancies": [
        # "tenancies_1a",
        # "tenancies_1c",
        # "tenancies_2a",
        # "tenancies_other",
        "tenancies_all",
    ],
    "people": [
        # "people_1a",
        #        "people_1b",
        #        "people_1c",
        #        "people_2a",
        "people_all"
    ],
    "contacts": [
        # "contacts_1a",
        # "contacts_1b",
        # "contacts_1c",
        # "contacts_2a",
        "contacts_all",
    ],
    "arrears_actions": [
        "arrears_actions_1a",
        "arrears_actions_1c",
        "arrears_actions_2a",
    ],
    "revenue_accounts": [
        "revenue_accounts_1a",
        "revenue_accounts_1b_sc",
        "revenue_accounts_1c",
        "revenue_accounts_2a",
        "revenue_accounts_other",
    ],
    "transactions": [
        # "transactions_1a",
        # "transactions_1c",
        # "transactions_2a",
        # "transactions_other",
        "transactions_all",
    ],
    "addresses": ["addresses_1a", "addresses_1b", "addresses_2a"],
}

partition_keys = ["import_date"]
