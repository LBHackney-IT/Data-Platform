sql_config = {
    "properties": {"id_field": "lpro_propref"},
    "tenancies": {"id_field": "ltcy_alt_ref"},
    "people": {"id_field": "lpar_per_alt_ref"},
    "debit_breakdowns": {"id_field": "ldbr_pay_ref"},
    "contacts": {"id_field": "lcde_legacy_ref"},
    "arrears_actions": {"id_field": "laca_pay_ref"},
    "revenue_accounts": {"id_field": "lrac_pay_ref"},
    "transactions": {"id_field": "ltrn_alt_ref"},
    "addresses": {"id_field": "laus_legacy_ref"},
}

data_load_list = [
    "properties",
    "tenancies",
    "people",
    "debit_breakdowns"
    # "contacts",
    # "arrears_actions",
    # "revenue_accounts",
    # # "transactions",
    # "addresses",
]

table_list = {
    "properties": [
        "full_dq_full_dq_hem_pro_all_dq",
    ],
    "tenancies": [
        "full_dq_full_dq_hem_tcy_all_dq",
    ],
    "people": ["full_dq_full_dq_hem_per_all_dq"],
    "debit_breakdowns": ["full_dq_full_dq_hra_dbr_all_dq"],
    "contacts": [
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
        "transactions_all",
    ],
    "addresses": ["addresses_1a", "addresses_1b", "addresses_2a"],
}

partition_keys = ["import_date"]
