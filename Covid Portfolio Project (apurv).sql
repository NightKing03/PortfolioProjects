select * from portfolio.dbo.covid_deaths
where continent is not null
order by 3,4


--select * from portfolio.dbo.covid_vacc
--order by 3, 4


-- select data that we are going to be using

select location , date , total_cases, new_cases , total_deaths , population 
from portfolio.dbo.covid_deaths
order by 1 , 2


-- looking at total cases vs total deaths
-- shows likelihood of dying if you intract covid in your country
create view DeathPercentage as
select location , date , total_cases, new_cases , total_deaths , cast(total_deaths as float)/cast(total_cases as float) * 100 as Death_percentage
from portfolio.dbo.covid_deaths
where location like '%india%'
and continent is not null
order by 1 , 2

-- looking at the toal case vs the population 
-- shows what percentage of population got covid

select location , date, population , total_cases , cast(total_cases as float)/cast(population as float) * 100 as Population_infected
from portfolio.dbo.covid_deaths
--where location like '%states%'
order by 1 ,2

--looking at countries highest infection rate compared to population

create view PercentPopulation as
select location , population , max(total_cases) as Highest_infection_count , max(cast(total_cases as float)/cast(population as float)) * 100 as PercentPopulationInfected
from portfolio.dbo.covid_deaths
--where location like '%states%'
group by location ,population
order by PercentPopulationInfected desc

--showing the countries with highest death count per population

create view highestDeathCount as
select location , max(cast(total_deaths as int)) as Highest_death_count 
from portfolio.dbo.covid_deaths
--where location like '%states%'
where continent is not null
group by location 
order by Highest_death_count desc

--LETS BREAK THING DOWN BY CONTINENT

--Showing the continent with highest death count 

create view TotalDeathCount as
select continent , max(cast(total_deaths as int)) as TotalDeathCount 
from portfolio.dbo.covid_deaths
--where location like '%states%'
where continent is not null
group by continent 
order by TotalDeathCount desc



-- Global Numbers

select Sum(new_cases) as totalcases , sum(cast(new_deaths as int)) as totaldeaths,
CASE
        WHEN SUM(CAST(new_cases AS INT)) = 0 THEN Null
        ELSE (SUM(CAST(new_deaths AS INT)) * 100.0) / SUM(CAST(new_cases AS INT)) End as Death_percentage
from portfolio.dbo.covid_deaths
--where location like '%india%'
where continent is not null
--group by date
order by 1 , 2


--total population vs total vaccination
--Using CTEs


with PopvsVac(Continent , Location , Date , Population , new_vaccinations  , RollingPeopleVaccinated)
as (
SELECT
    cd.continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    CASE
        WHEN SUM(CAST(cv.new_vaccinations AS bigINT)) = 0 THEN NULL
        ELSE SUM(CAST(cv.new_vaccinations AS bigINT)) OVER (PARTITION BY cd.location order by cd.location , cd.date)
    END AS RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population) here to avoid error you need CTE or Temp table
FROM portfolio.dbo.covid_deaths cd
JOIN portfolio.dbo.covid_vacc cv ON cv.location = cd.location
AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
GROUP BY cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
--ORDER BY cd.location, cd.date
)
select * , (RollingPeopleVaccinated/Population)*100 from PopvsVac



--Temp Table

Drop table if exists #percentPopulationvaccinated
Create table #percentPopulationvaccinated
(
continent nvarchar (255),
lenght nvarchar (255),
date datetime ,
population numeric ,
new_vaccinations numeric , 
RollingPeopleVaccinated numeric
)
Insert into #percentPopulationvaccinated
SELECT
    cd.continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    CASE
        WHEN SUM(CAST(cv.new_vaccinations AS bigINT)) = 0 THEN NULL
        ELSE SUM(CAST(cv.new_vaccinations AS bigINT)) OVER (PARTITION BY cd.location order by cd.location , cd.date)
    END AS RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population) here to avoid error you need CTE or Temp table
FROM portfolio.dbo.covid_deaths cd
JOIN portfolio.dbo.covid_vacc cv ON cv.location = cd.location
AND cd.date = cv.date
--WHERE cd.continent IS NOT NULL
GROUP BY cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
--ORDER BY cd.location, cd.date

select * , (RollingPeopleVaccinated/Population)*100 from #percentPopulationvaccinated


--Creating view to store data for later visualisation
create view percentPopulationvaccinated as
SELECT
    cd.continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    CASE
        WHEN SUM(CAST(cv.new_vaccinations AS bigINT)) = 0 THEN NULL
        ELSE SUM(CAST(cv.new_vaccinations AS bigINT)) OVER (PARTITION BY cd.location order by cd.location , cd.date)
    END AS RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population) here to avoid error you need CTE or Temp table
FROM portfolio.dbo.covid_deaths cd
JOIN portfolio.dbo.covid_vacc cv ON cv.location = cd.location
AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
GROUP BY cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
--ORDER BY cd.location, cd.date


--now you can perform the below query

select * from percentPopulationvaccinated