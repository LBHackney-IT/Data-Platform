"""
Only need to change the table name and the query prototyped on the Athena UI
by replacing table_name and query_on_athena
Note: python file name should be the same as the table name
"""

from scripts.helpers.athena_helpers import create_update_table_with_partition
from scripts.helpers.helpers import get_glue_env_var

environment = get_glue_env_var("environment")

# The target table in liberator refined zone
table_name = "parking_pcn_dvla_response_no_address"

# The exact same query prototyped in pre-prod(stg) or prod Athena
query_on_athena = """
/*
 All VRMs with PCNs response from DVLA has no address still open and not due to be written off

 Criteria:
 All PCNs issued
 and is not void
 and does not have a warning flag
 and is not vda and pcn issue date before '2021-06-01'  or can be vda after pcn issue date '2021-05-31'
 and has had a dvla_request
 and has had a dvla_response
 and registered_keeper_address is not null
 and has not had a PCN cancelled date
 and has not had a pcn_casecloseddate
 and next progression stage not like 'WRITEOFF'

 11/07/2024 - Created

 */
with no_resp_ceo as (
  Select distinct vrm as vrm_ceo,
    count(distinct pcn) as num_pcns_ceo --, LISTAGG(pcn, '   ') WITHIN GROUP (ORDER BY vrm) as vl_multi_pcns_ceo
,
    array_join(
      array_distinct(array_agg(pcnfoidetails_pcn_foi_full.pcn)),
      -- aggregate that collects distinct values into an array
      ' | ' -- delimiter
    ) as vl_multi_pcns_ceo
  FROM "dataplatform-prod-liberator-refined-zone".pcnfoidetails_pcn_foi_full
  WHERE pcnfoidetails_pcn_foi_full.import_date = (
      SELECT max(pcnfoidetails_pcn_foi_full.import_date)
      from "dataplatform-prod-liberator-refined-zone".pcnfoidetails_pcn_foi_full
    )
    and isvoid = 0
    and warningflag = 0
    and (
      (
        isvda = 0
        and cast(pcnissuedate as date) < cast('2021-06-01' as date)
      )
      or (
        cast(pcnissuedate as date) > cast('2021-05-31' as date)
      )
    )
    and dvla_request is not null
    and dvla_response is not null
    and registered_keeper_address = ''
    and pcn_canx_date is null
    and pcn_casecloseddate is null
    and upper(debttype) like 'CEO'
    and upper(nextprogressionstage) not like 'WRITEOFF' --and cast(pcnissuedate as date) > cast('2019-12-31' as date) and cast(pcnissuedate as date) < cast('2024-01-01' as date)--Parking Tickets issued between 01/01/2020 and 31/12/2023.
  group by vrm
  order by vrm_ceo
),
no_resp_cctv as (
  Select distinct vrm as vrm_cctv,
    count(distinct pcn) as num_pcns_cctv --, LISTAGG(pcn, '   ') WITHIN GROUP (ORDER BY vrm) as vl_multi_pcns_cctv
,
    array_join(
      array_distinct(array_agg(pcnfoidetails_pcn_foi_full.pcn)),
      -- aggregate that collects distinct values into an array
      ' | ' -- delimiter
    ) as vl_multi_pcns_cctv
  FROM "dataplatform-prod-liberator-refined-zone".pcnfoidetails_pcn_foi_full
  WHERE pcnfoidetails_pcn_foi_full.import_date = (
      SELECT max(pcnfoidetails_pcn_foi_full.import_date)
      from "dataplatform-prod-liberator-refined-zone".pcnfoidetails_pcn_foi_full
    )
    and isvoid = 0
    and warningflag = 0
    and (
      (
        isvda = 0
        and cast(pcnissuedate as date) < cast('2021-06-01' as date)
      )
      or (
        cast(pcnissuedate as date) > cast('2021-05-31' as date)
      )
    )
    and dvla_request is not null
    and dvla_response is not null
    and registered_keeper_address = ''
    and pcn_canx_date is null
    and pcn_casecloseddate is null
    and upper(debttype) in (
      'CCTV MOVING TRAFFIC',
      'CCTV STATIC',
      'CCTV BUS LANE'
    )
    and upper(nextprogressionstage) not like 'WRITEOFF' --and cast(pcnissuedate as date) > cast('2019-12-31' as date) and cast(pcnissuedate as date) < cast('2024-01-01' as date)--Parking Tickets issued between 01/01/2020 and 31/12/2023.
  group by vrm
  order by vrm
) -- summary sent to DRT
Select distinct pcnfoidetails_pcn_foi_full.vrm,
  min(
    cast(
      substr(Cast(pcnissuedate as varchar(10)), 1, 10) as date
    )
  ) as min_pcnissuedate,
  max(
    cast(
      substr(Cast(pcnissuedate as varchar(10)), 1, 10) as date
    )
  ) as max_pcnissuedate,
  count(distinct pcn) as num_pcns_all --, LISTAGG(pcn, '   ') WITHIN GROUP (ORDER BY vrm) as vl_multi_pcns_all
,
  array_join(
    array_distinct(array_agg(pcnfoidetails_pcn_foi_full.pcn)),
    -- aggregate that collects distinct values into an array
    ' | ' -- delimiter
  ) as vl_multi_pcns_all --CEO PCNs
,
  num_pcns_ceo,
  vl_multi_pcns_ceo --CCTV PCNs
,
  num_pcns_cctv,
  vl_multi_pcns_cctv
  /*Partitions*/
,
  pcnfoidetails_pcn_foi_full.import_year,
  pcnfoidetails_pcn_foi_full.import_month,
  pcnfoidetails_pcn_foi_full.import_day,
  pcnfoidetails_pcn_foi_full.import_date
FROM "dataplatform-prod-liberator-refined-zone".pcnfoidetails_pcn_foi_full
  left join no_resp_cctv on no_resp_cctv.vrm_cctv = pcnfoidetails_pcn_foi_full.vrm
  left join no_resp_ceo on no_resp_ceo.vrm_ceo = pcnfoidetails_pcn_foi_full.vrm
WHERE pcnfoidetails_pcn_foi_full.import_date = (
    SELECT max(pcnfoidetails_pcn_foi_full.import_date)
    from "dataplatform-prod-liberator-refined-zone".pcnfoidetails_pcn_foi_full
  )
  and isvoid = 0
  and warningflag = 0
  and (
    (
      isvda = 0
      and cast(pcnissuedate as date) < cast('2021-06-01' as date)
    )
    or (
      cast(pcnissuedate as date) > cast('2021-05-31' as date)
    )
  )
  and dvla_request is not null
  and dvla_response is not null
  and registered_keeper_address = ''
  and pcn_canx_date is null
  and pcn_casecloseddate is null
  and upper(nextprogressionstage) not like 'WRITEOFF' --and cast(pcnissuedate as date) > cast('2019-12-31' as date) and cast(pcnissuedate as date) < cast('2024-01-01' as date)--Parking Tickets issued between 01/01/2020 and 31/12/2023.
group by pcnfoidetails_pcn_foi_full.vrm --CEO PCNs
,
  num_pcns_ceo,
  vl_multi_pcns_ceo --CCTV PCNs
,
  num_pcns_cctv,
  vl_multi_pcns_cctv
  /*Partitions*/
,
  pcnfoidetails_pcn_foi_full.import_year,
  pcnfoidetails_pcn_foi_full.import_month,
  pcnfoidetails_pcn_foi_full.import_day,
  pcnfoidetails_pcn_foi_full.import_date
order by pcnfoidetails_pcn_foi_full.vrm
"""

create_update_table_with_partition(
    environment=environment, query_on_athena=query_on_athena, table_name=table_name
)
