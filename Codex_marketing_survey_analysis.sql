
-- Data cleaning
UPDATE fact_survey_responses
SET Tried_before = 'No'
WHERE Heard_before = 'No';
--

ALTER TABLE fact_survey_responses
MODIFY COLUMN Taste_experience VARCHAR(50);

UPDATE fact_survey_responses
SET Taste_experience  = 'null'
WHERE Tried_before = 'No';
--
-- 1. Demographic Insights (examples)
-- a. Who prefers energy drink more? (male/female/non-binary?)
SELECT Gender, 
       count(*) as Gender_drink_count ,
       ROUND(100.0 * count(*) / (select count(*) from dim_repondents),2) as Gender_drink_pct
FROM dim_repondents 
GROUP BY gender 
ORDER BY Gender_drink_pct DESC;

-- b. Which age group prefers energy drinks more?
SELECT Age, 
       count(*) as Age_group_count,
       ROUND( 100.0 * count(*) / (select count(*) from dim_repondents ), 2) AS Age_GroupShare_Pct
FROM dim_repondents 
GROUP BY age 
ORDER BY Age_GroupShare_Pct DESC ;

-- c. Which type of marketing reaches the most Youth (15-30)?
SELECT  marketing_channels,
        count(*) as reach_count, 
        Round(100.0 * COUNT(*) / (SELECT COUNT(marketing_channels) FROM fact_survey_responses),2) 
                         as marketing_reach_pct
FROM Fact_survey_responses AS S 
JOIN dim_repondents AS R
ON S.Respondent_ID= R.Respondent_ID
WHERE Age IN ('15-18', '19-30')
GROUP BY Marketing_channels
ORDER BY marketing_reach_pct DESC;

-- 2. Consumer Preferences:
-- a. What are the preferred ingredients of energy drinks among respondents?
SELECT Ingredients_expected, 
        COUNT(*) AS preferred_ing_count,
        ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM fact_survey_responses),2) as Preferred_ingredient_pct
FROM fact_survey_responses
GROUP BY Ingredients_expected
ORDER BY preferred_ing_count DESC;


-- b. What packaging preferences do respondents have for energy drinks?

SELECT Packaging_preference, 
       count(*) as pack_pref_count,
       ROUND( 100.0 * COUNT(*) / (SELECT COUNT(*) FROM fact_survey_responses ),2) as Packaging_pref_pct
FROM fact_survey_responses
GROUP BY Packaging_preference
ORDER BY pack_pref_count DESC;


-- 3. Competition Analysis:
-- a. Who are the current market leaders?

SELECT Current_brands , 
      count(*) as pref_brand_count,
      ROUND( 100.0 * COUNT(*) / ( SELECT COUNT(*) FROM fact_survey_responses ),2) as Market_share
FROM fact_survey_responses
GROUP BY Current_brands 
ORDER BY pref_brand_count DESC;

-- b. What are the primary reasons consumers prefer those brands over ours?
SELECT Reasons_preventing_trying, 
       COUNT(*) AS deterring_count,
       ROUND( 100.0 * COUNT(*) / ( SELECT COUNT(*) FROM fact_survey_responses ), 2) AS deterring_count_pct
FROM fact_survey_responses
GROUP BY Reasons_preventing_trying 
ORDER BY deterring_count DESC ;

-- 4. Marketing Channels and Brand Awareness:
-- a. Which marketing channel can be used to reach more customers?

SELECT Marketing_channels, 
       COUNT(*) marketing_reach_count,
       ROUND(100.0 * COUNT(*) / ( SELECT COUNT(*) FROM fact_survey_responses ),2) AS Marketing_channel_share
FROM fact_survey_responses
GROUP BY Marketing_channels 
ORDER BY marketing_reach_count DESC;

-- b. How effective are different marketing strategies and channels in reaching our customers?
-- 1. marketing channels and packaging preference
WITH CTE AS (
SELECT Marketing_channels,
       Packaging_preference, 
       COUNT(*) AS effectiveness_count,
       row_number() over( partition by Marketing_channels order by count(*) desc ) rn
FROM fact_survey_responses
GROUP BY Marketing_channels, Packaging_preference
ORDER BY Marketing_channels , effectiveness_count DESC)

SELECT * FROM CTE WHERE rn <=3;

-- 2. marketing channels and brand perception
WITH CTE AS (
SELECT Marketing_channels,
       Brand_perception, 
       count(*) effectiveness_count,
       row_number() over( partition by Marketing_channels order by count(*) desc ) rn
FROM fact_survey_responses
GROUP BY Marketing_channels,Brand_perception
ORDER BY Marketing_channels ,effectiveness_count DESC)

SELECT * FROM CTE WHERE rn <= 3

-- 3. Marketing_channels and Purchase_location
SELECT Marketing_channels,
       Purchase_location, 
       count(*) effectiveness_count
FROM fact_survey_responses
GROUP BY Marketing_channels, Purchase_location
ORDER BY Marketing_channels ,effectiveness_count DESC;

-- 5. Brand Penetration:
-- a. What do people think about our brand? (overall rating)

SELECT Tried_before, 
       avg(Taste_experience) as avg_rating
FROM fact_survey_responses
WHERE Tried_before = 'Yes'
group by Tried_before ;

