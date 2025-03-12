sql_config = {'person_reshape': {
    'sql': """SELECT *, substr(startdate, 1, 10) as startdate_parsed, substr(enddate, 1, 10) as enddate_parsed,
    substr(dateofbirth, 1, 10) as dateofbirth_parsed FROM "housing-refined-zone"."person_reshape" WHERE import_date = (SELECT max(import_date) FROM "housing-refined-zone"."person_reshape") AND enddate IS NULL AND type IN ('Secure', 'Introductory')""",
    'id_field': 'person_id'},
    'tenure_reshape': {
        'sql': """SELECT * FROM "housing-refined-zone"."tenure_reshape" where import_date=(select max(import_date) from "housing-refined-zone"."tenure_reshape") and description in ('Secure', 'Introductory', 'Mesne Profit Ac', 'Non-Secure') and (endoftenuredate is null or substr(endoftenuredate, 1, 11) = '1900-01-01')""",
        'id_field': 'tenancy_id'},
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

dq_dimensions_map = {
    'expect_first_name_column_value_lengths': 'VALIDITY',
    'expect_first_name_column_value_length': 'VALIDITY',
    'expect_uprn_column_values_to_match_regex': 'VALIDITY',
    'expect_person_type_values_to_be_in_set': 'CONSISTENCY',
    'expect_preferred_title_values_to_be_in_set': 'CONSISTENCY',
    'expect_uprn_not_to_be_null': 'COMPLETENESS',
    'expect_date_of_birth_to_be_between': 'VALIDITY',
    'expect_person_id_and_property_reference_column_values_to_be_unique_within_record': 'UNIQUENESS',
    'expect_property_ref_column_values_to_not_be_null': 'COMPLETENESS',
    'expect_member_full_name_column_value_lengths_between': 'VALIDITY',
    'expect_description_values_to_be_in_set': 'CONSISTENCY',
    'expect_tenancy_id_column_not_to_be_null': 'COMPLETENESS',
    'expect_start_of_tenure_date_column_not_to_be_null': 'COMPLETENESS',
    'expect_contact_type_column_values_to_not_be_null': 'COMPLETENESS',
    'expect_surname_column_value_length': 'VALIDITY',
    'expect_surname_column_value_lengths': 'VALIDITY',
    'expect_person_id_column_values_to_be_unique': 'UNIQUENESS',
    'expect_person_id_and_payment_reference_column_values_to_be_unique_within_record': 'UNIQUENESS',
    'expect_date_of_birth_column_values_to_not_be_null': 'COMPLETENESS',
    'expect_asset_type_values_to_be_in_set': 'CONSISTENCY',
    'expect_tenancy_id_and_property_reference_column_values_to_be_unique_within_record': 'UNIQUENESS',
    'expect_payment_reference_column_not_to_be_null': 'COMPLETENESS',
    'expect_target_id_column_values_to_not_be_null': 'COMPLETENESS',
    'expect_contact_type_column_values_to_be_in_set': 'CONSISTENCY',
    'expect_sub_type_column_values_to_not_be_null': 'COMPLETENESS',
    'expect_asset_id_not_to_be_null': 'COMPLETENESS',
    'expect_uprn_column_value_lengths_between': 'VALIDITY',
    'expect_person_id_column_values_to_not_be_null': 'COMPLETENESS',
    'expect_tenancy_id_and_payment_reference_column_values_to_be_unique_within_record': 'UNIQUENESS',
    'expect_tenure_code_column_not_to_be_null': 'COMPLETENESS',
    'expect_target_id_and_value_column_values_to_be_unique_within_record': 'UNIQUENESS',
    'expect_sub_type_column_values_to_be_in_set': 'CONSISTENCY',
    'expect_tenure_values_to_be_in_set_housing_dwellings_list': 'CONSISTENCY',
    'expect_contact_value_column_values_to_be_unique': 'UNIQUENESS',
    'expect_contact_value_column_values_to_not_be_null': 'COMPLETENESS',
    'expect_asset_type_not_to_be_null': 'COMPLETENESS',
    'expect_uprn_column_values_to_not_be_null': 'COMPLETENESS',
    'expect_target_type_column_values_to_be_in_set': 'CONSISTENCY',
}
