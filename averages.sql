SELECT * from h2.factSales;
SELECT * from h2.dimCalendar;
SELECT * from h2.dimProduct;
SELECT * from h2.dimStore;

--- Average Turnover
SELECT 
    fs.receipt,
    AVG(fs.unitsSold * dp.price) AS AverageTurnover
FROM 
    factSales fs
JOIN 
    dimProduct dp ON fs.idProduct = dp.ID


--- Average Turnover BY RECEIPT
SELECT 
    fs.receipt,
    AVG(fs.unitsSold * dp.price) AS AverageTurnover
FROM 
    factSales fs
JOIN 
    dimProduct dp ON fs.idProduct = dp.ID
GROUP BY 
    fs.receipt


-- Average Amount of a Receipt
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

-- Average Amount PER Receipt
SELECT 
    fs.receipt,
    AVG(dp.price) AS AveragePrice
FROM 
    factSales fs
JOIN 
    dimProduct dp ON fs.idProduct = dp.ID
GROUP BY 
    fs.receipt

-- Average price product
SELECT 
    AVG(dp.price)as averagePrice
FROM 
    dimProduct dp


-- Average price PER product
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

-- Average Number of Units Purchased per receipt:
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

