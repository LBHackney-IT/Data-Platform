sql_config = {
    "properties_1a": {
        "sql": """ SELECT *
                   FROM "housing_nec_migration"."properties_1a" """,
        "id_field": "LPRO_PROPREF",
    },
}


table_list = ['properties_1a']

partition_keys = ['import_date']
