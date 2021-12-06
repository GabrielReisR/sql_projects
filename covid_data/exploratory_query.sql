-- See data ----
SELECT *
FROM COVIDProject..CovidDeaths
WHERE continent is not null
ORDER BY 3, 4

SELECT *
FROM COVIDProject..CovidVaccinations
WHERE continent is not null
ORDER BY 3, 4

/* Checking country statistics */
-- Select data that we're going to use ----
SELECT continent, date, total_cases, new_cases, total_deaths, population
FROM COVIDProject..CovidDeaths
WHERE continent is not null
ORDER BY 1, 2

-- Checking total_cases against total_deaths by country: death_percentage ----
SELECT
	location,
	date,
	total_cases,
	total_deaths,
	100 * (total_deaths/total_cases) AS death_percentage
FROM COVIDProject..CovidDeaths
WHERE continent is not null
ORDER BY 1, 2;

-- Check total_deaths by country ----
SELECT
	location,
	MAX(CAST(total_deaths AS int)) AS total_death_count
FROM COVIDProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY total_death_count DESC

-- Looking at total_cases against population: percent_population_infected ----
-- Percentage of population that got COVID
SELECT 
	location,
	date,
	total_cases,
	total_deaths,
	population,
	100 * (total_cases/population) AS percent_population_infected
FROM COVIDProject..CovidDeaths
WHERE continent is not null
ORDER BY 1, 2

-- Looking at highest infection rates compared to population ----
-- Let's check the country with the highest percent of its population infected
SELECT 
	location,
	population,
	MAX(total_cases) AS highest_infection_count,
	MAX(100 * (total_cases/population)) AS percent_population_infected
FROM COVIDProject..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY percent_population_infected DESC

-- Show countries with highest death count by population ----
SELECT 
	location,
	population,
	MAX(total_deaths) AS highest_deaths_count,
	MAX(100 * (total_deaths/population)) AS percent_population_died
FROM COVIDProject..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY percent_population_died DESC

/* Checking continent statistics */
-- Select data that we're going to use ----
SELECT continent, date, total_cases, new_cases, total_deaths, population
FROM COVIDProject..CovidDeaths
WHERE continent is not null
ORDER BY 1, 2

-- Checking total_cases against total_deaths by continent: death_percentage ----
SELECT
	continent,
	date,
	total_cases,
	total_deaths,
	100 * (total_deaths/total_cases) AS death_percentage
FROM COVIDProject..CovidDeaths
WHERE continent is not null
ORDER BY 1, 2;

-- Check total_deaths by continent ----
SELECT
	location,
	MAX(CAST(total_deaths AS int)) AS total_death_count
FROM COVIDProject..CovidDeaths
WHERE continent is null
AND location NOT LIKE '%income%'
GROUP BY location
ORDER BY total_death_count DESC

-- Looking at total_cases against population by continent: percent_population_infected ----
-- Percentage of population that got COVID
SELECT 
	location,
	date,
	total_cases,
	total_deaths,
	100 * (total_cases/population) AS percent_population_infected
FROM COVIDProject..CovidDeaths
WHERE continent is null
AND location NOT LIKE '%income%'
ORDER BY 1, 2

-- Looking at highest infection rates compared to population ----
-- Let's check the continent with the highest percent of its population infected
SELECT 
	location,
	population,
	MAX(total_cases) AS highest_infection_count,
	MAX(100 * (total_cases/population)) AS percent_population_infected
FROM COVIDProject..CovidDeaths
WHERE continent is null
AND location NOT LIKE '%income%'
GROUP BY location, population
ORDER BY percent_population_infected DESC

-- Show continents with highest death count by population ----
SELECT 
	location,
	population,
	MAX(total_deaths) AS highest_deaths_count,
	MAX(100 * (total_deaths/population)) AS percent_population_died
FROM COVIDProject..CovidDeaths
WHERE continent is null
AND location NOT LIKE '%income%'
GROUP BY location, population
ORDER BY percent_population_died DESC

-- Total cases, deaths and death_percentage in world ----
SELECT
	date,
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS int)) AS total_deaths,
	100 * (SUM(CAST(new_deaths AS int))/SUM(new_cases)) AS death_percentage
FROM COVIDProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1, 2;

-- Total number of cases, deaths and death_percentage ----
SELECT
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS int)) AS total_deaths,
	100 * (SUM(CAST(new_deaths AS int))/SUM(new_cases)) AS death_percentage
FROM COVIDProject..CovidDeaths
WHERE continent is not null

/* Joining CovidDeaths and CovidVaccinations */
-- Joining function
SELECT *
FROM COVIDProject..CovidDeaths AS deaths
JOIN COVIDProject..CovidVaccinations AS vaccines
	ON deaths.location = vaccines.location
	AND deaths.date = vaccines.date

-- Looking at total population & total_vaccinations by countries ----
SELECT 
	deaths.continent,
	deaths.location,
	deaths.date,
	population,
	vaccines.new_vaccinations
FROM COVIDProject..CovidDeaths AS deaths
JOIN COVIDProject..CovidVaccinations AS vaccines
	ON deaths.location = vaccines.location
	AND deaths.date = vaccines.date
WHERE deaths.continent is not null
ORDER BY 2, 3

-- Checking total vaccinations by summing new_vaccinations
SELECT 
	deaths.continent,
	deaths.location,
	deaths.date,
	population,
	vaccines.new_vaccinations,
	SUM(CAST(vaccines.new_vaccinations AS bigint)) 
		OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS total_vaccinations
FROM COVIDProject..CovidDeaths AS deaths
JOIN COVIDProject..CovidVaccinations AS vaccines
	ON deaths.location = vaccines.location
	AND deaths.date = vaccines.date
WHERE deaths.continent is not null
ORDER BY 2, 3

-- Creating CTE (common table expression, a temporary named result) ----
WITH pop_vs_vac (continent, location, date, population, new_vaccinations, total_vaccinations)
AS
(
SELECT 
	deaths.continent,
	deaths.location,
	deaths.date,
	population,
	vaccines.new_vaccinations,
	SUM(CAST(vaccines.new_vaccinations AS bigint)) 
		OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS total_vaccinations
FROM COVIDProject..CovidDeaths AS deaths
JOIN COVIDProject..CovidVaccinations AS vaccines
	ON deaths.location = vaccines.location
	AND deaths.date = vaccines.date
WHERE deaths.continent is not null
)
SELECT
	*,
	total_vaccinations/population
FROM pop_vs_vac

-- Creating a temporary table ----
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
	(continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	total_vaccinations float)
INSERT INTO #PercentPopulationVaccinated
SELECT 
	deaths.continent,
	deaths.location,
	deaths.date,
	population,
	vaccines.new_vaccinations,
	SUM(CAST(vaccines.new_vaccinations AS bigint)) 
		OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS total_vaccinations
FROM COVIDProject..CovidDeaths AS deaths
JOIN COVIDProject..CovidVaccinations AS vaccines
	ON deaths.location = vaccines.location
	AND deaths.date = vaccines.date
WHERE deaths.continent is not null
SELECT
	*,
	total_vaccinations/population
FROM #PercentPopulationVaccinated

-- Creating a visualization ----
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
	deaths.continent,
	deaths.location,
	deaths.date,
	deaths.population,
	vaccines.new_vaccinations,
	SUM(CAST(vaccines.new_vaccinations AS bigint)) 
		OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS total_vaccinations
FROM COVIDProject..CovidDeaths AS deaths
JOIN COVIDProject..CovidVaccinations AS vaccines
	ON deaths.location = vaccines.location
	AND deaths.date = vaccines.date
WHERE deaths.continent is not null