sql_config = {'person_reshape': {
    'sql': """SELECT *, cast(date_parse(substr(startdate, 1, 10), '%Y-%m-%d') as date) as startdate_parsed, cast(date_parse(substr(enddate, 1, 10), '%Y-%m-%d') as date) as enddate_parsed,  cast(date_parse(substr(dateofbirth, 1, 10), '%Y-%m-%d') as date) as dateofbirth_parsed FROM "housing-refined-zone"."person_reshape" where import_date=(select max(import_date) from "housing-refined-zone"."person_reshape") and enddate is NULL and type in ('Secure', 'Introductory')"""},
    'tenure_reshape': {
        'sql': """SELECT * FROM "housing-refined-zone"."tenure_reshape" where import_date>'20240412' and import_date=(select max(import_date) from "housing-refined-zone"."tenure_reshape" where import_date>'20240412') and isterminated=False and description in ('Secure', 'Introductory')"""},
    'contacts_reshape': {
        'sql': """SELECT id, targetid, createdat, contacttype, subtype, value, lastmodified, targettype, isactive, person_id, import_date  FROM "housing-refined-zone"."contacts_reshape"  where import_date=(select max(import_date) from "housing-refined-zone"."contacts_reshape") and isactive=True"""},
    'housing_homeowner_record_sheet': {
        'sql': """SELECT * FROM "housing-raw-zone"."housing_homeowner_record_sheet" where import_date=(select max(import_date) from "housing-raw-zone"."housing_homeowner_record_sheet")"""},
    'housing_dwellings_list': {
        'sql': """SELECT * FROM "housing-raw-zone"."housing_dwellings_list" where import_date=(select max(import_date) from "housing-raw-zone"."housing_homeowner_record_sheet")"""}
}

table_list = ['person_reshape', 'tenure_reshape', 'contacts_reshape', 'housing_homeowner_record_sheet',
              'housing_dwellings_list']
partition_keys = ['import_year', 'import_month', 'import_day', 'import_date']
