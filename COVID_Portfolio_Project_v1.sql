SELECT *
FROM PortfolioProject..CovidDeath
ORDER BY location, date;

--SELECT *
--FROM PortfolioProject..CovidVaccination
--ORDER BY location, date


/*Continent and Countries recorded in this study*/
SELECT DISTINCT continent
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
ORDER BY continent;

SELECT DISTINCT location
FROM PortfolioProject..CovidDeath
WHERE continent IS NULL
ORDER BY location;

--Create view of countries in North America
CREATE VIEW [North America's Country] AS
SELECT DISTINCT location
FROM PortfolioProject..CovidDeath
WHERE continent = 'North America';

SELECT *
FROM [North America's Country]
ORDER BY location;


SELECT DISTINCT location
FROM PortfolioProject..CovidDeath
WHERE continent = 'South America'
ORDER BY location;

SELECT DISTINCT location
FROM PortfolioProject..CovidDeath
WHERE continent = 'Asia'
ORDER BY location;

SELECT DISTINCT location
FROM PortfolioProject..CovidDeath
WHERE continent = 'Africa'
ORDER BY location;

SELECT DISTINCT location
FROM PortfolioProject..CovidDeath
WHERE continent = 'Europe'
ORDER BY location;

SELECT DISTINCT location
FROM PortfolioProject..CovidDeath
WHERE continent = 'Oceania'
ORDER BY location;


/*Select data that is going to be used.*/
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeath
ORDER BY location, date;


/*Total Cases vs Total Deaths*/
--It shows the likelihood of dying if infected with covid in your country.
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM PortfolioProject..CovidDeath
WHERE location LIKE 'Ca%da'
ORDER BY date;

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM PortfolioProject..CovidDeath
WHERE location LIKE 'Mal%sia'
ORDER BY date;


/*Total Cases vs Population*/
--It shows the percentage of population infected with covid.
SELECT location, date, total_cases, population, (total_cases/population)*100 AS case_percentage
FROM PortfolioProject..CovidDeath
WHERE location LIKE 'Canada'
ORDER BY date;

SELECT location, date, total_cases, population, (total_cases/population)*100 AS case_percentage
FROM PortfolioProject..CovidDeath
WHERE location LIKE 'Malaysia'
ORDER BY date;


/*Countries with Highest Infection Rate compared to Population*/
SELECT location, population, MAX(total_cases) AS total_infection_count, MAX((total_cases/population)*100) AS case_percentage
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL -- to remove continent indicator in the result
GROUP BY location, population
--HAVING location = 'Malaysia'
--HAVING location = 'Canada'
ORDER BY total_infection_count DESC;


/*Countries with Highest Death Count per Population*/
SELECT location, population, MAX(CAST(total_deaths AS float)) AS total_death_count, MAX((total_deaths/population)*100) AS death_percentage
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL -- to remove continent indicator in the result
GROUP BY location, population
--HAVING location = 'Malaysia';
--HAVING location = 'Canada'
ORDER BY total_death_count DESC;


/*Total Death Count by Continent*/
SELECT location, MAX(CAST(total_deaths AS float)) AS total_death_count, MAX((total_deaths/population)*100) AS death_percentage
FROM PortfolioProject..CovidDeath
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC;


/*Confirm the total death count in North America*/
CREATE VIEW [North America Death Count] AS --Create a view for North America
SELECT location, MAX(CAST(total_deaths AS float)) AS total_death_count
FROM PortfolioProject..CovidDeath
WHERE continent = 'North America'
GROUP BY location;

SELECT SUM(total_death_count) AS total_death_count_in_North_America
FROM [North America Death Count]

/*Global Numbers*/
SELECT 
	date, 
	SUM(new_cases) AS total_new_case, 
	SUM(CAST(new_deaths AS float)) AS total_new_death,
	ROUND((SUM(CAST(new_deaths AS float))/SUM(new_cases))*100,2) AS death_percentage
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

/*Joining both Covid Death and Covid Vaccination tables together*/
SELECT*
FROM PortfolioProject..CovidDeath AS dea
INNER JOIN PortfolioProject..CovidVaccination AS vac
	ON dea.location=vac.location 
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL;


/*Total Population vs New Vaccinations per day*/
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.location ORDER BY dea.date, dea.location) AS cumulative_vaccinated
FROM PortfolioProject..CovidDeath AS dea
INNER JOIN PortfolioProject..CovidVaccination AS vac
	ON dea.location=vac.location 
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL --AND dea.location='Canada'
ORDER BY 2,3;


--use CTE to view the vaccinated percentage over population
WITH PopvsVac AS
(SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.location ORDER BY dea.date, dea.location) AS cumulative_vaccinated
FROM PortfolioProject..CovidDeath AS dea
INNER JOIN PortfolioProject..CovidVaccination AS vac
	ON dea.location=vac.location 
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL) 
--ORDER BY 2,3)

SELECT*, ROUND((cumulative_vaccinated/population)*100,2) AS vaccinated_percentage
FROM PopvsVac
WHERE location='Canada'
ORDER BY 2,3;


--Temporary table
DROP TABLE IF exists PercentageVaccinatedPopulation --add this "DROP TABLE" statement in case you might do many times alteration

CREATE TABLE PercentageVaccinatedPopulation(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population float,
	new_vaccination float,
	cummulative_vaccinated float
	)

INSERT INTO PercentageVaccinatedPopulation
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.location ORDER BY dea.date, dea.location) AS cumulative_vaccinated
FROM PortfolioProject..CovidDeath AS dea
INNER JOIN PortfolioProject..CovidVaccination AS vac
	ON dea.location=vac.location 
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL;

SELECT*, ROUND((cummulative_vaccinated/population)*100,2) AS vaccinated_percentage
FROM PercentageVaccinatedPopulation;


/*Creating view to store date for visualisation*/
CREATE VIEW PercentVaccinatedPopulation AS
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.location ORDER BY dea.date, dea.location) AS cumulative_vaccinated
FROM PortfolioProject..CovidDeath AS dea
INNER JOIN PortfolioProject..CovidVaccination AS vac
	ON dea.location=vac.location 
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL;

SELECT*
FROM PercentVaccinatedPopulation

