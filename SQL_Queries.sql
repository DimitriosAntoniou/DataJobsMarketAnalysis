-- ============================================================
--  DATA JOBS MARKET ANALYSIS — SQL Queries
--  Author  : Dimitrios Antoniou
--  Dataset : Data Science Salaries 2020–2024 (600 records)
--  Tool    : SQLite / SQL Server compatible
-- ============================================================


-- ============================================================
-- 0. CREATE TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS ds_salaries (
    id INTEGER PRIMARY KEY,
    work_year INTEGER,
    experience_level TEXT,   -- EN / MI / SE / EX
    experience_label TEXT,   -- Entry-level / Mid-level / Senior / Executive
    employment_type  TEXT,   -- FT / PT / CT
    employment_label TEXT,   -- Full-Time / Part-Time / Contract
    job_title TEXT,
    salary_usd INTEGER,
    employee_residence TEXT,   -- ISO country code (US, GB, DE ...)
    country_name TEXT,
    remote_ratio INTEGER, -- 0=On-site | 50=Hybrid | 100=Remote
    remote_label TEXT,
    company_size TEXT,   -- S / M / L
    company_size_label TEXT
);


-- ============================================================
-- Q1. AVERAGE SALARY BY JOB TITLE
--     Which roles pay the most in the market?
-- ============================================================
SELECT
    job_title,
    COUNT(*) AS total_jobs,
    ROUND(AVG(salary_usd), 0) AS avg_salary_usd,
    ROUND(MIN(salary_usd), 0) AS min_salary_usd,
    ROUND(MAX(salary_usd), 0) AS max_salary_usd
FROM ds_salaries
GROUP BY job_title
ORDER BY avg_salary_usd DESC;


-- ============================================================
-- Q2. AVERAGE SALARY BY COUNTRY
--     Which countries pay the best?
-- ============================================================
SELECT
    country_name,
    employee_residence AS country_code,
    COUNT(*) AS total_jobs,
    ROUND(AVG(salary_usd), 0) AS avg_salary_usd
FROM ds_salaries
GROUP BY country_name
ORDER BY avg_salary_usd DESC;


-- ============================================================
-- Q3. SALARY BY EXPERIENCE LEVEL
--     How much does salary grow with experience?
-- ============================================================
SELECT
    experience_label,
    COUNT(*) AS total_employees,
    ROUND(AVG(salary_usd), 0) AS avg_salary_usd,
    ROUND(MIN(salary_usd), 0) AS min_salary_usd,
    ROUND(MAX(salary_usd), 0) AS max_salary_usd
FROM ds_salaries
GROUP BY experience_label
ORDER BY avg_salary_usd DESC;


-- ============================================================
-- Q4. REMOTE VS HYBRID VS ON-SITE
--     Does remote work affect salary?
-- ============================================================
SELECT
    remote_label,
    COUNT(*) AS total_jobs,
    ROUND(AVG(salary_usd), 0) AS avg_salary_usd,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM ds_salaries), 1) AS percentage
FROM ds_salaries
GROUP BY remote_label
ORDER BY total_jobs DESC;


-- ============================================================
-- Q5. MARKET TRENDS BY YEAR (2020–2024)
--     How has the job market evolved?
-- ============================================================
SELECT
    work_year,
    COUNT(*) AS total_jobs,
    ROUND(AVG(salary_usd), 0) AS avg_salary_usd
FROM ds_salaries
GROUP BY work_year
ORDER BY work_year ASC;


-- ============================================================
-- Q6. TOP 10 HIGHEST PAID POSITIONS
-- ============================================================
SELECT
    job_title,
    experience_label,
    country_name,
    remote_label,
    salary_usd
FROM ds_salaries
ORDER BY salary_usd DESC
LIMIT 10;


-- ============================================================
-- Q7. FOCUS: DATA ANALYST — Detailed View
--     (Directly relevant to the role we are applying for!)
-- ============================================================
SELECT
    experience_label,
    country_name,
    remote_label,
    ROUND(AVG(salary_usd), 0) AS avg_salary_usd,
    COUNT(*) AS count
FROM ds_salaries
WHERE job_title IN ('Data Analyst', 'Senior Data Analyst')
GROUP BY experience_label, country_name, remote_label
ORDER BY avg_salary_usd DESC
LIMIT 20;


