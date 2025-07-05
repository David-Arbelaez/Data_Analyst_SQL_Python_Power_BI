--SELECT * FROM dbo.customer_reviews

SELECT 
    ReviewID, 
    CustomerID, 
    ProductID,  
    ReviewDate,  
    Rating, 
    REPLACE(ReviewText, '  ', ' ') AS ReviewText

--INTO fixed_customer_reviews
FROM 
    dbo.customer_reviews; 
