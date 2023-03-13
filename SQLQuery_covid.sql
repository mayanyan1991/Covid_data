select *
from CovidDeath$
where continent is not null -- not take continent into account
order by 3,4

--select *
--from CovidVacci$
--order by 3,4

--select Data that I am going to use
select Location, Date, total_cases,new_cases,total_deaths,population
from CovidDeath$
order by 1,2

--looking at Total cases vs Total Deaths
select Location, Date, total_cases,total_deaths, (total_deaths/total_cases)*100 As death_percentage
from CovidDeath$
Where location = 'Sweden'
order by 1,2

--looking at total cases vs population
select Location, Date, total_cases,population, (total_cases/population)*100 As case_percentage
from CovidDeath$
Where location = 'Sweden'
order by 1,2

--looking at countries with highest infection rate compared to population
select Location, MAX(total_cases) HighestInfectionCount, Max((total_cases/population)*100) As HighestPercentageInfection
from CovidDeath$
where continent is not null
Group by location
order by HighestPercentageInfection desc

--showing the country with the highest death count per population
select Location, MAX(cast(total_deaths as int)) HighestDeathCount, Max((total_deaths/population)*100) As HighestPercentageDeath
from CovidDeath$
where continent is not null
Group by location
order by HighestPercentageDeath desc

--showing group by continent
select location, MAX(cast(total_deaths as int)) HighestDeathCount
from CovidDeath$
where continent is null
Group by location
order by HighestDeathCount desc

--global daily
select Date, SUM(new_cases), SUM(cast(new_deaths as int)) as SumDeath, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
from CovidDeath$
Where continent is not null
group by date
order by date

--join tables, looking at lotal population vs vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.Date) as SumVacci
---accumulative vaccine by date
from CovidDeath$ dea
Join CovidVacci$ vac
	on dea.location = vac.Location
	AND dea.date = vac.date
Where dea.continent is not null

--use CTE
With temp_pop_vacci (Continent, Location, Date, Population, New_vaccine, SumVacci) --column number should be the same
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.Date) as SumVacci
---accumulative vaccine by date
from CovidDeath$ dea
Join CovidVacci$ vac
	on dea.location = vac.Location
	AND dea.date = vac.date
Where dea.continent is not null
)
select *, (SumVacci/population)*100
from temp_pop_vacci


--temp table
Drop table if exists #PercentPop
Create Table #PercentPop
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric,
RollingPeopleVacci numeric
)

Insert into #PercentPop
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.Date) as SumVacci
---accumulative vaccine by date
from CovidDeath$ dea
Join CovidVacci$ vac
	on dea.location = vac.Location
	AND dea.date = vac.date
Where dea.continent is not null

select *, (RollingPeopleVacci/population)*100
from #PercentPop


--create view to store data for later visualizations
Create View PercentPop AS 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.Date) as SumVacci
---accumulative vaccine by date
from CovidDeath$ dea
Join CovidVacci$ vac
	on dea.location = vac.Location
	AND dea.date = vac.date
Where dea.continent is not null
