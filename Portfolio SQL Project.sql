select *
from [Covid Deaths]
where continent IS NOT NULL
order by 3, 4

select *
from [Covid Vaccinations]
order by 3, 4

--select data used in the project

select location, date, total_cases, new_cases, total_deaths, population
from [Covid Deaths]
order by 1,2

---Looking at Total Cases Vs Total Deaths (likelihood of dying after contracting covid in a country)
SELECT
    location,
    date,
    total_cases,
    total_deaths,
    CASE
        WHEN TRY_CAST(total_cases AS decimal(10, 2)) IS NOT NULL
            AND TRY_CAST(total_deaths AS decimal(10, 2)) IS NOT NULL
            AND TRY_CAST(total_cases AS decimal(10, 2)) <> 0
        THEN (CONVERT(decimal(10, 2), total_deaths) / CONVERT(decimal(10, 2), total_cases)) * 100
        ELSE NULL
    END AS DeathPercentage
FROM
    [Covid Deaths]
WHERE location like '%Italy%'
ORDER BY   1, 2;

--Looking at Total Cases vs Population (shows what percentage of population got Covid)

SELECT
    location,
    date,
    total_cases,
    population,
    CASE
        WHEN TRY_CAST(total_cases AS decimal(10, 2)) IS NOT NULL
            AND TRY_CAST(population AS decimal(10, 2)) IS NOT NULL
            AND TRY_CAST(total_cases AS decimal(10, 2)) <> 0
        THEN (CONVERT(decimal(10, 2), total_cases) / CONVERT(decimal(10, 2), population)) * 100
        ELSE NULL
    END AS PopulationPercentage
FROM
    [Covid Deaths]
WHERE total_cases IS NOT NULL and location like '%Italy%'
ORDER BY   1, 2;

--Looking at countries with highest infection rates compared to population

SELECT
    location,
    MAX(total_cases) AS HighestInfectionCount,
    MAX(population) AS population,
    CASE
        WHEN TRY_CAST(MAX(total_cases) AS decimal(18, 2)) IS NOT NULL
            AND TRY_CAST(MAX(population) AS decimal(18, 2)) IS NOT NULL
            AND TRY_CAST(MAX(total_cases) AS decimal(18, 2)) <> 0
        THEN MAX(CONVERT(decimal(18, 2), total_cases) / NULLIF(CONVERT(decimal(18, 2), population), 0)) * 100
        ELSE NULL
    END AS PopulationPercentageInfected
FROM
    [Covid Deaths]
WHERE
    total_cases IS NOT NULL 
GROUP BY
    location
ORDER BY
    PopulationPercentageInfected desc;

--Looking at countries with highest death count per population

SELECT
    location,
    MAX(cast(total_deaths as int)) AS TotalDeathCount 
FROM
    [Covid Deaths]
where continent IS NOT NULL
GROUP BY
    location
ORDER BY
    TotalDeathCount desc;

---breakdown of deathcount by continent

SELECT
    location,
    MAX(cast(total_deaths as int)) AS TotalDeathCount,
	MAX(cast(population as bigint))as Population
FROM
    [Covid Deaths]
where continent IS NULL and location not like '%income%'
GROUP BY
    location
ORDER BY
    TotalDeathCount desc;

---Looking for death rate per continent/globally

SELECT
    location,
    MAX(CAST(total_deaths AS int)) AS TotalDeathCount,
    MAX(CAST(total_cases AS bigint)) AS TotalCases,
    CASE
        WHEN MAX(CAST(total_deaths AS decimal(18, 2))) IS NOT NULL
            AND MAX(CAST(total_cases as decimal(18, 2))) IS NOT NULL
            AND MAX(CAST(total_deaths AS decimal(18, 2))) <> 0
        THEN MAX(CAST(total_deaths AS decimal(18, 2)) / NULLIF(CAST(total_cases AS decimal(18, 2)), 0)) * 100
        ELSE NULL
    END AS Death_Rate
FROM
    [Covid Deaths]
WHERE
    continent IS NULL
    AND location NOT LIKE '%income%' 
GROUP BY
    location
ORDER BY
    TotalDeathCount DESC;

-- Looking at Total Population vs Vaccinations

select dea.continent, dea.location, dea.date, dea.population, cast(vac.new_vaccinations as int) as new_vaccinations
, sum(cast(vac.new_vaccinations as bigint)) over (Partition by dea.location order by dea.location, dea.date) as Total_vaccinations
from [Covid Deaths] dea
join [Covid Vaccinations] vac
on dea.location = vac.location
and dea.date = vac.date
where new_vaccinations IS NOT NULL and dea.continent IS NOT NULL
order by new_vaccinations desc

--using CTE

WITH PopvsVac (Continent, Location, Date, Population,new_vaccinations, Total_vaccinations)
as 
(select dea.continent, dea.location, dea.date, dea.population, cast(vac.new_vaccinations as int) as new_vaccinations
, sum(cast(vac.new_vaccinations as bigint)) over (Partition by dea.location order by dea.location, dea.date) as Total_vaccinations
from [Covid Deaths] dea
join [Covid Vaccinations] vac
on dea.location = vac.location
and dea.date = vac.date
where new_vaccinations IS NOT NULL and dea.continent IS NOT NULL
)
select *, (Total_vaccinations/population)*100 as vaccination_rate
from PopvsVac 

--using TEMP TABLE

CREATE Table #PercentpopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccnations numeric,
total_vaccinations numeric,
)

insert into #PercentpopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, cast(vac.new_vaccinations as int) as new_vaccinations
, sum(cast(vac.new_vaccinations as bigint)) over (Partition by dea.location order by dea.location, dea.date) as Total_vaccinations
from [Covid Deaths] dea
join [Covid Vaccinations] vac
on dea.location = vac.location
and dea.date = vac.date
where new_vaccinations IS NOT NULL and dea.continent IS NOT NULL

select *, (Total_vaccinations/population)*100 as vaccination_rate
from #PercentpopulationVaccinated

--creating view to store data for later visualization

create view Infection_Rates as 
SELECT
    location,
    MAX(total_cases) AS HighestInfectionCount,
    MAX(population) AS population,
    CASE
        WHEN TRY_CAST(MAX(total_cases) AS decimal(18, 2)) IS NOT NULL
            AND TRY_CAST(MAX(population) AS decimal(18, 2)) IS NOT NULL
            AND TRY_CAST(MAX(total_cases) AS decimal(18, 2)) <> 0
        THEN MAX(CONVERT(decimal(18, 2), total_cases) / NULLIF(CONVERT(decimal(18, 2), population), 0)) * 100
        ELSE NULL
    END AS PopulationPercentageInfected
FROM
    [Covid Deaths]
WHERE
    total_cases IS NOT NULL 
GROUP BY
    location

select *
from Infection_Rates


create view Death_Rates as 
SELECT
    location,
    MAX(CAST(total_deaths AS int)) AS TotalDeathCount,
    MAX(CAST(total_cases AS bigint)) AS TotalCases,
    CASE
        WHEN MAX(CAST(total_deaths AS decimal(18, 2))) IS NOT NULL
            AND MAX(CAST(total_cases as decimal(18, 2))) IS NOT NULL
            AND MAX(CAST(total_deaths AS decimal(18, 2))) <> 0
        THEN MAX(CAST(total_deaths AS decimal(18, 2)) / NULLIF(CAST(total_cases AS decimal(18, 2)), 0)) * 100
        ELSE NULL
    END AS Death_Rate
FROM
    [Covid Deaths]
WHERE
    continent IS NULL
    AND location NOT LIKE '%income%' 
GROUP BY
    location

select *
from Death_Rates
--END!
