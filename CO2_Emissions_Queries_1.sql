-- Author: Olivier Vadiavaloo
-- Data Source:
--	Hannah Ritchie, Max Roser and Pablo Rosado (2020) - "CO₂ and Greenhouse Gas Emissions". 
--	Published online at OurWorldInData.org. Retrieved from: 'https://ourworldindata.org/co2-and-other-greenhouse-gas-emissions' [Online Resource]


-- BASIC QUERIES

SELECT *
FROM CO2EmissionsDB..CountriesCO2EmissionsPerYear
ORDER BY country

SELECT *
FROM CO2EmissionsDB..CountryCO2EmissionPerSourceType
ORDER BY country

SELECT *
FROM CO2EmissionsDB..CountriesOtherEmissions
ORDER BY country

SELECT *
FROM CO2EmissionsDB..CountriesEnergyConsumption
ORDER BY country


-- ********************
-- EASY QUERIES
-- ********************

-- (1)
-- Find the CO2 Emission of each country per year. Exclude NULL entries.
-- Order the results in ascending order by country. Note that the emissions
-- are measured in millions of tonnes.
SELECT country AS Country, 
	   year AS [Year], 
	   co2 AS [C02 Emission]
FROM CO2EmissionsDB..CountriesCO2EmissionsPerYear
WHERE co2 IS NOT NULL
ORDER BY 1


-- (2)
-- Find the total CO2 Emission for each country over all the years
-- in which the emissions were recorded. Exclude NULL entries and 
-- order the results in ascending order by country.
SELECT country AS Country, 
	   SUM(co2) AS [Total CO2 Emission]
FROM CO2EmissionsDB..CountriesCO2EmissionsPerYear
WHERE co2 IS NOT NULL
GROUP BY country
ORDER BY 1


-- (3)
-- Find the global CO2 Emission in the 2020.
SELECT SUM(co2)
FROM CO2EmissionsDB..CountriesCO2EmissionsPerYear
WHERE year = 2020


-- (4)
-- Compute the CO2 Emission per GDP for each country over
-- the years. Order the results in ascending order by
-- country.
DECLARE @Trillion AS BIGINT = 1000000000000

SELECT country AS Country, 
	   year AS Year,
	   (co2 / gdp) * @Trillion AS [CO2 Emission Per GDP] 
FROM CO2EmissionsDB..CountriesCO2EmissionsPerYear
WHERE co2 IS NOT NULL AND
	  gdp IS NOT NULL
ORDER BY 1


-- (5)
-- Find the top 10 countries with the highest CO2 emission per capita
-- over all the recorded years.
-- Order results in descending order of CO2 emission per capita.
SELECT TOP(10) country AS Country,
	   year AS [Year],
	   MAX([co2_per_capita]) AS [CO2 Per Capita]
FROM CO2EmissionsDB..CountriesCO2EmissionsPerYear
WHERE co2 IS NOT NULL AND
	  gdp IS NOT NULL
GROUP BY country, year
ORDER BY [CO2 Per Capita] DESC


-- (6)
-- Find the top 10 countries with the highest CO2 emission per capita
-- in the year 2011.
-- Order results in descending order of CO2 emission per capita.
SELECT TOP(10) country AS Country,
	   MAX([co2_per_capita]) AS [CO2 Per Capita]
FROM CO2EmissionsDB..CountriesCO2EmissionsPerYear
WHERE co2 IS NOT NULL AND
	  year = 2011 AND
	  gdp IS NOT NULL
GROUP BY country
ORDER BY [CO2 Per Capita] DESC


-- (7)
-- Find the average GHG and CO2 emissions of each country.
-- Order results by country.
SELECT perYr.country AS [Country],
	   AVG(perYr.co2) AS [Avg CO2 Emission (in millions of tonnes)],
	   AVG(otherEmissions.total_ghg) AS [Avg GHG Emission (in millions of tonnes)]
FROM CO2EmissionsDB..CountriesCO2EmissionsPerYear perYr
	 INNER JOIN CO2EmissionsDB..CountriesOtherEmissions otherEmissions
	 ON perYr.country = otherEmissions.country AND
	 perYr.year = otherEmissions.year
