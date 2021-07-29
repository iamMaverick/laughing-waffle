--Quick data check--
use [Portfolio-Project]

SELECT TOP(1000) * FROM [Portfolio-Project]..covid_deaths$
SELECT TOP(1000) * FROM [Portfolio-Project]..[covid_vaccinations$]

--SELECT DATA THAT WE ARE GOING TO USE--

SELECT Location, date, total_Cases, new_cases, total_deaths, population
FROM [Portfolio-Project]..covid_deaths$
ORDER BY 1,2

-- Will be looking at total cases and total deaths--
--shows that the likelihood of dying if you contract covid at ths set location
SELECT Location, date,total_cases, total_deaths, concat(((total_deaths/total_cases)*100),'%') as DeathPerc
FROM [Portfolio-Project]..covid_deaths$
WHERE LOCATION LIKE '%states%'
ORDER BY 2 DESC


--Looking at the total cases vs population
SELECT Location, date,total_cases, population, concat(((total_cases/population)*100),'%') as PopulateionPerc
FROM [Portfolio-Project]..covid_deaths$
WHERE LOCATION LIKE '%states%'
ORDER BY 2 DESC

--checking which country has the highest rate compared to population
SELECT Location,population, MAX(total_cases) as HighestInfectionCount,concat(((MAX(total_cases)/population)*100),'%') as PopulateionPerc
FROM [Portfolio-Project]..covid_deaths$
--WHERE LOCATION LIKE '%states%'
GROUP BY Location,population
ORDER BY 4 DESC

-- see, how many people died?

SELECT Location, MAX(convert(int, total_deaths)) as HeighestDeathCount
FROM [Portfolio-Project]..covid_deaths$
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY HeighestDeathCount DESC

--EDA by continent

SELECT continent, MAX(convert(int, total_deaths)) as Total_count
FROM [Portfolio-Project]..covid_deaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Total_count DESC

--showing the continents with highest death_count

SELECT continent, MAX(convert(int, total_deaths)) as HeighestDeathCount
FROM [Portfolio-Project]..covid_deaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY HeighestDeathCount DESC

-- global numbers EDA

SELECT SUM(new_cases) as Sum_new_cases, SUM(convert(int,new_deaths)) as Sum_new_deaths, concat(((SUM(convert(int,new_deaths))/SUM(new_cases))*100),' %') as DeathPerc
FROM [Portfolio-Project]..covid_deaths$
WHERE 
--LOCATION LIKE '%states%'
continent IS NOT NULL
ORDER BY 1 DESC

--on daily basis

SELECT date,SUM(new_cases) as Sum_new_cases, SUM(convert(int,new_deaths)) as Sum_new_deaths, concat(((SUM(convert(int,new_deaths))/SUM(new_cases))*100),' %') as DeathPerc
FROM [Portfolio-Project]..covid_deaths$
WHERE 
--LOCATION LIKE '%states%'
continent IS NOT NULL
GROUP BY date
ORDER BY 1 DESC

--on weekly basis

SELECT DATEPART(WEEK, date) as Week_number,SUM(new_cases) as Sum_new_cases, SUM(convert(int,new_deaths)) as Sum_new_deaths, concat(((SUM(convert(int,new_deaths))/SUM(new_cases))*100),' %') as DeathPerc
FROM [Portfolio-Project]..covid_deaths$
WHERE 
--LOCATION LIKE '%states%'
continent IS NOT NULL
GROUP BY DATEPART(WEEK, date)
ORDER BY 1 DESC

--on monthly basis
SELECT DATEPART(MM, date) as Week_number,SUM(new_cases) as Sum_new_cases, SUM(convert(int,new_deaths)) as Sum_new_deaths, concat(((SUM(convert(int,new_deaths))/SUM(new_cases))*100),' %') as DeathPerc
FROM [Portfolio-Project]..covid_deaths$
WHERE 
--LOCATION LIKE '%states%'
continent IS NOT NULL
GROUP BY DATEPART(MM, date)
ORDER BY 1 DESC

--on quarterly basis

