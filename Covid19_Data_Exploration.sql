/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views
*/

SELECT * FROM covid_death
WHERE continent IS NOT NULL
ORDER BY 3,4;

-- Select data that we are going to be starting with
SELECT 
	covid_location, 
	covid_date,
	total_cases,
	new_cases,
	total_deaths,
	new_deaths,
	population
FROM covid_death
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Total Deaths vs Total Cases
-- Daily Death Rate from Covid19 (France)
SELECT 
	covid_location, 
	covid_date,
	total_deaths,
	total_cases,
	(total_deaths/total_cases)*100 AS death_rate
FROM covid_death
WHERE  covid_location LIKE '%France%'
	AND continent IS NOT NULL 
ORDER BY covid_location, covid_date;

-- New Deaths vs Population
-- Daily confirmed deaths in France per million people
SELECT 
	covid_location, 
	covid_date,
	population,
	new_deaths,
	new_deaths/(population/1000000) AS death_ratio
FROM covid_death
WHERE covid_location LIKE '%France%'
	AND continent IS NOT NULL
GROUP BY covid_location, covid_date, population, new_deaths
ORDER BY covid_date;

-- Total Cases vs Population
-- Shows what daily percentage of population in France have been infected with Covid
SELECT 
	covid_location, 
	covid_date,
	total_cases,
	population,
	(total_cases/population)*100 AS covid_ratio
FROM covid_death
WHERE covid_location LIKE '%France%' 
	AND continent IS NOT NULL
ORDER BY covid_location, covid_date;

-- New Cases vs Population
-- Daily confirmed new cases per million people in France
SELECT 
	covid_location, 
	covid_date,
	new_cases,
	population,
	(new_cases/(population/1000000)) AS covid_ratio
FROM covid_death
WHERE covid_location LIKE '%France%' 
	AND continent IS NOT NULL
ORDER BY covid_location, covid_date;

-- Countries with High Infection Rate compared to their population
SELECT 
	covid_location, 
	MAX(total_cases) AS highest_cases,
	population,
	(MAX(total_cases)/population)*100 AS covid_ratio
FROM covid_death
WHERE total_cases IS NOT NULL 
	AND population IS NOT NULL
	AND continent IS NOT NULL
GROUP BY covid_location, population
ORDER BY covid_ratio DESC;

--Countries with Highest Total Deaths compared to their population
SELECT 
	covid_location, 
	MAX(total_deaths) AS highest_death_count,
	population,
	(MAX(total_deaths)/population)*100 AS death_ratio
FROM covid_death
WHERE total_deaths IS NOT NULL
	AND population IS NOT NULL
	AND continent IS NOT NULL
GROUP BY covid_location, population
ORDER BY death_ratio DESC;

--BREAKING IT DOWN BY CONTINENT
--Continents with Highest Total Deaths
SELECT 
	covid_location, 
	MAX(total_deaths) AS total_death_count
FROM covid_death
WHERE continent IS NULL
	AND covid_location NOT IN 
	('World', 
	 'High income', 
	 'Upper middle income', 
	 'Lower middle income', 
	 'European Union', 
	 'Low income', 
	 'International')
GROUP BY covid_location
ORDER BY total_death_count DESC;

--GLOBAL NUMBERS
--Showing total new death rate per day accross the world
SELECT 
	covid_date,
	SUM(new_cases) AS total_cases_per_day,
	SUM(new_deaths) AS total_deaths_per_day,
	SUM(new_deaths)/SUM(new_cases)*100 AS death_rate
FROM covid_death
WHERE continent IS NOT NULL
GROUP BY covid_date
ORDER BY covid_date;

--Showing total death rate accross the world
SELECT 
	SUM(new_cases) AS total_cases,
	SUM(new_deaths) AS total_deaths,
	SUM(new_deaths)/SUM(new_cases)*100 AS death_rate
FROM covid_death
WHERE continent IS NOT NULL;


-- Moving on to Vaccination Data
SELECT * FROM covid_vaccination
WHERE continent IS NOT NULL
ORDER BY 3,4;

-- Looking at Changes in the Vaccination Ratio over time
--Using CTE (Common Table Expression)
With populationVsVaccinations(
	covid_location,
	covid_date,
	population,
	new_vaccinations,
	rolling_people_vaccinated
) AS(
	SELECT 
		deaths.covid_location,
		deaths.covid_date,
		deaths.population,
		vaccines.new_vaccinations,
		SUM(vaccines.new_vaccinations) 
			OVER (PARTITION BY deaths.covid_location
			 ORDER BY deaths.covid_location, deaths.covid_date)
			AS rolling_people_vaccinated
	FROM covid_vaccination vaccines
	INNER JOIN covid_death deaths
	ON deaths.covid_location = vaccines.covid_location
		AND deaths.covid_date = vaccines.covid_date
	WHERE deaths.continent IS NOT NULL
)

SELECT *, (rolling_people_vaccinated/population)*100 AS vaccination_ratio
FROM populationVsVaccinations;

