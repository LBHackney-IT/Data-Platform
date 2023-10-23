import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame
from scripts.helpers.helpers import (
    get_glue_env_var,
    get_latest_partitions,
    PARTITION_KEYS,
)


def sparkSqlQuery(glueContext, query, mapping, transformation_ctx) -> DynamicFrame:
    for alias, frame in mapping.items():
        frame.toDF().createOrReplaceTempView(alias)
    result = spark.sql(query)
    return DynamicFrame.fromDF(result, glueContext, transformation_ctx)


args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)
environment = get_glue_env_var("environment")

# Script generated for node Amazon S3 - Raw - liberator_pcn_qa
AmazonS3Rawliberator_pcn_qa_node1668440603311 = (
    glueContext.create_dynamic_frame.from_catalog(
        database="dataplatform-" + environment + "-liberator-raw-zone",
        push_down_predicate=(
            "to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)"
        ),
        table_name="liberator_pcn_qa",
        transformation_ctx="AmazonS3Rawliberator_pcn_qa_node1668440603311",
    )
)

# Script generated for node S3 bucket - refined - parking_correspondence_performance_records_with_pcn
S3bucketrefinedparking_correspondence_performance_records_with_pcn_node1 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-refined-zone",
    push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)",
    table_name="parking_correspondence_performance_records_with_pcn",
    transformation_ctx=(
        "S3bucketrefinedparking_correspondence_performance_records_with_pcn_node1"
    ),
)

