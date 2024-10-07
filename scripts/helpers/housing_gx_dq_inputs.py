sql_config = {'person_reshape': {
    'sql': """SELECT * FROM "housing-refined-zone"."person_reshape" where import_date=(select max(import_date) from "housing-refined-zone"."person_reshape") and enddate is NULL and type in ('Secure', 'Introductory')"""},
    'tenure_reshape': {
        'sql': """SELECT * FROM "housing-refined-zone"."tenure_reshape" where import_date>'20240412' and import_date=(select max(import_date) from "housing-refined-zone"."tenure_reshape" where import_date>'20240412') and isterminated=False and description in ('Secure', 'Introductory')"""},
    'contacts_reshape': {
        'sql': """SELECT id, targetid, createdat, contacttype, subtype, value, lastmodified, targettype, isactive, person_id, import_date  FROM "housing-refined-zone"."contacts_reshape"  where import_date=(select max(import_date) from "housing-refined-zone"."contacts_reshape") and isactive=True"""}
}

table_list = ['person_reshape', 'tenure_reshape', 'contacts_reshape']
partition_keys = ['import_year', 'import_month', 'import_day', 'import_date']