-- b. Which cities do we need to focus more on?
-- Marketing issues
WITH cte1 AS ( 
SELECT  
        City, 
        COUNT(*) AS NotHeard_count
FROM dim_cities AS c
JOIN dim_repondents AS r
ON c.City_ID = r.City_ID
join fact_survey_responses as s
on r.Respondent_ID = s.Respondent_ID
where Heard_before = 'No'
GROUP BY City
ORDER BY NotHeard_count DESC),

cte2 AS ( 
SELECT  
        City, 
        COUNT(*) AS city_count
FROM dim_cities AS c
JOIN dim_repondents AS r
ON c.City_ID = r.City_ID
join fact_survey_responses as s
on r.Respondent_ID = s.Respondent_ID
GROUP BY City
ORDER BY city_count DESC)

SELECT cte1.City, Round( 100.0 * NotHeard_count  / city_count ,2 ) AS not_heard_pct
from cte1 JOIN cte2 ON cte1.City = cte2.City
ORDER BY not_heard_pct DESC ;


-- Supply chain issue
WITH cte1 AS (
    SELECT  
        City, 
        COUNT(*) AS counter
   FROM dim_cities AS c
   JOIN dim_repondents AS r
   ON c.City_ID = r.City_ID
   join fact_survey_responses as s
   on r.Respondent_ID = s.Respondent_ID
   where Heard_before = 'Yes' and Reasons_preventing_trying = 'Not available locally'
   GROUP BY City
   ORDER BY counter DESC),

cte2 as ( 
    SELECT  
        City, 
        COUNT(*) AS group_total
   FROM dim_cities AS c
   JOIN dim_repondents AS r
   ON c.City_ID = r.City_ID
   join fact_survey_responses as s
   on r.Respondent_ID = s.Respondent_ID
   GROUP BY C.City)

SELECT cte1.City, Round( 100.0 * counter / group_total,2 ) AS not_availability_pct
from cte1 JOIN cte2 ON cte1.City = cte2.City
ORDER BY not_availability_pct DESC ;


-- Purchase Behavior:
-- a. Where do respondents prefer to purchase energy drinks?

SELECT Purchase_location, 
      count(*) AS purchase_count,
      ROUND( 100.0 * COUNT(*) / (SELECT COUNT(*) FROM fact_survey_responses),2) AS Purchase_location_pct
FROM fact_survey_responses 
GROUP BY Purchase_location;

-- b. What are the typical consumption situations for energy drinks among respondents?
SELECT Typical_consumption_situations, 
      COUNT(*) as consumption_situation_count ,
      ROUND( 100.0 * COUNT(*) / (SELECT COUNT(*) FROM fact_survey_responses),2) AS consumption_situation_share_pct
FROM fact_survey_responses 
GROUP BY Typical_consumption_situations
ORDER BY consumption_situation_count DESC
;

-- c. What factors influence respondents' purchase decisions, such as price range and limited edition packaging?
SELECT Price_range, 
		COUNT(*)  as price_preference_count,
        ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM fact_survey_responses),2) AS price_preference_pct
FROM fact_survey_responses 
GROUP BY Price_range;

--
SELECT Limited_edition_packaging, 
       COUNT(*) AS Limited_edition_packaging,
       ROUND(100.0 * COUNT(*) / sum(count(*)) over(),2) AS Limited_edition_packaging_Share_pct
FROM fact_survey_responses 
GROUP BY Limited_edition_packaging
ORDER BY Limited_edition_packaging DESC;

-- Product Development
-- a. Which area of business should we focus more on our product development? (Branding/taste/availability)
SELECT Taste_experience, 
       COUNT(*) Taste_experience_count ,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM fact_survey_responses WHERE Tried_before = 'Yes' ),2) AS percentage
FROM fact_survey_responses 
WHERE Tried_before = 'Yes'
GROUP BY Taste_experience ;

-- 
SELECT Brand_perception,
       COUNT(*) AS brand_perception_count,
	ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM fact_survey_responses ),2) AS brand_perception_pct
FROM fact_survey_responses 
GROUP BY Brand_perception;
--

SELECT Improvements_desired,
       COUNT(*) as Improvements_desired_count,
	  ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM fact_survey_responses ),2) AS Improvements_desired_share_pct
FROM fact_survey_responses 
GROUP BY Improvements_desired
ORDER BY Improvements_desired_share_pct DESC;


-- 
SELECT Reasons_preventing_trying,
       COUNT(*) AS counter,
        ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM fact_survey_responses ),2) AS percentage
FROM fact_survey_responses 
GROUP BY Reasons_preventing_trying 
ORDER BY counter DESC;


-- Secondary Insights (Sample Sections / Questions)
-- What immediate improvements can we bring to the product?
-- 1. they could do increase availablity by comparing preferred brand and reasons for choosing this brand

SELECT Current_brands , 
       Reasons_for_choosing_brands , 
       COUNT(*)
FROM fact_survey_responses
GROUP BY Current_brands , Reasons_for_choosing_brands 
ORDER BY Current_brands,COUNT(*) DESC;

SELECT Interest_in_natural_or_organic, 
        COUNT(*) AS counter
        
FROM fact_survey_responses
GROUP BY Interest_in_natural_or_organic;

-- What should be the ideal price of our product?
SELECT Price_range, 
        COUNT(*) AS price_range_count
FROM fact_survey_responses
GROUP BY Price_range;

-- What kind of marketing campaigns, offers, and discounts we can run?


-- Who can be a brand ambassador, and why?







