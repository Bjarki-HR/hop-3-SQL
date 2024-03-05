SELECT * from h2.factSales;
SELECT * from h2.dimCalendar;
SELECT * from h2.dimProduct;
SELECT * from h2.dimStore;


-- Turnover and Cost By Year:
SELECT 
    ds.name AS StoreName,
    dp.name AS ProductName,
    dc.year,
    SUM(fs.unitsSold * dp.price) AS Turnover,
    SUM(fs.unitsSold * dp.cost) AS Cost
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
    dc.year;

-- Turnover and Cost By month:
SELECT 
    ds.name AS StoreName,
    dp.name AS ProductName,
    dc.year,
    dc.monthNo,
    SUM(fs.unitsSold * dp.price) AS Turnover,
    SUM(fs.unitsSold * dp.cost) AS Cost
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

-- Turnover and Cost By Week:
SELECT 
    ds.name AS StoreName,
    dp.name AS ProductName,
    dc.year,
    dc.week,
    SUM(fs.unitsSold * dp.price) AS Turnover,
    SUM(fs.unitsSold * dp.cost) AS Cost
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


-- Turnover and Cost By day:
SELECT 
    ds.name AS StoreName,
    dp.name AS ProductName,
    dc.date,
    SUM(fs.unitsSold * dp.price) AS Turnover,
    SUM(fs.unitsSold * dp.cost) AS Cost
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
    dc.date;