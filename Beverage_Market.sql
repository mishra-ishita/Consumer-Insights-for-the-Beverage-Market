CREATE DATABASE food_beverage;
USE food_beverage;
SELECT * FROM dim_cities;
SELECT * FROM dim_respondents;
SELECT * FROM fact_survey_responses;

-- 1. Demographic Profile (Age & Gender by City Tier)
SELECT 
    c.Tier AS City_Tier,
    r.Age_Group AS Age_Category,
    r.Gender AS Gender,
    COUNT(*) AS Respondent_Count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY c.Tier),
        2
    ) AS Percent_of_Tier
FROM dim_respondents r
JOIN dim_cities c 
    ON r.City_ID = c.City_ID
GROUP BY c.Tier, r.Age_Group, r.Gender
ORDER BY c.Tier, r.Age_Group, r.Gender;

-- 2. Consumption Frequency Trends
SELECT 
    f.Consume_frequency,
    COUNT(*) AS Respondent_Count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS Percent_of_Total
FROM fact_survey_responses f
GROUP BY f.Consume_frequency
ORDER BY FIELD(f.Consume_frequency, 'Daily','2-3 times a week','Once a week','2-3 times a month','Rarely');

-- 3. Peak Consumption Times by Age Group
SELECT 
    r.Age_Group,
    f.Consume_time,
    COUNT(*) AS Respondent_Count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY r.Age_Group), 2) AS Percent_by_Age
FROM fact_survey_responses f
JOIN dim_respondents r ON f.Respondent_ID = r.Respondent_ID
GROUP BY r.Age_Group, f.Consume_time
ORDER BY r.Age_Group, Percent_by_Age DESC;

-- 4️. Top Reasons for Consumption by Gender
SELECT 
    r.Gender,
    f.Consume_reason,
    COUNT(*) AS Respondent_Count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY r.Gender),2) AS Percent_by_Gender
FROM fact_survey_responses f
JOIN dim_respondents r ON f.Respondent_ID = r.Respondent_ID
GROUP BY r.Gender, f.Consume_reason
ORDER BY r.Gender, Percent_by_Gender DESC;

-- 5. Brand Awareness by City Tier
SELECT 
    c.Tier,
    SUM(CASE WHEN f.Heard_before='Yes' THEN 1 ELSE 0 END) AS Heard_Count,
    COUNT(*) AS Total_Respondents,
    ROUND(SUM(CASE WHEN f.Heard_before='Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),2) AS Heard_Percent
FROM fact_survey_responses f
JOIN dim_respondents r ON f.Respondent_ID = r.Respondent_ID
JOIN dim_cities c ON r.City_ID = c.City_ID
GROUP BY c.Tier
ORDER BY Heard_Percent DESC;

-- 6. Brand Perception by Age Group
SELECT 
    r.Age_Group,
    f.Brand_perception,
    COUNT(*) AS Respondent_Count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY r.Age_Group),2) AS Percent_by_Age
FROM fact_survey_responses f
JOIN dim_respondents r ON f.Respondent_ID = r.Respondent_ID
GROUP BY r.Age_Group, f.Brand_perception
ORDER BY r.Age_Group, FIELD(f.Brand_perception,'Positive','Neutral','Negative');

-- 7. General Perception of Energy Drinks
SELECT 
    f.General_perception,
    COUNT(*) AS Respondent_Count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(),2) AS Percent_of_Total
FROM fact_survey_responses f
GROUP BY f.General_perception
ORDER BY FIELD(f.General_perception,'Healthy','Effective','Dangerous','Not sure');

-- 8. Trial Conversion Funnel
WITH Awareness AS (
    SELECT COUNT(*) AS Heard_Count
    FROM fact_survey_responses
    WHERE Heard_before='Yes'
),
Tried AS (
    SELECT COUNT(*) AS Tried_Count
    FROM fact_survey_responses
    WHERE Tried_before='Yes'
)
SELECT 
    a.Heard_Count,
    t.Tried_Count,
    ROUND(t.Tried_Count*100.0/a.Heard_Count,2) AS Trial_Rate_Percent
FROM Awareness a, Tried t;

-- 9.Taste Experience Ratings by City Tier
SELECT 
    c.Tier,
    AVG(f.Taste_experience) AS Avg_Taste_Rating,
    COUNT(f.Taste_experience) AS Respondent_Count
FROM fact_survey_responses f
JOIN dim_respondents r ON f.Respondent_ID = r.Respondent_ID
JOIN dim_cities c ON r.City_ID = c.City_ID
WHERE f.Taste_experience IS NOT NULL
GROUP BY c.Tier
ORDER BY Avg_Taste_Rating DESC;

-- 10.Barriers to Trying (Conditional Aggregation)
SELECT 
    f.Reasons_preventing_trying,
    COUNT(*) AS Respondent_Count,
    ROUND(COUNT(*)*100.0/SUM(COUNT(*)) OVER(),2) AS Percent_of_Total
FROM fact_survey_responses f
WHERE f.Tried_before='No'
GROUP BY f.Reasons_preventing_trying
ORDER BY Percent_of_Total DESC;

-- 11.Top Current Brands by City
WITH Ranked_Brands AS (
    SELECT 
        c.City AS City_Name,
        f.Current_brands AS Brand,
        COUNT(*) AS Respondent_Count,
        ROW_NUMBER() OVER(
            PARTITION BY c.City 
            ORDER BY COUNT(*) DESC
        ) AS Rank_in_City
    FROM fact_survey_responses f
    JOIN dim_respondents r 
        ON f.Respondent_ID = r.Respondent_ID
    JOIN dim_cities c 
        ON r.City_ID = c.City_ID
    GROUP BY c.City, f.Current_brands
)
SELECT City_Name, Brand, Respondent_Count
FROM Ranked_Brands
WHERE Rank_in_City = 1
ORDER BY City_Name;

-- 12. Consumption Frequency vs. Brand Awareness
SELECT 
    f.Consume_frequency,
    SUM(CASE WHEN f.Heard_before='Yes' THEN 1 ELSE 0 END) AS Heard_Count,
    COUNT(*) AS Total_Respondents,
    ROUND(SUM(CASE WHEN f.Heard_before='Yes' THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS Heard_Percent
FROM fact_survey_responses f
GROUP BY f.Consume_frequency
ORDER BY FIELD(f.Consume_frequency,'Daily','2-3 times a week','Once a week','2-3 times a month','Rarely');

-- 13. Perception vs. Trial Rates
SELECT 
    f.Brand_perception,
    SUM(CASE WHEN f.Tried_before='Yes' THEN 1 ELSE 0 END) AS Tried_Count,
    COUNT(*) AS Total_Respondents,
    ROUND(SUM(CASE WHEN f.Tried_before='Yes' THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS Trial_Percent
FROM fact_survey_responses f
GROUP BY f.Brand_perception
ORDER BY FIELD(f.Brand_perception,'Positive','Neutral','Negative');

-- 14. Age Group vs. Preferred Brand
SELECT 
    r.Age_Group,
    f.Current_brands,
    COUNT(*) AS Respondent_Count,
    ROW_NUMBER() OVER(PARTITION BY r.Age_Group ORDER BY COUNT(*) DESC) AS Rank_in_Age
FROM fact_survey_responses f
JOIN dim_respondents r ON f.Respondent_ID = r.Respondent_ID
GROUP BY r.Age_Group, f.Current_brands
ORDER BY r.Age_Group, Rank_in_Age;