# Script generated for node parking_raw_zone - parking_correspondence_performance_teams
parking_raw_zoneparking_correspondence_performance_teams_node1682093516418 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)",
    table_name="parking_correspondence_performance_teams",
    transformation_ctx=(
        "parking_raw_zoneparking_correspondence_performance_teams_node1682093516418"
    ),
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/*
For use in Google Studio to calculate the Correspondence performance for each calendar month Total number of cases and Total number of QA reviews for each month.

14/11/2022 - Created job
21/04/2023 - added teams data from google spreadsheet load - https://docs.google.com/spreadsheets/d/1zxZXX1_qU9NW93Ug1JUy7aXsnTz45qIj7Zftmi9trbI/edit?usp=sharing
09/08/2023 - added new officers
*/
with qa_tot as (select 
case 
when qa_doc_created_by like 'AFalade' then 'Ayo Falade'
when qa_doc_created_by like 'BAhmed' then 'Bilal Ahmed Choudhury'
--Claire Glover	when qa_doc_created_by like '' then ''
when qa_doc_created_by like 'djulian' then 'Damien Julian'
when qa_doc_created_by like 'dgardner' then 'Daniel Gardner'
when qa_doc_created_by like 'DLagatolla' then 'Davide Lagatolla'
when qa_doc_created_by like 'DLagatolla' then 'Davide Lagattolla'
--Earle Nottingham	when qa_doc_created_by like '' then ''
when qa_doc_created_by like 'EPassos' then 'Edson Passos'--Edson Passos	
when qa_doc_created_by like 'esamson' then 'Emma Samson'
when qa_doc_created_by like 'hpatel' then 'Hamza Patel'
when qa_doc_created_by like 'iaHenry' then 'Ian Henry'
when qa_doc_created_by like 'Imali' then 'Imran Ali'
when qa_doc_created_by like 'JAhmed' then 'Jahed Ahmed'
when qa_doc_created_by like 'mmagnusson' then 'Magnus Magnusson'
when qa_doc_created_by like 'mwalters' then 'Melanie Walters'
--Nohaad Al-othmani	when qa_doc_created_by like '' then ''
when qa_doc_created_by like 'OOnisemo' then 'Olabisi Onisemo'
when qa_doc_created_by like 'oolagbaju' then 'Olamide Olagbaju'
when qa_doc_created_by like 'PShakes' then 'Pameta Shakes'
when qa_doc_created_by like 'rcampbell' then 'Rhys Campbell'
when qa_doc_created_by like 'sspanos' then 'Savva Spanos'
when qa_doc_created_by like 'ssunilkumar' then 'Shirley Sunilkumar'
when qa_doc_created_by like 'sbaxter' then 'Sonia Baxter'
when qa_doc_created_by like 'WElegbede' then 'Wasilat Elegbede'
when qa_doc_created_by like 'yyahya' then 'Yusuf Yahya'
when qa_doc_created_by like 'admin' then 'ADMIN'
when qa_doc_created_by like 'albrooks' then 'Alan Brooks'
when qa_doc_created_by like 'bmoloney' then 'bmoloney'
when qa_doc_created_by like 'cbeasley' then 'cbeasley'
when qa_doc_created_by like 'EAbankwa' then 'EAbankwa'
when qa_doc_created_by like 'EOsagiede' then 'EOsagiede'
when qa_doc_created_by like 'khamad-okunnu' then 'khamad-okunnu'
when qa_doc_created_by like 'toike' then 'Tayo Oike'
when qa_doc_created_by like 'MIbabu' then 'Muhammad Ismail Bin Abu'
when qa_doc_created_by like 'stopic' then 'Sandi Topic'
when qa_doc_created_by like 'mdayang' then 'Maria Dayang'
when qa_doc_created_by like 'jskrbic' then 'Jovana Skrbic'
when qa_doc_created_by like 'ihaji' then 'Irfan Haji'
when qa_doc_created_by like 'gpugliese' then 'Gianmarco Pugliese'
when qa_doc_created_by like 'csims' then 'Colin Sims'
when qa_doc_created_by like 'ahenry' then 'Ainsley Henry'

else qa_doc_created_by end as qa_link_officer_name_corresp
,concat(qa_doc_created_by,concat(substr(Cast(qa_done as varchar(10)),1, 7), '-01')  ) as qatot_unique_id
,qa_doc_created_by as qatot_qa_doc_created_by
,concat(substr(Cast(qa_done as varchar(10)),1, 7), '-01') as MonthYear_qadone
,count(*) as qatot_total_reviews

 FROM liberator_pcn_qa where import_date =(SELECT max(import_date) FROM liberator_pcn_qa )
 group by 
 case 
when qa_doc_created_by like 'AFalade' then 'Ayo Falade'
when qa_doc_created_by like 'BAhmed' then 'Bilal Ahmed Choudhury'
--Claire Glover	when qa_doc_created_by like '' then ''
when qa_doc_created_by like 'djulian' then 'Damien Julian'
when qa_doc_created_by like 'dgardner' then 'Daniel Gardner'
when qa_doc_created_by like 'DLagatolla' then 'Davide Lagatolla'
when qa_doc_created_by like 'DLagatolla' then 'Davide Lagattolla'
--Earle Nottingham	when qa_doc_created_by like '' then ''
when qa_doc_created_by like 'EPassos' then 'Edson Passos'--Edson Passos	
when qa_doc_created_by like 'esamson' then 'Emma Samson'
when qa_doc_created_by like 'hpatel' then 'Hamza Patel'
when qa_doc_created_by like 'iaHenry' then 'Ian Henry'
when qa_doc_created_by like 'Imali' then 'Imran Ali'
when qa_doc_created_by like 'JAhmed' then 'Jahed Ahmed'
when qa_doc_created_by like 'mmagnusson' then 'Magnus Magnusson'
when qa_doc_created_by like 'mwalters' then 'Melanie Walters'
--Nohaad Al-othmani	when qa_doc_created_by like '' then ''
when qa_doc_created_by like 'OOnisemo' then 'Olabisi Onisemo'
when qa_doc_created_by like 'oolagbaju' then 'Olamide Olagbaju'
when qa_doc_created_by like 'PShakes' then 'Pameta Shakes'
when qa_doc_created_by like 'rcampbell' then 'Rhys Campbell'
when qa_doc_created_by like 'sspanos' then 'Savva Spanos'
when qa_doc_created_by like 'ssunilkumar' then 'Shirley Sunilkumar'
when qa_doc_created_by like 'sbaxter' then 'Sonia Baxter'
when qa_doc_created_by like 'WElegbede' then 'Wasilat Elegbede'
when qa_doc_created_by like 'yyahya' then 'Yusuf Yahya'
when qa_doc_created_by like 'admin' then 'ADMIN'
when qa_doc_created_by like 'albrooks' then 'Alan Brooks'
when qa_doc_created_by like 'bmoloney' then 'bmoloney'
when qa_doc_created_by like 'cbeasley' then 'cbeasley'
when qa_doc_created_by like 'EAbankwa' then 'EAbankwa'
when qa_doc_created_by like 'EOsagiede' then 'EOsagiede'
when qa_doc_created_by like 'khamad-okunnu' then 'khamad-okunnu'
when qa_doc_created_by like 'toike' then 'Tayo Oike'
when qa_doc_created_by like 'MIbabu' then 'Muhammad Ismail Bin Abu'
when qa_doc_created_by like 'stopic' then 'Sandi Topic'
when qa_doc_created_by like 'mdayang' then 'Maria Dayang'
when qa_doc_created_by like 'jskrbic' then 'Jovana Skrbic'
when qa_doc_created_by like 'ihaji' then 'Irfan Haji'
when qa_doc_created_by like 'gpugliese' then 'Gianmarco Pugliese'
when qa_doc_created_by like 'csims' then 'Colin Sims'
when qa_doc_created_by like 'ahenry' then 'Ainsley Henry'
else qa_doc_created_by end -- as qa_link_officer_name_corresp
,concat(qa_doc_created_by,concat(substr(Cast(qa_done as varchar(10)),1, 7), '-01')  ) 
,qa_doc_created_by 
,concat(substr(Cast(qa_done as varchar(10)),1, 7), '-01')
 
)
, corresp_tot as (select
case 
when response_written_by like 'Ayo Falade' then 'AFalade'
when response_written_by like  'Bilal Ahmed Choudhury' then 'BAhmed'
when response_written_by like  'Damien Julian' then 'djulian'
when response_written_by like  'Daniel Gardner' then 'dgardner'
when response_written_by like  'Davide Lagatolla' then 'DLagatolla'
when response_written_by like  'Davide Lagattolla' then 'DLagatolla'
when response_written_by like  'Emma Samson' then 'esamson' 
when response_written_by like 'Hamza Patel'  then 'hpatel'
when response_written_by like  'Ian Henry' then 'iaHenry'
when response_written_by like  'Imran Ali' then 'Imali'
when response_written_by like 'Jahed Ahmed'  then 'JAhmed'
when response_written_by like  'Magnus Magnusson' then 'mmagnusson'
when response_written_by like  'Olabisi Onisemo' then 'OOnisemo'
when response_written_by like  'Olamide Olagbaju' then 'oolagbaju'
when response_written_by like  'Pameta Shakes' then 'PShakes'
when response_written_by like  'Rhys Campbell' then 'rcampbell'
when response_written_by like  'Savva Spanos' then 'sspanos'
when response_written_by like  'Shirley Sunilkumar' then 'ssunilkumar'
when response_written_by like  'Sonia Baxter' then 'sbaxter'
when response_written_by like  'Wasilat Elegbede' then 'WElegbede'
when response_written_by like  'Claire Glover' then 'Claire Glover'
when response_written_by like  'Earle Nottingham' then 'Earle Nottingham'
when response_written_by like  'Edson Passos' then 'EPassos'
when response_written_by like  'Melanie Walters' then 'Melanie Walters'
when response_written_by like  'Nohaad Al-othmani' then 'Nohaad Al-othmani'
when response_written_by like  'Yusuf Yahya' then 'Yusuf Yahya'
when response_written_by like 'Ainsley Henry' then 'ahenry'  
when response_written_by like 'Colin Sims' then 'csims' 
when response_written_by like 'Gianmarco Pugliese' then 'gpugliese'
when response_written_by like 'Irfan Haji' then 'ihaji'
when response_written_by like 'Jovana Skrbic' then  'jskrbic'
when response_written_by like 'Maria Dayang' then 'mdayang'
when response_written_by like 'Sandi Topic' then 'stopic'
when response_written_by like  'Muhammad Ismail Bin Abu' then 'MIbabu'
when response_written_by like  'Tayo Oike' then 'toike'
else response_written_by end as corresp_link_officer_name_qa
,concat(case 
when response_written_by like 'Ayo Falade' then 'AFalade'
when response_written_by like  'Bilal Ahmed Choudhury' then 'BAhmed'
when response_written_by like  'Damien Julian' then 'djulian'
when response_written_by like  'Daniel Gardner' then 'dgardner'
when response_written_by like  'Davide Lagatolla' then 'DLagatolla'
when response_written_by like  'Davide Lagattolla' then 'DLagatolla'
when response_written_by like  'Emma Samson' then 'esamson' 
when response_written_by like 'Hamza Patel'  then 'hpatel'
when response_written_by like  'Ian Henry' then 'iaHenry'
when response_written_by like  'Imran Ali' then 'Imali'
when response_written_by like 'Jahed Ahmed'  then 'JAhmed'
when response_written_by like  'Magnus Magnusson' then 'mmagnusson'
when response_written_by like  'Olabisi Onisemo' then 'OOnisemo'
when response_written_by like  'Olamide Olagbaju' then 'oolagbaju'
when response_written_by like  'Pameta Shakes' then 'PShakes'
when response_written_by like  'Rhys Campbell' then 'rcampbell'
when response_written_by like  'Savva Spanos' then 'sspanos'
when response_written_by like  'Shirley Sunilkumar' then 'ssunilkumar'
when response_written_by like  'Sonia Baxter' then 'sbaxter'
when response_written_by like  'Wasilat Elegbede' then 'WElegbede'
when response_written_by like  'Claire Glover' then 'Claire Glover'
when response_written_by like  'Earle Nottingham' then 'Earle Nottingham'
when response_written_by like  'Edson Passos' then 'EPassos'
when response_written_by like  'Melanie Walters' then 'Melanie Walters'
when response_written_by like  'Nohaad Al-othmani' then 'Nohaad Al-othmani'
when response_written_by like  'Yusuf Yahya' then 'Yusuf Yahya'
when response_written_by like 'Ainsley Henry' then 'ahenry'  
when response_written_by like 'Colin Sims' then 'csims' 
when response_written_by like 'Gianmarco Pugliese' then 'gpugliese'
when response_written_by like 'Irfan Haji' then 'ihaji'
when response_written_by like 'Jovana Skrbic' then  'jskrbic'
when response_written_by like 'Maria Dayang' then 'mdayang'
when response_written_by like 'Sandi Topic' then 'stopic'
when response_written_by like  'Muhammad Ismail Bin Abu' then 'MIbabu'
when response_written_by like  'Tayo Oike' then 'toike'
else response_written_by end,concat(substr(Cast(response_generated_at as varchar(10)),1, 7), '-01')  ) as corresptot_qa_unique_id
,concat(response_written_by,concat(substr(Cast(response_generated_at as varchar(10)),1, 7), '-01')  ) as corresptot_unique_id
,response_written_by as corresptot_response_written_by
,monthyear as monthyear_corresp
,count(*) as corresptot_total_cases

from parking_correspondence_performance_records_with_pcn
where import_date =(select max(import_date) from parking_correspondence_performance_records_with_pcn)
AND parking_correspondence_performance_records_with_pcn.response_generated_at != ''

group by
case 
when response_written_by like 'Ayo Falade' then 'AFalade'
when response_written_by like  'Bilal Ahmed Choudhury' then 'BAhmed'
when response_written_by like  'Damien Julian' then 'djulian'
when response_written_by like  'Daniel Gardner' then 'dgardner'
when response_written_by like  'Davide Lagatolla' then 'DLagatolla'
when response_written_by like  'Davide Lagattolla' then 'DLagatolla'
when response_written_by like  'Emma Samson' then 'esamson' 
when response_written_by like 'Hamza Patel'  then 'hpatel'
when response_written_by like  'Ian Henry' then 'iaHenry'
when response_written_by like  'Imran Ali' then 'Imali'
when response_written_by like 'Jahed Ahmed'  then 'JAhmed'
when response_written_by like  'Magnus Magnusson' then 'mmagnusson'
when response_written_by like  'Olabisi Onisemo' then 'OOnisemo'
when response_written_by like  'Olamide Olagbaju' then 'oolagbaju'
when response_written_by like  'Pameta Shakes' then 'PShakes'
when response_written_by like  'Rhys Campbell' then 'rcampbell'
when response_written_by like  'Savva Spanos' then 'sspanos'
when response_written_by like  'Shirley Sunilkumar' then 'ssunilkumar'
when response_written_by like  'Sonia Baxter' then 'sbaxter'
when response_written_by like  'Wasilat Elegbede' then 'WElegbede'
when response_written_by like  'Claire Glover' then 'Claire Glover'
when response_written_by like  'Earle Nottingham' then 'Earle Nottingham'
when response_written_by like  'Edson Passos' then 'EPassos'
when response_written_by like  'Melanie Walters' then 'Melanie Walters'
when response_written_by like  'Nohaad Al-othmani' then 'Nohaad Al-othmani'
when response_written_by like  'Yusuf Yahya' then 'Yusuf Yahya'
when response_written_by like 'Ainsley Henry' then 'ahenry'  
when response_written_by like 'Colin Sims' then 'csims' 
when response_written_by like 'Gianmarco Pugliese' then 'gpugliese'
when response_written_by like 'Irfan Haji' then 'ihaji'
when response_written_by like 'Jovana Skrbic' then  'jskrbic'
when response_written_by like 'Maria Dayang' then 'mdayang'
when response_written_by like 'Sandi Topic' then 'stopic'
when response_written_by like  'Muhammad Ismail Bin Abu' then 'MIbabu'
when response_written_by like  'Tayo Oike' then 'toike'
else response_written_by end -- as corresp_link_officer_name_qa
,concat(case 
when response_written_by like 'Ayo Falade' then 'AFalade'
when response_written_by like  'Bilal Ahmed Choudhury' then 'BAhmed'
when response_written_by like  'Damien Julian' then 'djulian'
when response_written_by like  'Daniel Gardner' then 'dgardner'
when response_written_by like  'Davide Lagatolla' then 'DLagatolla'
when response_written_by like  'Davide Lagattolla' then 'DLagatolla'
when response_written_by like  'Emma Samson' then 'esamson' 
when response_written_by like 'Hamza Patel'  then 'hpatel'
when response_written_by like  'Ian Henry' then 'iaHenry'
when response_written_by like  'Imran Ali' then 'Imali'
when response_written_by like 'Jahed Ahmed'  then 'JAhmed'
when response_written_by like  'Magnus Magnusson' then 'mmagnusson'
when response_written_by like  'Olabisi Onisemo' then 'OOnisemo'
when response_written_by like  'Olamide Olagbaju' then 'oolagbaju'
when response_written_by like  'Pameta Shakes' then 'PShakes'
when response_written_by like  'Rhys Campbell' then 'rcampbell'
when response_written_by like  'Savva Spanos' then 'sspanos'
when response_written_by like  'Shirley Sunilkumar' then 'ssunilkumar'
when response_written_by like  'Sonia Baxter' then 'sbaxter'
when response_written_by like  'Wasilat Elegbede' then 'WElegbede'
when response_written_by like  'Claire Glover' then 'Claire Glover'
when response_written_by like  'Earle Nottingham' then 'Earle Nottingham'
when response_written_by like  'Edson Passos' then 'EPassos'
when response_written_by like  'Melanie Walters' then 'Melanie Walters'
when response_written_by like  'Nohaad Al-othmani' then 'Nohaad Al-othmani'
when response_written_by like  'Yusuf Yahya' then 'Yusuf Yahya'
when response_written_by like 'Ainsley Henry' then 'ahenry'  
when response_written_by like 'Colin Sims' then 'csims' 
when response_written_by like 'Gianmarco Pugliese' then 'gpugliese'
when response_written_by like 'Irfan Haji' then 'ihaji'
when response_written_by like 'Jovana Skrbic' then  'jskrbic'
when response_written_by like 'Maria Dayang' then 'mdayang'
when response_written_by like 'Sandi Topic' then 'stopic'
when response_written_by like  'Muhammad Ismail Bin Abu' then 'MIbabu'
when response_written_by like  'Tayo Oike' then 'toike'
else response_written_by end,concat(substr(Cast(response_generated_at as varchar(10)),1, 7), '-01')  )
,concat(response_written_by,concat(substr(Cast(response_generated_at as varchar(10)),1, 7), '-01')  ) 
,response_written_by 
,monthyear
)
, team as (
select distinct start_date as t_start_date
,end_date   as t_end_date
,team   as t_team
,team_name   as t_team_name
,role   as t_role
,forename   as t_forename
,surname   as t_surname
,full_name   as t_full_name
,qa_doc_created_by   as t_qa_doc_created_by
,qa_doc_full_name   as t_qa_doc_full_name
,post_title   as t_post_title
,notes  as t_notes
,import_date   as t_import_date--* 
from parking_correspondence_performance_teams where import_date = (select max(import_date)  from parking_correspondence_performance_teams ) 
)


