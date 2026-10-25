-- A/B TESTING PORTFOLIO PROJECT — SQL WORKFLOW
-- Project: Does a Simpler Checkout Increase Conversion?
-- Data are synthetic and do not represent actual Amazon customer data or performance.
-- Prerequisites: import these CSVs as tables in PostgreSQL:
--   data/checkout_exposures.csv    -> checkout_exposures
--   data/session_outcomes.csv      -> session_outcomes
--   data/checkout_orders.csv       -> checkout_orders
--   data/checkout_order_items.csv  -> checkout_order_items
-- This script validates data quality, experiment integrity and the session-level analysis view.
-- Objective: Validate synthetic data, check experiment integrity, prepare the session-level view,
-- and produce checks to support a defensible analysis and recommendation.
-- Tools: PostgreSQL → Python → Power BI → GitHub

-- ============================================================
-- STAGE 1 — CONFIRM MY DATABASE IS READY
-- ============================================================

-- TASK 1: INSPECT MY TABLES
-- I need to confirm that all four tables exist in my PostgreSQL database and understand their structure.
SELECT *
FROM checkout_order_items
LIMIT 5;

SELECT *
FROM checkout_orders
LIMIT 5;

SELECT *
FROM session_outcomes
LIMIT 5;

SELECT *
FROM checkout_exposures
LIMIT 5;



-- ============================================================
-- STAGE 2 — VALIDATE MY IMPORTED DATA
-- ============================================================

-- CHECK ROW COUNTS

SELECT 'checkout_exposures' AS table_name, COUNT(*) AS row_count
FROM checkout_exposures

UNION ALL

SELECT 'session_outcomes', COUNT(*)
FROM session_outcomes

UNION ALL

SELECT 'checkout_orders', COUNT(*)
FROM checkout_orders

UNION ALL

SELECT 'checkout_order_items', COUNT(*)
FROM checkout_order_items;

-- "checkout_exposures"	12000
-- "session_outcomes"	12000
-- "checkout_orders"	1274
--"checkout_order_items"	2527


-- CHECK FOR DUPLICATE RECORDS

SELECT
    session_id,
    COUNT(*) AS number_of_records
FROM checkout_exposures
GROUP BY session_id
HAVING COUNT(*) > 1;

SELECT
    session_id,
    COUNT(*) AS number_of_records
FROM session_outcomes
GROUP BY session_id
HAVING COUNT(*) > 1;

SELECT
   synthetic_order_id,
    COUNT(*) AS number_of_records
FROM checkout_orders
GROUP BY synthetic_order_id
HAVING COUNT(*) > 1;

SELECT
    synthetic_order_item_id,
    COUNT(*) AS number_of_records
FROM checkout_order_items
GROUP BY synthetic_order_item_id
HAVING COUNT(*) > 1;

-- Multiple item rows per order are expected and are not duplicate-item errors.
-- This query identifies orders with more than one line item.
SELECT
    synthetic_order_id,
    COUNT(*) AS item_line_count
FROM checkout_order_items
GROUP BY synthetic_order_id
HAVING COUNT(*) > 1
ORDER BY item_line_count DESC, synthetic_order_id;


-- CHECK MISSING AND INVALID VALUES
-- =====================================================
-- DATA QUALITY CHECKS — ALL TABLES
-- =====================================================

SELECT
    'checkout_exposures' AS table_name,
    'Missing session IDs' AS check_name,
    COUNT(*) AS issue_count
FROM checkout_exposures
WHERE session_id IS NULL

UNION ALL

SELECT
    'checkout_exposures',
    'Missing variant labels',
    COUNT(*)
FROM checkout_exposures
WHERE variant IS NULL OR TRIM(variant) = ''

UNION ALL

SELECT
    'checkout_exposures',
    'Invalid eligibility values',
    COUNT(*)
FROM checkout_exposures
WHERE eligible IS NULL OR eligible NOT IN (0, 1)

UNION ALL

SELECT
    'checkout_exposures',
    'Invalid exposure values',
    COUNT(*)
FROM checkout_exposures
WHERE exposed IS NULL OR exposed NOT IN (0, 1)

UNION ALL

SELECT
    'checkout_exposures',
    'Missing assignment timestamps',
    COUNT(*)
FROM checkout_exposures
WHERE assigned_at IS NULL

UNION ALL

SELECT
    'session_outcomes',
    'Missing session IDs',
    COUNT(*)
FROM session_outcomes
WHERE session_id IS NULL

