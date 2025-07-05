--SELECT * FROM dbo.customers
--SELECT * FROM dbo.geography

SELECT
	c.CustomerID,
	c.CustomerName,
	c.Email,
	c.Gender,
	c.Age,
	g.Country,
	g.City

--INTO dbo.fixed_customers_geography
FROM
	dbo.customers as c
LEFT JOIN 
	dbo.geography g
ON
	c.GeographyID = g.GeographyID;