SELECT
--from qa_total
qa_tot.qa_link_officer_name_corresp
,qa_tot.qatot_unique_id
,qa_tot.qatot_qa_doc_created_by
,qa_tot.MonthYear_qadone
,qa_tot.qatot_total_reviews

--from correspondence_total
,corresp_tot.corresp_link_officer_name_qa
,corresp_tot.corresptot_qa_unique_id
,corresp_tot.corresptot_unique_id
,corresp_tot.corresptot_response_written_by
,corresp_tot.monthyear_corresp
,corresp_tot.corresptot_total_cases

--from qa
,case 
when qa_doc_created_by like 'AFalade' then 'Ayo Falade'
when qa_doc_created_by like 'BAhmed' then 'Bilal Ahmed Choudhury'
--Claire Glover	when qa_doc_created_by like '' then ''
when qa_doc_created_by like 'djulian' then 'Damien Julian'
when qa_doc_created_by like 'dgardner' then 'Daniel Gardner'
when qa_doc_created_by like 'DLagatolla' then 'Davide Lagatolla'
when qa_doc_created_by like 'DLagatolla' then 'Davide Lagattolla'
--Earle Nottingham	when qa_doc_created_by like '' then ''
when qa_doc_created_by like 'EPassos' then 'Edson Passos'--Edson Passos	
when qa_doc_created_by like 'esamson' then 'Emma Samson'
when qa_doc_created_by like 'hpatel' then 'Hamza Patel'
when qa_doc_created_by like 'iaHenry' then 'Ian Henry'
when qa_doc_created_by like 'Imali' then 'Imran Ali'
when qa_doc_created_by like 'JAhmed' then 'Jahed Ahmed'
when qa_doc_created_by like 'mmagnusson' then 'Magnus Magnusson'
when qa_doc_created_by like 'mwalters' then 'Melanie Walters'
--Nohaad Al-othmani	when qa_doc_created_by like '' then ''
when qa_doc_created_by like 'OOnisemo' then 'Olabisi Onisemo'
when qa_doc_created_by like 'oolagbaju' then 'Olamide Olagbaju'
when qa_doc_created_by like 'PShakes' then 'Pameta Shakes'
when qa_doc_created_by like 'rcampbell' then 'Rhys Campbell'
when qa_doc_created_by like 'sspanos' then 'Savva Spanos'
when qa_doc_created_by like 'ssunilkumar' then 'Shirley Sunilkumar'
when qa_doc_created_by like 'sbaxter' then 'Sonia Baxter'
when qa_doc_created_by like 'WElegbede' then 'Wasilat Elegbede'
when qa_doc_created_by like 'yyahya' then 'Yusuf Yahya'
when qa_doc_created_by like 'admin' then 'ADMIN'
when qa_doc_created_by like 'albrooks' then 'Alan Brooks'
when qa_doc_created_by like 'bmoloney' then 'bmoloney'
when qa_doc_created_by like 'cbeasley' then 'cbeasley'
when qa_doc_created_by like 'EAbankwa' then 'EAbankwa'
when qa_doc_created_by like 'EOsagiede' then 'EOsagiede'
when qa_doc_created_by like 'khamad-okunnu' then 'khamad-okunnu'
when qa_doc_created_by like 'toike' then 'Tayo Oike'
when qa_doc_created_by like 'MIbabu' then 'Muhammad Ismail Bin Abu'
when qa_doc_created_by like 'stopic' then 'Sandi Topic'
when qa_doc_created_by like 'mdayang' then 'Maria Dayang'
when qa_doc_created_by like 'jskrbic' then 'Jovana Skrbic'
when qa_doc_created_by like 'ihaji' then 'Irfan Haji'
when qa_doc_created_by like 'gpugliese' then 'Gianmarco Pugliese'
when qa_doc_created_by like 'csims' then 'Colin Sims'
when qa_doc_created_by like 'ahenry' then 'Ainsley Henry'
else qa_doc_created_by end as link_officer_name
,* 

FROM liberator_pcn_qa 

left join qa_tot on qa_tot.qatot_unique_id = concat(qa_doc_created_by,concat(substr(Cast(qa_done as varchar(10)),1, 7), '-01')  )
left join corresp_tot on corresp_tot.corresptot_qa_unique_id = concat(qa_doc_created_by,concat(substr(Cast(qa_done as varchar(10)),1, 7), '-01')  )
left join team on upper(team.t_qa_doc_created_by) = upper(liberator_pcn_qa.qa_doc_created_by)

where import_date =(SELECT max(import_date) FROM liberator_pcn_qa)

order by qa_done desc
"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "liberator_pcn_qa": AmazonS3Rawliberator_pcn_qa_node1668440603311,
        "parking_correspondence_performance_records_with_pcn": S3bucketrefinedparking_correspondence_performance_records_with_pcn_node1,
        "parking_correspondence_performance_teams": parking_raw_zoneparking_correspondence_performance_teams_node1682093516418,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-"
    + environment
    + "-refined-zone/parking/liberator/parking_correspondence_performance_qa_with_totals_gds/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    compression="snappy",
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="parking_correspondence_performance_qa_with_totals_gds",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