GROUP BY perYr.country


-- (8)
-- Find the maximum CO2 & GHG emission per primary_energy_consumption for each country
-- over all the recorded years.
SELECT perYr.country AS [Country],
	   MAX(perYr.co2 / energyCons.primary_energy_consumption) AS [Max CO2 Per Primary Energy Consumption],
	   MAX(otherEmissions.total_ghg / energyCons.primary_energy_consumption) AS [Max GHG Per Primary Energy Consumption]
FROM CO2EmissionsDB..CountriesCO2EmissionsPerYear perYr
	 INNER JOIN CO2EmissionsDB..CountriesEnergyConsumption energyCons
	 ON perYr.country = energyCons.country AND 
	 perYr.country = energyCons.country
	 INNER JOIN CO2EmissionsDB..CountriesOtherEmissions otherEmissions
	 ON energyCons.country = otherEmissions.country AND
	 energyCons.year = otherEmissions.year
WHERE energyCons.primary_energy_consumption IS NOT NULL AND
	  perYr.co2 IS NOT NULL AND otherEmissions.total_ghg IS NOT NULL AND
	  energyCons.primary_energy_consumption > 0
GROUP BY perYr.country

-- **********************
--  INTERMEDIATE QUERIES
-- **********************

-- (9)
-- Find the share of CO2 Emissions contributed by each source type
-- in Canada over the years.
SELECT perYear.country AS [Country],
	   perYear.year AS [Year], 
	   perSource.coal_co2 / perYear.co2 AS Coal,
	   perSource.flaring_co2 / perYear.co2 AS Flaring,
	   perSource.cement_co2 / perYear.co2 AS Cement,
	   perSource.gas_co2 / perYear.co2 AS Gas,
	   perSource.oil_co2 / perYear.co2 AS Oil,
	   perSource.other_industry_co2 / perYear.co2 AS [Other Industry]
FROM CO2EmissionsDB..CountriesCO2EmissionsPerYear perYear
	 INNER JOIN CO2EmissionsDB..CountryCO2EmissionPerSourceType perSource
	 ON perYear.country = 'Canada' AND 
	 perYear.country = perSource.country AND
	 perYear.[iso_code] = perSource.[iso_code] AND
	 perYear.year = perSource.year
WHERE perYear.co2 IS NOT NULL AND
	  (perSource.coal_co2 IS NOT NULL OR
	  perSource.flaring_co2 IS NOT NULL OR
	  perSource.cement_co2 IS NOT NULL OR
	  perSource.gas_co2 IS NOT NULL OR
	  perSource.oil_co2 IS NOT NULL OR
	  perSource.other_industry_co2 IS NOT NULL)
ORDER BY 2


-- (10)
-- Find which year had the most CO2 Emission from coal.
SELECT TOP(1) year AS [Year],
	   SUM(coal_co2) AS [Coal CO2 Emission]
FROM CO2EmissionsDB..CountryCO2EmissionPerSourceType
WHERE coal_co2 IS NOT NULL
GROUP BY year
ORDER BY 2 DESC


-- (11)
-- Find the highest CO2 for each recorded year by continent.
-- The continents must be columns.
SELECT *
FROM (
	SELECT continent AS [Continent],
		   year AS [Year],
		   co2 AS CO2
	FROM CO2EmissionsDB..ContinentsCO2EmissionsPerYear
	WHERE co2 IS NOT NULL
) base
PIVOT (
	SUM(CO2)
	FOR Continent IN (
		[Africa],
		[Antarctica],
		[Asia],
		[Europe],
		[North America],
		[South America],
		[Australia]
	)
) AS [pivot_table]
ORDER BY Year


-- *********************
--  ADVANCED QUERIES
-- *********************


