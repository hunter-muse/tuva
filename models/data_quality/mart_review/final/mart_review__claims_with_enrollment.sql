{{ config(
     enabled = var('claims_enabled',var('tuva_marts_enabled',False))
 | as_bool
   )
}}


SELECT
    mc.data_source,
    mc.year_month,
    
    SUM(CASE WHEN mm.patient_id IS NOT NULL THEN 1 ELSE 0 END) AS claims_with_enrollment,
    COUNT(*) AS claims,
    CAST(SUM(CASE WHEN mm.patient_id IS NOT NULL THEN 1 ELSE 0 END) / cast(COUNT(*) as decimal(18,2)) AS DECIMAL(18,2)) AS percentage_claims_with_enrollment
    , '{{ var('tuva_last_run')}}' as tuva_last_run
FROM {{ ref('mart_review__stg_medical_claim') }} mc
LEFT JOIN {{ ref('core__member_months')}} mm
    ON mc.patient_id = mm.patient_id
    AND mc.data_source = mm.data_source
    AND mc.year_month = mm.year_month
GROUP BY mc.data_source
, mc.year_month
    , '{{ var('tuva_last_run')}}'
