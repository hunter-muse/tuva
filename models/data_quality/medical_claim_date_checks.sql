with medical_claim_null AS (
SELECT 
    claim_id, 
    claim_line_number, 
    CASE WHEN claim_start_date is null then 1 else 0 end as claim_start_date_null, 
    CASE WHEN claim_end_date is null then 1 else 0 end as claim_end_date_null, 
    CASE WHEN claim_line_start_date is null then 1 else 0 end as claim_line_start_date_null, 
    CASE WHEN claim_line_end_date is null then 1 else 0 end as claim_line_end_date_null, 
    CASE WHEN admission_date is null then 1 else 0 end as admission_date_null, 
    CASE WHEN discharge_date is null then 1 else 0 end as discharge_date_null, 
    CASE WHEN paid_date IS NULL THEN 1 ELSE 0 END AS paid_date_null
FROM 
        {{ref('core__medical_claim')}}
) 

, claim_dates AS (
    SELECT 
        claim_id,
        COUNT(DISTINCT claim_start_date) AS distinct_claim_start_dates,
        COUNT(DISTINCT claim_end_date) AS distinct_claim_end_dates,
        COUNT(DISTINCT admission_date) AS distinct_admission_dates,
        COUNT(DISTINCT discharge_date) AS distinct_discharge_dates
    FROM 
        {{ref('core__medical_claim')}}
    GROUP BY 
        claim_id
)


/*
Multiple claim_start_date values
Multiple claim_end_date values
Multiple admission_date values
Multiple discharge_date values
*/

select 
'missing_claim_start_date' AS test_name,
'medical_claim' AS test_source, 
COALESCE(SUM(claim_start_date_null),0) AS flagged_records
FROM 
medical_claim_null

UNION 

select 
'missing_claim_end_date' AS test_name,
'medical_claim' AS test_source, 
COALESCE(SUM(claim_end_date_null),0) AS flagged_records
FROM 
medical_claim_null

UNION 

select 
'missing_claim_line_start_date' AS test_name,
'medical_claim' AS test_source, 
COALESCE(SUM(claim_line_start_date_null),0) AS flagged_records
FROM 
medical_claim_null

UNION 

select 
'missing_claim_line_end_date' AS test_name,
'medical_claim' AS test_source, 
COALESCE(SUM(claim_line_end_date_null),0) AS flagged_records
FROM 
medical_claim_null

UNION 

select 
'missing_admission_date' AS test_name,
'medical_claim' AS test_source, 
COALESCE(SUM(admission_date_null),0) AS flagged_records
FROM 
medical_claim_null

UNION 

select 
'missing_discharge_date' AS test_name,
'medical_claim' AS test_source, 
COALESCE(SUM(discharge_date_null),0) AS flagged_records
FROM 
medical_claim_null

UNION 

select 
'missing_paid_date' AS test_name,
'medical_claim' AS test_source, 
COALESCE(SUM(paid_date_null),0) AS flagged_records
FROM 
medical_claim_null

UNION 

select 
'multiple_claim_start_dates' AS test_name,
'medical_claim' AS test_source, 
COALESCE(COUNT(distinct_claim_start_dates),0) AS flagged_records
FROM 
claim_dates
where 
distinct_claim_start_dates > 1 

UNION 

select 
'multiple_claim_end_dates' AS test_name,
'medical_claim' AS test_source, 
COALESCE(COUNT(distinct_claim_end_dates),0) AS flagged_records
FROM 
claim_dates
where 
distinct_claim_end_dates > 1 

UNION 

select 
'multiple_admission_dates' AS test_name,
'medical_claim' AS test_source, 
COALESCE(COUNT(distinct_admission_dates),0) AS flagged_records
FROM 
claim_dates
where 
distinct_admission_dates > 1 

UNION 

select 
'multiple_discharge_dates' AS test_name,
'medical_claim' AS test_source, 
COALESCE(COUNT(distinct_discharge_dates),0) AS flagged_records
FROM 
claim_dates
where 
distinct_discharge_dates > 1 
