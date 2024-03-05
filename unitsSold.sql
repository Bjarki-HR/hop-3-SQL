
SELECT * from h2.factSales;
SELECT * from h2.dimCalendar;
SELECT * from h2.dimProduct;
SELECT * from h2.dimStore;

-- UNITS SOLD By Year:
SELECT 
    ds.name AS StoreName,
    dp.name AS ProductName,
    dc.year,
    SUM(fs.unitsSold) AS UnitsSold
FROM 
    h2.factSales fs
JOIN 
    h2.dimCalendar dc ON fs.idCalendar = dc.[date]
JOIN 
    h2.dimStore ds ON fs.idStore = ds.ID
JOIN 
    h2.dimProduct dp ON fs.idProduct = dp.ID
GROUP BY 
    ds.name, 
    dp.name,
    dc.year;


-- UNITS SOLD By Month:
SELECT 
    ds.name AS StoreName,
    dp.name AS ProductName,
    dc.year,
    dc.monthNo,
    SUM(fs.unitsSold) AS UnitsSold
FROM 
    factSales fs
JOIN 
    dimCalendar dc ON fs.idCalendar = dc.date
JOIN 
    dimStore ds ON fs.idStore = ds.ID
JOIN 
    dimProduct dp ON fs.idProduct = dp.ID
GROUP BY 
    ds.name, 
    dp.name,
    dc.year, 
    dc.monthNo;


-- UNITS SOLD By Week:
SELECT 
    ds.name AS StoreName,
    dp.name AS ProductName,
    dc.year,
    dc.week,
    SUM(fs.unitsSold) AS UnitsSold
FROM 
    factSales fs
JOIN 
    dimCalendar dc ON fs.idCalendar = dc.date
JOIN 
    dimStore ds ON fs.idStore = ds.ID
JOIN 
    dimProduct dp ON fs.idProduct = dp.ID
GROUP BY 
    ds.name, 
    dp.name,
    dc.year, 
    dc.week;

-- UNITS SOLD By Day:
SELECT 
    ds.name AS StoreName,
    dp.name AS ProductName,
    dc.date,
    SUM(fs.unitsSold) AS UnitsSold
FROM 
    factSales fs
JOIN 
    dimCalendar dc ON fs.idCalendar = dc.ID
JOIN 
    dimStore ds ON fs.idStore = ds.ID
JOIN 
    dimProduct dp ON fs.idProduct = dp.ID
GROUP BY 
    ds.name, 
    dp.name,
    dc.date;
