{{ config(
     enabled = var('financial_pmpm_enabled',var('claims_enabled',var('tuva_marts_enabled',False))) | as_bool
   )
}}

with claims_with_service_categories as (
  select
      patient_id
    , payer
    , "plan"
    , service_category_1
    , service_category_2
    , coalesce(claim_start_date,claim_end_date) as claim_date
    , paid_amount
    , allowed_amount
    , data_source
  from {{ ref('financial_pmpm__stg_medical_claim') }}
)

, medical_claims_year_month as (
  select
      patient_id
    , payer
    , "plan"
    , service_category_1
    , service_category_2
    {% if target.type == 'fabric' %}
        , cast({{ YEAR("claim_date") }} as {{ dbt.type_string() }} )
          + RIGHT(REPLICATE('0', 2) + cast({{ MONTH("claim_date") }} as {{ dbt.type_string() }} ), 2) AS year_month
    {% else %}
        , cast({{ date_part("year", "claim_date") }} as {{ dbt.type_string() }} )
          || lpad(cast({{ date_part("month", "claim_date") }} as {{ dbt.type_string() }} ), 2, '0') AS year_month
    {% endif %}
    , paid_amount
    , allowed_amount
    , data_source
  from claims_with_service_categories
)

, rx_claims as (
  select
      patient_id
    , payer
    , "plan"
    , 'Pharmacy' as service_category_1
    , cast(null as {{ dbt.type_string() }}) as service_category_2
    , coalesce(dispensing_date, paid_date) as claim_date
    , paid_amount
    , allowed_amount
    , data_source
  from {{ ref('financial_pmpm__stg_pharmacy_claim') }}
)

, rx_claims_year_month as (
  select
      patient_id
    , payer
    , "plan"
    , service_category_1
    , service_category_2
    {% if target.type == 'fabric' %}
        , cast(YEAR("claim_date") as {{ dbt.type_string() }} )
        + RIGHT(REPLICATE('0', 2) + cast(MONTH("claim_date") as {{ dbt.type_string() }}), 2) AS year_month
    {% else %}
        , cast({{ date_part("year", "claim_date") }} as {{ dbt.type_string() }} )
        || lpad(cast({{ date_part("month", "claim_date") }} as {{ dbt.type_string() }}), 2, '0') AS year_month
    {% endif %}
    , paid_amount
    , allowed_amount
    , data_source
  from rx_claims
)

, combine_medical_and_rx as (
select *
from medical_claims_year_month

union all

select *
from rx_claims_year_month
)

select
    patient_id
  , year_month
  , payer
  , "plan"
  , service_category_1
  , service_category_2
  , sum(paid_amount) as total_paid
  , sum(allowed_amount) as total_allowed
  , data_source
  , '{{ var('tuva_last_run')}}' as tuva_last_run
  from combine_medical_and_rx
group by
    patient_id
  , year_month
  , payer
  , "plan"
  , service_category_1
  , service_category_2
  , data_source