UNION ALL

SELECT
    'session_outcomes',
    'Invalid conversion indicators',
    COUNT(*)
FROM session_outcomes
WHERE converted IS NULL OR converted NOT IN (0, 1)

UNION ALL

SELECT
    'session_outcomes',
    'Missing conversion timestamps for conversions',
    COUNT(*)
FROM session_outcomes
WHERE converted = 1 AND conversion_timestamp IS NULL

UNION ALL

SELECT
    'session_outcomes',
    'Missing order IDs for conversions',
    COUNT(*)
FROM session_outcomes
WHERE converted = 1 AND synthetic_order_id IS NULL

UNION ALL

SELECT
    'checkout_orders',
    'Missing order IDs',
    COUNT(*)
FROM checkout_orders
WHERE synthetic_order_id IS NULL

UNION ALL

SELECT
    'checkout_orders',
    'Missing session IDs',
    COUNT(*)
FROM checkout_orders
WHERE session_id IS NULL

UNION ALL

SELECT
    'checkout_orders',
    'Missing order timestamps',
    COUNT(*)
FROM checkout_orders
WHERE order_timestamp IS NULL

UNION ALL

SELECT
    'checkout_orders',
    'Missing order values',
    COUNT(*)
FROM checkout_orders
WHERE order_value_gbp IS NULL

UNION ALL

SELECT
    'checkout_orders',
    'Non-positive order values',
    COUNT(*)
FROM checkout_orders
WHERE order_value_gbp <= 0

UNION ALL

SELECT
    'checkout_orders',
    'Missing currency',
    COUNT(*)
FROM checkout_orders
WHERE currency IS NULL OR TRIM(currency) = ''

UNION ALL

SELECT
    'checkout_order_items',
    'Missing order-item IDs',
    COUNT(*)
FROM checkout_order_items
WHERE synthetic_order_item_id IS NULL

UNION ALL

SELECT
    'checkout_order_items',
    'Missing order IDs',
    COUNT(*)
FROM checkout_order_items
WHERE synthetic_order_id IS NULL

UNION ALL

SELECT
    'checkout_order_items',
    'Missing session IDs',
    COUNT(*)
FROM checkout_order_items
WHERE session_id IS NULL

UNION ALL

SELECT
    'checkout_order_items',
    'Missing line values',
    COUNT(*)
FROM checkout_order_items
WHERE line_value_gbp IS NULL

UNION ALL

SELECT
    'checkout_order_items',
    'Non-positive line values',
    COUNT(*)
FROM checkout_order_items
WHERE line_value_gbp <= 0

UNION ALL

SELECT
    'checkout_order_items',
    'Missing line numbers',
    COUNT(*)
FROM checkout_order_items
WHERE line_number IS NULL

ORDER BY table_name, check_name;



-- ============================================================
-- STAGE 3 — VALIDATE THE EXPERIMENT DESIGN
-- ============================================================

-- INSPECT THE EXPERIMENTAL GROUPS
SELECT *
FROM checkout_exposures
LIMIT 5;
-- 1. Identify variant labels
SELECT
    '01 - Variant labels' AS check_name,
    COALESCE(variant, 'NULL') AS result,
    COUNT(*) AS record_count
FROM checkout_exposures
GROUP BY variant

UNION ALL

-- 2. Count sessions assigned to each variant
SELECT
    '02 - Sessions by variant',
    COALESCE(variant, 'NULL'),
    COUNT(*)
FROM checkout_exposures
GROUP BY variant

UNION ALL

-- 3. Check eligibility and exposure combinations
SELECT
    '03 - Eligibility/exposure combinations',
    CONCAT(
        'variant=', COALESCE(variant, 'NULL'),
        ', eligible=', COALESCE(eligible::TEXT, 'NULL'),
        ', exposed=', COALESCE(exposed::TEXT, 'NULL')
    ),
    COUNT(*)
FROM checkout_exposures
GROUP BY variant, eligible, exposed

UNION ALL

-- 4. Find invalid eligibility indicators
SELECT
    '04 - Invalid eligibility values',
    COALESCE(eligible::TEXT, 'NULL'),
    COUNT(*)
FROM checkout_exposures
WHERE eligible IS NULL OR eligible NOT IN (0, 1)
GROUP BY eligible

UNION ALL

-- 5. Find invalid exposure indicators
SELECT
    '05 - Invalid exposure values',
    COALESCE(exposed::TEXT, 'NULL'),
    COUNT(*)
