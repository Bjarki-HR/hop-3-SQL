SELECT * from h2.factSales;
SELECT * from h2.dimProduct;
SELECT * from h2.dimStore;



-- Store Product and inventory information
SELECT 
    ds.name AS StoreName,
    ds.city AS StoreCity,
    ds.location AS StoreLocation,
    dp.name AS ProductName,
    dp.category AS ProductCategory,
    dp.cost AS ProductCost,
    dp.price AS ProductPrice,
    fi.inStock AS CurrentStock
FROM 
    [h2].[factInventory] fi
JOIN 
    dimProduct dp ON fi.idProduct = dp.ID
JOIN 
    dimStore ds ON fi.idStore = ds.ID;