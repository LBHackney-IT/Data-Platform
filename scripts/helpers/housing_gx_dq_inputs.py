from scripts.housing.housing_person_reshape_gx_suite import suite as person_reshape_suite
from scripts.housing.housing_tenure_reshape_gx_suite import suite as tenure_reshape_suite
from scripts.housing.housing_contacts_reshape_gx_suite import suite as contacts_reshape_suite

gx_dq_housing_config = {'person_reshape': {
    'sql': """SELECT * FROM "housing-refined-zone"."person_reshape" where import_date=(select max(import_date) from "housing-refined-zone"."person_reshape") and enddate is NULL and type in ('Secure', 'Introductory')""",
    'suite': person_reshape_suite},
    'tenure_reshape': {
        'sql': """SELECT * FROM "housing-refined-zone"."tenure_reshape" where import_date>'20240412' and import_date=(select max(import_date) from "housing-refined-zone"."tenure_reshape" where import_date>'20240412') and isterminated=False and description in ('Secure', 'Introductory')""",
        'suite': tenure_reshape_suite},
    'contacts_reshape': {
        'sql': """SELECT id, targetid, createdat, contacttype, subtype, value, lastmodified, targettype, isactive, person_id, import_date  FROM "housing-refined-zone"."contacts_reshape"  where import_date=(select max(import_date) from "housing-refined-zone"."contacts_reshape") and isactive=True""",
        'suite': contacts_reshape_suite}
}

table_list = ['person_reshape', 'tenure_reshape', 'contacts_reshape']
partition_keys = ['import_year', 'import_month', 'import_day', 'import_date']