FROM checkout_exposures
WHERE exposed IS NULL OR exposed NOT IN (0, 1)
GROUP BY exposed

UNION ALL

-- 6. Count assigned sessions that were not exposed
SELECT
    '06 - Assigned but not exposed',
    COALESCE(variant, 'NULL'),
    COUNT(*)
FROM checkout_exposures
WHERE exposed = 0
GROUP BY variant

UNION ALL

-- 7. Find exposed sessions marked ineligible
SELECT
    '07 - Exposed but ineligible',
    COALESCE(variant, 'NULL'),
    COUNT(*)
FROM checkout_exposures
WHERE eligible = 0 AND exposed = 1
GROUP BY variant

ORDER BY check_name, result;


-- EXPERIMENT INTEGRITY AUDIT
-- Purpose: Check that exposure, outcome and order records connect correctly.

-- 1. Exposure records without a matching outcome
SELECT
    '01 - Exposure without outcome' AS check_name,
    e.session_id AS session_id,
    e.variant AS variant,
    'No matching session_outcomes record' AS issue
FROM checkout_exposures AS e
LEFT JOIN session_outcomes AS s
    ON e.session_id = s.session_id
WHERE s.session_id IS NULL

UNION ALL

-- 2. Outcome records without a matching exposure
SELECT
    '02 - Outcome without exposure',
    s.session_id,
    NULL::TEXT AS variant,
    'No matching checkout_exposures record'
FROM session_outcomes AS s
LEFT JOIN checkout_exposures AS e
    ON s.session_id = e.session_id
WHERE e.session_id IS NULL

UNION ALL

-- 3. Missing or invalid conversion indicators
SELECT
    '03 - Invalid conversion indicator',
    s.session_id,
    e.variant,
    CONCAT(
        'converted=',
        COALESCE(s.converted::TEXT, 'NULL')
    )
FROM session_outcomes AS s
LEFT JOIN checkout_exposures AS e
    ON s.session_id = e.session_id
WHERE s.converted IS NULL
   OR s.converted NOT IN (0, 1)

UNION ALL

-- 4. Converted sessions missing a conversion timestamp
SELECT
    '04 - Conversion missing timestamp',
    s.session_id,
    e.variant,
    'Converted but conversion_timestamp is missing'
FROM session_outcomes AS s
LEFT JOIN checkout_exposures AS e
    ON s.session_id = e.session_id
WHERE s.converted = 1
  AND s.conversion_timestamp IS NULL

UNION ALL

-- 5. Converted sessions missing a synthetic order ID
SELECT
    '05 - Conversion missing order ID',
    s.session_id,
    e.variant,
    'Converted but synthetic_order_id is missing'
FROM session_outcomes AS s
LEFT JOIN checkout_exposures AS e
    ON s.session_id = e.session_id
WHERE s.converted = 1
  AND s.synthetic_order_id IS NULL

UNION ALL

-- 6. Converted sessions whose order ID does not exist
SELECT
    '06 - Conversion order not found',
    s.session_id,
    e.variant,
    CONCAT(
        'Order ID: ',
        s.synthetic_order_id
    )
FROM session_outcomes AS s
LEFT JOIN checkout_exposures AS e
    ON s.session_id = e.session_id
LEFT JOIN checkout_orders AS o
    ON s.synthetic_order_id = o.synthetic_order_id
WHERE s.converted = 1
  AND s.synthetic_order_id IS NOT NULL
  AND o.synthetic_order_id IS NULL

UNION ALL

-- 7. Orders without a matching conversion outcome
SELECT
    '07 - Order without matching conversion',
    o.session_id,
    e.variant,
    CONCAT(
        'Order ID: ',
        o.synthetic_order_id
    )
FROM checkout_orders AS o
LEFT JOIN checkout_exposures AS e
    ON o.session_id = e.session_id
LEFT JOIN session_outcomes AS s
    ON o.session_id = s.session_id
WHERE s.session_id IS NULL
   OR s.converted IS DISTINCT FROM 1

UNION ALL

-- 8. Check that a conversion's order belongs to the same session.
SELECT
    '08 - Order/session mismatch',
    s.session_id,
    e.variant,
    CONCAT(
        'Order ID ', o.synthetic_order_id,
        ' belongs to session ', o.session_id
    )
FROM session_outcomes AS s
JOIN checkout_orders AS o
    ON s.synthetic_order_id = o.synthetic_order_id
