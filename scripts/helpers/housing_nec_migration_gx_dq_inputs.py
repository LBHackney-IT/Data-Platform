sql_config = {
    "properties_1a": {
        "sql": """ SELECT *
                   FROM "housing_nec_migration"."properties_1a" """,
        "id_field": "LPRO_PROPREF",
    },
    "properties_1b": {
            "sql": """ SELECT *
                       FROM "housing_nec_migration"."properties_1b" """,
            "id_field": "LPRO_PROPREF",
        },
    "properties_1c": {
            "sql": """ SELECT *
                       FROM "housing_nec_migration"."properties_1c" """,
            "id_field": "LPRO_PROPREF",
        }
}


table_list = ['properties_1a', 'properties_1b', 'properties_1c']

partition_keys = ['import_date']
