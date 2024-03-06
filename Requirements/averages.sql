SELECT * from h2.factSales;
SELECT * from h2.dimCalendar;
SELECT * from h2.dimProduct;
SELECT * from h2.dimStore;

--------------- Average Turnover -------------------

SELECT 
    fs.receipt,
    AVG(fs.unitsSold * dp.price) AS AverageTurnover
FROM 
    factSales fs
JOIN 
    dimProduct dp ON fs.idProduct = dp.ID



---- Average Turnover BY RECEIPT --------------------

SELECT 
    fs.receipt,
    AVG(fs.unitsSold * dp.price) AS AverageTurnover
FROM 
    factSales fs
JOIN 
    dimProduct dp ON fs.idProduct = dp.ID
GROUP BY 
    fs.receipt


-- Average Turnover OF A RECEIPT --------------------

SELECT 
    AVG(ReceiptTotal.Turnover) AS AverageReceiptAmount
FROM 
    (SELECT 
        fs.receipt,
        SUM(fs.unitsSold * dp.price) AS Turnover
     FROM 
        factSales fs
     JOIN 
        dimProduct dp ON fs.idProduct = dp.ID
     GROUP BY 
        fs.receipt
    ) AS ReceiptTotal;


-- Average Turnover PER RECEIPT --------------------

SELECT 
    fs.receipt,
    AVG(dp.price) AS AveragePrice
FROM 
    factSales fs
JOIN 
    dimProduct dp ON fs.idProduct = dp.ID
GROUP BY 
    fs.receipt

-------------------------------------------------
--------------- Average Price -------------------

SELECT 
    AVG(dp.price)as averagePrice
FROM 
    dimProduct dp


-- Average price PER PRODUCT --------------------

SELECT 
    fs.idProduct,
    dp.name AS ProductName,
    AVG(dp.price) AS AveragePrice
FROM 
    factSales fs
JOIN 
    dimProduct dp ON fs.idProduct = dp.ID
GROUP BY 
    fs.idProduct, dp.name;


-- Average NUM OF UNITS PURCHASED PER RECEIPT ----

SELECT 
    AVG(ReceiptUnits.TotalUnits) AS AverageUnitsPerReceipt
FROM 
    (SELECT 
        fs.receipt,
        SUM(fs.unitsSold) AS TotalUnits
     FROM 
        factSales fs
     GROUP BY 
        fs.receipt
    ) AS ReceiptUnits;