LEFT JOIN checkout_exposures AS e
    ON s.session_id = e.session_id
WHERE s.converted = 1
  AND o.session_id IS DISTINCT FROM s.session_id

ORDER BY check_name, session_id;

-- INTERPRETATION NOTE:
-- The integrity-audit query returns records that fail the listed checks.
-- Verify the actual query result before reporting that the audit passed.
-- A zero-row result only supports the specific relationships tested; it does not prove
-- that the data are completely error-free or representative of real-world behaviour.

-- ============================================================
-- STAGE 4 — BUILD MY ANALYSIS DATASET
-- ============================================================

-- TASK 7: DECIDE THE UNIT OF ANALYSIS
-- BUILD MY SESSION-LEVEL ANALYSIS DATASET

-- 1. Combine experiment assignments with conversion outcomes

CREATE OR REPLACE VIEW checkout_session_analysis AS
SELECT
    e.session_id,
    e.variant,
    e.eligible,
    e.exposed,
    s.converted,
    s.conversion_timestamp,
    s.synthetic_order_id
FROM checkout_exposures AS e
LEFT JOIN session_outcomes AS s
    ON e.session_id = s.session_id;


-- 2. Check the number of sessions in the analysis dataset
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT session_id) AS unique_sessions
FROM checkout_session_analysis;


-- 3. Check for duplicated session IDs
SELECT
    session_id,
    COUNT(*) AS number_of_records
FROM checkout_session_analysis
GROUP BY session_id
HAVING COUNT(*) > 1;


-- 4. Check for sessions without a matching outcome
SELECT *
FROM checkout_session_analysis
WHERE converted IS NULL;


-- 5. Summarise the dataset by variant
SELECT
    variant,
    COUNT(*) AS total_sessions,
    COUNT(*) FILTER (WHERE eligible = 1) AS eligible_sessions,
    COUNT(*) FILTER (WHERE exposed = 1) AS exposed_sessions,
    COUNT(*) FILTER (WHERE converted = 1) AS converted_sessions
FROM checkout_session_analysis
GROUP BY variant
ORDER BY variant;

SELECT *
FROM checkout_session_analysis;


-- TASK 8: VALIDATE THE FINAL ANALYSIS DATASET

-- 1. Compare total rows against unique sessions
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT session_id) AS unique_sessions,
    COUNT(*) - COUNT(DISTINCT session_id) AS extra_rows
FROM checkout_session_analysis;


-- 2. Check for duplicate session IDs
SELECT
    session_id,
    COUNT(*) AS number_of_records
FROM checkout_session_analysis
GROUP BY session_id
HAVING COUNT(*) > 1;


-- 3. Check for missing values in essential fields
SELECT
    COUNT(*) FILTER (WHERE session_id IS NULL) AS missing_session_ids,
    COUNT(*) FILTER (WHERE variant IS NULL) AS missing_variants,
    COUNT(*) FILTER (WHERE converted IS NULL) AS missing_conversion_outcomes,
    COUNT(*) FILTER (WHERE eligible IS NULL) AS missing_eligibility_values,
    COUNT(*) FILTER (WHERE exposed IS NULL) AS missing_exposure_values
FROM checkout_session_analysis;


-- 4. Check for invalid variant labels
SELECT
    variant,
    COUNT(*) AS session_count
FROM checkout_session_analysis
WHERE variant IS NULL
   OR variant NOT IN ('control', 'treatment')
GROUP BY variant;


-- 5. Check for invalid conversion, eligibility or exposure values
SELECT *
FROM checkout_session_analysis
WHERE converted IS NULL OR converted NOT IN (0, 1)
   OR eligible IS NULL OR eligible NOT IN (0, 1)
   OR exposed IS NULL OR exposed NOT IN (0, 1);


-- 6. Check whether the analysis view retains every exposure record
SELECT
    (SELECT COUNT(*) FROM checkout_exposures) AS original_exposure_rows,
    (SELECT COUNT(*) FROM checkout_session_analysis) AS analysis_rows;


-- 7. Check whether any sessions are missing their outcomes
SELECT
    session_id,
    variant
FROM checkout_session_analysis
WHERE converted IS NULL;


-- 8. Review the final dataset
SELECT *
FROM checkout_session_analysis
ORDER BY session_id;

SELECT
    table_schema,
    table_name
FROM information_schema.views
WHERE table_name = 'checkout_session_analysis';

SELECT *
FROM checkout_session_analysis;
