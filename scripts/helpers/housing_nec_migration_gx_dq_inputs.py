sql_config = {
    "properties": {"id_field": "lpro_propref"},
    "tenancies": {"id_field": "ltcy_alt_ref"},
    "people": {"id_field": "lpar_per_alt_ref"},
    "contacts": {"id_field": "lcde_legacy_ref"},
    "arrears_actions": {"id_field": "laca_pay_ref"},
    "revenue_accounts": {"id_field": "lrac_pay_ref"},
    "transactions": {"id_field": "ltrn_alt_ref"},
    "addresses": {"id_field": "laus_legacy_ref"},
}

data_load_list = [
    "properties",
    "tenancies",
    "people"
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
        "full_dq_full_dq_hem_pro_all_dq",
    ],
    "tenancies": [
        # "tenancies_1a",
        # "tenancies_1c",
        # "tenancies_2a",
        # "tenancies_other",
        "full_dq_full_dq_hem_tcy_all_dq",
    ],
    "people": [
        # "people_1a",
        #        "people_1b",
        #        "people_1c",
        #        "people_2a",
        "full_dq_full_dq_hem_per_all_dq"
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