--Using Temp Table
DROP TABLE IF EXISTS temp_populationVsVaccinations;
CREATE TEMP TABLE temp_populationVsVaccinations(
	covid_location VARCHAR(300),
	covid_date DATE,
	population BIGINT,
	new_vaccinations BIGINT,
	rolling_people_vaccinated NUMERIC
);
INSERT INTO temp_populationVsVaccinations(
	SELECT 
		deaths.covid_location,
		deaths.covid_date,
		deaths.population,
		vaccines.new_vaccinations,
		SUM(vaccines.new_vaccinations) 
			OVER (PARTITION BY deaths.covid_location
			 ORDER BY deaths.covid_location, deaths.covid_date)
			AS rolling_people_vaccinated
	FROM covid_vaccination vaccines
	INNER JOIN covid_death deaths
	ON deaths.covid_location = vaccines.covid_location
		AND deaths.covid_date = vaccines.covid_date
	WHERE deaths.continent IS NOT NULL
);

SELECT *, (rolling_people_vaccinated/population)*100 AS vaccination_ratio
FROM temp_populationVsVaccinations
WHERE covid_location LIKE '%Cuba';


-- Looking at Ratio of Fully Vaccinated People per Country as of Feb 14 2023
SELECT 
	deaths.covid_location,
	deaths.population,
	MAX(vaccines.people_fully_vaccinated) AS people_fully_vaccinated,
	MAX(vaccines.people_fully_vaccinated)/deaths.population * 100 AS vaccination_ratio
FROM covid_vaccination vaccines
INNER JOIN covid_death deaths
ON deaths.covid_location = vaccines.covid_location
	AND deaths.covid_date = vaccines.covid_date
WHERE deaths.continent IS NOT NULL
GROUP BY deaths.continent, deaths.covid_location, deaths.population
HAVING MAX(vaccines.people_fully_vaccinated)/deaths.population * 100 >100
ORDER BY deaths.covid_location;

-- Looking at Ratio of Fully Vaccinated People per Continent as of Feb 14 2023
SELECT 
	deaths.covid_location,
	deaths.covid_date,
	deaths.population,
	MAX(vaccines.people_fully_vaccinated) AS people_fully_vaccinated,
	MAX(vaccines.people_fully_vaccinated)/deaths.population * 100 AS vaccination_ratio
FROM covid_vaccination vaccines
INNER JOIN covid_death deaths
ON deaths.covid_location = vaccines.covid_location
	AND deaths.covid_date = vaccines.covid_date
WHERE deaths.continent IS  NULL
AND deaths.covid_location NOT IN 
	('World', 
	 'High income', 
	 'Upper middle income', 
	 'Lower middle income', 
	 'European Union', 
	 'Low income', 
	 'International')
GROUP BY deaths.continent, deaths.covid_location, deaths.population, deaths.covid_date
ORDER BY deaths.covid_location;

--Creating Views to be used in Tableau

--View to Store Vaccination Ratio Per Continent
CREATE VIEW vaccination_ratio_per_continent AS
SELECT 
	deaths.continent,
	deaths.covid_location,
	deaths.population,
	MAX(vaccines.total_vaccinations) AS total_vaccinations,
	(MAX(vaccines.total_vaccinations)/deaths.population) * 100 AS vaccination_ratio
FROM covid_vaccination vaccines
INNER JOIN covid_death deaths
ON deaths.covid_location = vaccines.covid_location
	AND deaths.covid_date = vaccines.covid_date
WHERE deaths.continent IS NULL
GROUP BY deaths.continent, deaths.covid_location, deaths.population
ORDER BY deaths.covid_location;

SELECT * FROM vaccination_ratio_per_continent;

--View to Store Likelihood of Death From Covid in France
CREATE VIEW likelihood_of_death_france AS
SELECT 
	covid_location, 
	covid_date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 AS death_ratio
FROM covid_death
WHERE covid_location LIKE '%France%'
ORDER BY covid_location, covid_date;

SELECT * FROM likelihood_of_death_france;

--View to Store Highest Infection Rate Per Country
CREATE VIEW highest_infection_rate_per_country AS
SELECT 
	covid_location, 
	MAX(total_cases) AS highest_cases,
	population,
	MAX((total_cases/population))*100 AS covid_ratio
FROM covid_death
WHERE total_cases IS NOT NULL 
	AND population IS NOT NULL
	AND continent IS NOT NULL
GROUP BY covid_location, population
ORDER BY covid_ratio DESC;

SELECT * FROM highest_infection_rate_per_country;

--View to Store Highest Death Rate Per Country
CREATE VIEW highest_death_rate_per_country AS
SELECT 
	covid_location, 
	MAX(total_deaths) AS highest_death_rate,
	population,
	MAX((total_deaths/population))*100 AS death_ratio
FROM covid_death
WHERE total_deaths IS NOT NULL 
	AND population IS NOT NULL
	AND continent IS NOT NULL
GROUP BY covid_location, population
ORDER BY death_ratio DESC;

SELECT * FROM highest_death_rate_per_country;

-- View to Store Total Deaths per Continent
CREATE VIEW highest_total_death_rate_per_continent AS
SELECT 
	covid_location, 
	MAX(total_deaths) AS highest_death_rate
FROM covid_death
WHERE continent IS NULL
GROUP BY covid_location
ORDER BY highest_death_rate DESC;

SELECT * FROM highest_total_death_rate_per_continent