-- ============================================================
-- Q8. BONUS — SALARY BY COMPANY SIZE
--     Large vs Small company — which is better?
-- ============================================================
SELECT
    company_size_label,
    COUNT(*) AS total_jobs,
    ROUND(AVG(salary_usd), 0) AS avg_salary_usd,
    ROUND(MIN(salary_usd), 0) AS min_salary_usd,
    ROUND(MAX(salary_usd), 0) AS max_salary_usd
FROM ds_salaries
GROUP BY company_size_label
ORDER BY avg_salary_usd DESC;


-- ============================================================
-- Q9. WINDOW FUNCTION — Salary Ranking per Job Title
--     Ranking each employee's salary within their job category
-- ============================================================
SELECT
    job_title,
    country_name,
    experience_label,
    salary_usd,
    RANK() OVER (PARTITION BY job_title ORDER BY salary_usd DESC) AS salary_rank,
    ROUND(AVG(salary_usd) OVER (PARTITION BY job_title), 0) AS avg_salary_in_role
FROM ds_salaries
ORDER BY job_title, salary_rank;


-- ============================================================
-- Q10. WINDOW FUNCTION — Year-over-Year Salary Growth
--      How much did average salaries grow each year?
-- ============================================================
SELECT
    work_year,
    ROUND(AVG(salary_usd), 0)    AS avg_salary_usd,
    ROUND(AVG(salary_usd) - LAG(ROUND(AVG(salary_usd), 0))
        OVER (ORDER BY work_year), 0) AS yoy_change_usd,
    ROUND((AVG(salary_usd) - LAG(AVG(salary_usd))
        OVER (ORDER BY work_year)) /
        LAG(AVG(salary_usd)) OVER (ORDER BY work_year) * 100, 1) AS yoy_growth_pct
FROM ds_salaries
GROUP BY work_year
ORDER BY work_year;


-- ============================================================
-- Q11. CTE — Above Average Salary Analysis
--      Which roles consistently pay above the market average?
-- ============================================================
WITH market_avg AS (
    SELECT ROUND(AVG(salary_usd), 0) AS overall_avg
    FROM ds_salaries
),
role_avg AS (
    SELECT
        job_title,
        COUNT(*) AS total_jobs,
        ROUND(AVG(salary_usd), 0) AS avg_salary
    FROM ds_salaries
    GROUP BY job_title
)
SELECT
    r.job_title,
    r.total_jobs,
    r.avg_salary,
    m.overall_avg,
    ROUND(r.avg_salary - m.overall_avg, 0) AS diff_from_market,
    ROUND((r.avg_salary - m.overall_avg) * 100.0
        / m.overall_avg, 1) AS pct_above_market
FROM role_avg r
CROSS JOIN market_avg m
WHERE r.avg_salary > m.overall_avg
ORDER BY pct_above_market DESC;


-- ============================================================
-- Q12. CASE WHEN — Salary Tier Classification
--      Categorizing all positions into salary bands
-- ============================================================
SELECT
    job_title,
    experience_label,
    country_name,
    salary_usd,
    CASE
        WHEN salary_usd < 40000  THEN 'Entry Band'
        WHEN salary_usd < 80000  THEN 'Mid Band'
        WHEN salary_usd < 130000 THEN 'Senior Band'
        WHEN salary_usd < 200000 THEN 'Lead Band'
        ELSE                          'Executive Band'
    END AS salary_tier
FROM ds_salaries
ORDER BY salary_usd DESC;


-- ============================================================
-- Q13. CTE + CASE WHEN — Salary Tier Distribution
--      What percentage of jobs fall in each salary band?
-- ============================================================
WITH tiered AS (
    SELECT
        CASE
            WHEN salary_usd < 40000  THEN 'Entry Band'
            WHEN salary_usd < 80000  THEN 'Mid Band'
            WHEN salary_usd < 130000 THEN 'Senior Band'
            WHEN salary_usd < 200000 THEN 'Lead Band'
            ELSE                          'Executive Band'
        END AS salary_tier
    FROM ds_salaries
)
SELECT
    salary_tier,
    COUNT(*) AS total_jobs,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM ds_salaries), 1) AS percentage
FROM tiered
GROUP BY salary_tier
ORDER BY total_jobs DESC;


-- ============================================================
-- END OF SCRIPT
-- ============================================================
