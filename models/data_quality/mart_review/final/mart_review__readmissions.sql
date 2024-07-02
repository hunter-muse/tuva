{{ config(
     enabled = var('claims_enabled',var('tuva_marts_enabled',False))
 | as_bool
   )
}}

SELECT *
FROM {{ ref('readmissions__readmission_summary') }}
WHERE index_admission_flag = 1
