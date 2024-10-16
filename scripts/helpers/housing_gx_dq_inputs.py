sql_config = {'person_reshape': {
    'sql': """SELECT *, cast(date_parse(substr(startdate, 1, 10), '%Y-%m-%d') as date) as startdate_parsed, cast(date_parse(substr(enddate, 1, 10), '%Y-%m-%d') as date) as enddate_parsed,  cast(date_parse(substr(dateofbirth, 1, 10), '%Y-%m-%d') as date) as dateofbirth_parsed FROM "housing-refined-zone"."person_reshape" where import_date=(select max(import_date) from "housing-refined-zone"."person_reshape") and enddate is NULL and type in ('Secure', 'Introductory')""",
    'id_field': 'person_id'},
    'tenure_reshape': {
        'sql': """SELECT * FROM "housing-refined-zone"."tenure_reshape" where import_date>'20240412' and import_date=(select max(import_date) from "housing-refined-zone"."tenure_reshape" where import_date>'20240412') and isterminated=False and description in ('Secure', 'Introductory')""",
        'id_field': 'tenure_id'},
    'contacts_reshape': {
        'sql': """SELECT id, targetid, createdat, contacttype, subtype, value, lastmodified, targettype, isactive, person_id, import_date  FROM "housing-refined-zone"."contacts_reshape"  where import_date=(select max(import_date) from "housing-refined-zone"."contacts_reshape") and isactive=True""",
        'id_field': 'id'},
    'housing_homeowner_record_sheet': {
        'sql': """SELECT * FROM "housing-raw-zone"."housing_homeowner_record_sheet" where import_date=(select max(import_date) from "housing-raw-zone"."housing_homeowner_record_sheet")""",
        'id_field': 'property_no'},
    'housing_dwellings_list': {
        'sql': """SELECT * FROM "housing-raw-zone"."housing_dwellings_list" where import_date=(select max(import_date) from "housing-raw-zone"."housing_homeowner_record_sheet")""",
        'id_field': 'property_dwelling_reference_number'},
    'assets_reshape': {
        'sql': """SELECT * FROM "housing-refined-zone"."assets_reshape" where import_date=(select max(import_date) from "housing-refined-zone"."assets_reshape") and assettype = 'Dwelling'""",
        'id_field': 'asset_id'}
}

table_list = ['person_reshape', 'tenure_reshape', 'contacts_reshape', 'housing_homeowner_record_sheet',
              'housing_dwellings_list', 'assets_reshape']

partition_keys = ['import_year', 'import_month', 'import_day', 'import_date']

dq_dimensions_map = {'expect_column_value_lengths_to_be_between': 'ACCURACY',
                     'expect_column_values_to_be_unique': 'UNIQUENESS',
                     'expect_column_values_to_match_regex': 'VALIDITY',
                     'expect_column_values_to_be_in_set': 'CONSISTENCY',
                     'expect_select_column_values_to_be_unique_within_record': 'UNIQUENESS',
                     'expect_column_values_to_not_be_null': 'COMPLETENESS',
                     'expect_column_values_to_be_between': 'VALIDITY'
                     }