SELECT DATEPART(QQ, date) as Week_number,SUM(new_cases) as Sum_new_cases, SUM(convert(int,new_deaths)) as Sum_new_deaths, concat(((SUM(convert(int,new_deaths))/SUM(new_cases))*100),' %') as DeathPerc
FROM [Portfolio-Project]..covid_deaths$
WHERE 
--LOCATION LIKE '%states%'
continent IS NOT NULL
GROUP BY DATEPART(QQ, date)
ORDER BY 1 DESC

--COVID VACCINATIONS--


--Looking at total populations vs vaccinations

SELECT cd.continent, cd.Location, cd.date,cd.population, 
convert(int,cv.new_vaccinations) as new_vaccination,
SUM(convert(int,cv.new_vaccinations)) OVER (PARTITION BY cd.LOCATION ORDER BY cd.Location,cd.date) as Running_Sum_vaccinations
--(Running_Sum_vaccinations/cd.population)*100
FROM [Portfolio-Project]..covid_deaths$ cd
JOIN [Portfolio-Project]..[covid_vaccinations$] cv 
on cd.Location = cv.Location and
cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY 2,3

--USE CTE

WITH PopvsVac(Continent,Location,Date,Population, new_vaccination,Running_Sum_vaccinations)
as
(
 SELECT cd.continent, cd.Location, cd.date,cd.population, 
convert(int,cv.new_vaccinations) as new_vaccination,
SUM(convert(int,cv.new_vaccinations)) OVER (PARTITION BY cd.LOCATION ORDER BY cd.Location,cd.date) as Running_Sum_vaccinations
--(Running_Sum_vaccinations/cd.population)*100
FROM [Portfolio-Project]..covid_deaths$ cd
JOIN [Portfolio-Project]..[covid_vaccinations$] cv 
on cd.Location = cv.Location and
cd.date = cv.date
WHERE cd.continent IS NOT NULL
--ORDER BY 2,3
)
Select *,(Running_Sum_vaccinations/Population)*100 From PopvsVac


--temp table

Go
CREATE TABLE #PercentPopulationVaccinated
(continent nvarchar(255),
Location nvarchar(255),
date datetime,
population numeric,
new_vaccination numeric,
Running_Sum_vaccinations numeric
)
Go
INSERT INTO #PercentPopulationVaccinated
SELECT cd.continent, cd.Location, cd.date,cd.population, 
convert(int,cv.new_vaccinations) as new_vaccination,
SUM(convert(int,cv.new_vaccinations)) OVER (PARTITION BY cd.LOCATION ORDER BY cd.Location,cd.date) as Running_Sum_vaccinations
--(Running_Sum_vaccinations/cd.population)*100
FROM [Portfolio-Project]..covid_deaths$ cd
JOIN [Portfolio-Project]..[covid_vaccinations$] cv 
on cd.Location = cv.Location and
cd.date = cv.date
WHERE cd.continent IS NOT NULL
--ORDER BY 2,3
Go
Select *,(Running_Sum_vaccinations/Population)*100 From #PercentPopulationVaccinated 

--Creating a View for highest deaths
Go
CREATE VIEW PercentPopulationVaccinated  
AS
SELECT 
cd.continent, cd.Location, cd.date,cd.population, 
convert(int,cv.new_vaccinations) as new_vaccination,
SUM(convert(int,cv.new_vaccinations)) OVER (PARTITION BY cd.LOCATION ORDER BY cd.Location,cd.date) as Running_Sum_vaccinations
--(Running_Sum_vaccinations/cd.population)*100
FROM 
[Portfolio-Project]..covid_deaths$ cd
JOIN [Portfolio-Project]..[covid_vaccinations$] cv 
on cd.Location = cv.Location and
cd.date = cv.date
WHERE 
cd.continent IS NOT NULL
--ORDER BY 2,3

exec PercentPopulationVaccinated;

---
SELECT CAST(
(
SELECT * FROM PercentPopulationVaccinated
FOR XML PATH ('Main')
)
AS VARCHAR(MAX)
)
As XMLDATA;




 






