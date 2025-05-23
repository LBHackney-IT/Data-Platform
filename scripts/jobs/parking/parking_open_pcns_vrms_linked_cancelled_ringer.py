"""
Only need to change the table name and the query prototyped on the Athena UI
by replacing table_name and query_on_athena
Note: python file name should be the same as the table name
"""

from scripts.helpers.athena_helpers import create_update_table_with_partition
from scripts.helpers.helpers import get_glue_env_var

environment = get_glue_env_var("environment")

# The target table in liberator refined zone
table_name = "parking_open_pcns_vrms_linked_cancelled_ringer"

# The exact same query prototyped in pre-prod(stg) or prod Athena
query_on_athena = """
With cancelled_vrm as (
    Select distinct vrm as canx_vrm
    from "dataplatform-prod-liberator-refined-zone".pcnfoidetails_pcn_foi_full
    where import_date = (
            select max(import_date)
            from "dataplatform-prod-liberator-refined-zone".pcnfoidetails_pcn_foi_full
        )
        and (
            upper(cancellationgroup) like '%RINGER%'
            or upper(cancellationreason) like '%RINGER%'
        )
)
Select cancelled_vrm.*,
    concat(
        substr(Cast(pcnissuedate as varchar(10)), 1, 7),
        '-01'
    ) as MonthYear,
    progressionstage,
    debttype,
    pcn,
    pcnissuedate,
    pcnissuedatetime,
    street_location,
    whereonlocation,
    zone,
    usrn,
    contraventioncode,
    contraventionsuffix,
    vrm,
    vehiclemake,
    vehiclemodel,
    vehiclecolour,
    corresp_dispute_flag,
    registered_keeper_address,
    current_ticket_address
    /*Registered extracted post codes*/
,
    case
        when length(
            regexp_extract(
                registered_keeper_address,
                '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})'
            )
        ) = 0
        or regexp_extract(
            registered_keeper_address,
            '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})'
        ) is null
        or regexp_extract(
            registered_keeper_address,
            '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})'
        ) like ''
        or regexp_extract(
            registered_keeper_address,
            '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})'
        ) like ' ' then 'No Address'
        else regexp_extract(
            registered_keeper_address,
            '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})'
        )
    end as reg_add_extracted_post_code
    /*Current extracted post codes*/
,
    case
        when length(
            regexp_extract(
                current_ticket_address,
                '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})'
            )
        ) = 0
        or regexp_extract(
            current_ticket_address,
            '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})'
        ) is null
        or regexp_extract(
            current_ticket_address,
            '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})'
        ) like ''
        or regexp_extract(
            current_ticket_address,
            '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})'
        ) like ' ' then 'No Address'
        else regexp_extract(
            current_ticket_address,
            '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})'
        )
    end as curr_add_extracted_post_code,
    bailiff
    /*for partiion*/
,
    format_datetime(current_date, 'yyyy') AS import_year,
    format_datetime(current_date, 'MM') AS import_month,
    format_datetime(current_date, 'dd') AS import_day,
    format_datetime(current_date, 'yyyyMMdd') AS import_date
from "dataplatform-prod-liberator-refined-zone".pcnfoidetails_pcn_foi_full
    left join cancelled_vrm on cancelled_vrm.canx_vrm = pcnfoidetails_pcn_foi_full.vrm
where pcnfoidetails_pcn_foi_full.import_date = (
        select max(pcnfoidetails_pcn_foi_full.import_date)
        from "dataplatform-prod-liberator-refined-zone".pcnfoidetails_pcn_foi_full
    )
    and (
        pcnfoidetails_pcn_foi_full.pcn_canx_date is null
        and pcnfoidetails_pcn_foi_full.pcn_casecloseddate is null
    )
    and cancelled_vrm.canx_vrm is not null
    and pcnfoidetails_pcn_foi_full.warningflag = 0
order by cancelled_vrm.canx_vrm,
    progressionstage,
    debttype,
    pcnissuedatetime desc,
    pcn,
    street_location
"""

create_update_table_with_partition(
    environment=environment, query_on_athena=query_on_athena, table_name=table_name
)