-- (12)
-- For each source type, find which year had the maximum CO2 emission
-- originating from that source.
WITH sum_src_emission AS (
	SELECT year AS [Year],
		   SUM(coal_co2) AS coal_co2,
		   SUM(cement_co2) AS cement_co2,
		   SUM(flaring_co2) AS flaring_co2,
		   SUM(gas_co2) AS gas_co2,
		   SUM(oil_co2) AS oil_co2,
		   SUM(other_industry_co2) AS other_industry_co2
	FROM CO2EmissionsDB..CountryCO2EmissionPerSourceType
	GROUP BY [Year]
),
unpivoted_src_emission AS (
	SELECT *
	FROM (
			SELECT *
			FROM sum_src_emission
		 ) AS a
		 UNPIVOT (
			SourceCO2Emission FOR Sources IN (
				coal_co2,
				cement_co2,
				flaring_co2,
				gas_co2,
				oil_co2,
				other_industry_co2
			)
		 ) AS p
),
emission_group_by_yr_source  AS (
	SELECT Sources,
		   MAX(SourceCO2Emission) AS MaxSrcCO2Emission
	FROM unpivoted_src_emission
	GROUP BY Sources
)
SELECT unpivotedTable.[Year],
	   unpivotedTable.SourceCO2Emission AS [Source CO2 Emission],
	   SUBSTRING(REPLACE(unpivotedTable.Sources, '_', ' '), 1, LEN(unpivotedTable.Sources) - 4) AS [Source]
FROM emission_group_by_yr_source maxEmission
	 INNER JOIN unpivoted_src_emission unpivotedTable
	 ON maxEmission.Sources = unpivotedTable.Sources AND
	 maxEmission.MaxSrcCO2Emission = unpivotedTable.SourceCO2Emission


-- (13)
-- For each country, find the major source of C02 emission in the
-- year with their record-high C02 emission.
WITH max_co2_per_country AS (
	SELECT country AS [Country],
	       year AS [Year],
		   co2 AS CO2,
		   MAX(co2) OVER (PARTITION BY country) AS [Max CO2 Emission]
	FROM CO2EmissionsDB..CountriesCO2EmissionsPerYear
	WHERE co2 IS NOT NULL
),
max_co2_per_country2 AS (
	SELECT [Country], [Year], [Max CO2 Emission]
	FROM max_co2_per_country
	WHERE [MAX CO2 Emission] = co2
),
max_co2_shares AS (
	SELECT perCountry.[Country],
		   perCountry.[Year],
		   perCountry.[Max CO2 Emission],
		   perSrc.coal_co2 / perCountry.[Max CO2 Emission] AS [Coal Share],
		   perSrc.cement_co2 / perCountry.[Max CO2 Emission] AS [Cement Share],
		   perSrc.flaring_co2 / perCountry.[Max CO2 Emission] AS [Flaring Share],
		   perSrc.gas_co2 / perCountry.[Max CO2 Emission] AS [Gas Share],
		   perSrc.oil_co2 / perCountry.[Max CO2 Emission] AS [Oil Share],
		   perSrc.other_industry_co2 / perCountry.[Max CO2 Emission] AS [Other Industry Share]
	FROM max_co2_per_country2 perCountry
		 INNER JOIN CO2EmissionsDB..CountryCO2EmissionPerSourceType perSrc
		 ON perCountry.[Country] = perSrc.country AND 
			perCountry.[Year] = perSrc.year
),
cross_apply_src_shares AS (
	SELECT ms.[Country], ms.[Year], ms.[Max CO2 Emission],
		   t.[Source Type], t.[CO2 Emission Share]
	FROM max_co2_shares ms
		 CROSS APPLY (
			VALUES
				('coal', ms.[Coal Share]),
				('cement', ms.[Cement Share]),
				('flaring', ms.[Flaring Share]),
				('Gas', ms.[Gas Share]),
				('oil', ms.[Oil Share]),
				('Other Industry', ms.[Other Industry Share])
		 ) t ([Source Type], [CO2 Emission Share])
)
SELECT c1.[Country], c1.[Year], c1.[Source Type], c1.[Max CO2 Emission],
	   c1.[CO2 Emission Share] AS [Source CO2 Emission Share]
FROM cross_apply_src_shares c1
WHERE c1.[CO2 Emission Share] = (
									SELECT MAX(c2.[CO2 Emission Share])
									FROM cross_apply_src_shares c2
									WHERE c1.[Country] = c2.[Country]
							    )
