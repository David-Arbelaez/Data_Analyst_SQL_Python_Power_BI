# Data-Management-Sketch-

<br/>

<h1>What is this about? 🤓</h1> 

<br/>

The idea is to perform a data study exercise and market analysis according to the data provided by the project managers. Multiple technologies such as <b>SQL</b>, <b>Python</b> and <b>PowerBI</b> will be used.

<h3>Index</h3>


- [Problem Description](#Problem-Description)
- [SQL](#SQL)
  - [Data Normalization](###Data-Normalization)
- [Python](#python)

# Problem Description

An online retailer is facing a drop in engagement and sales despite launching multiple campaigns to improve their marketing strategy, which is increasing their costs without significant returns. They decided to contact a data analyst to identify opportunities to improve their strategies.

<br/>

Key Points: 
- Reduced Customer Engagement
- Decreased Conversion Rates
- High Marketing Expenses
- Need for Customer Feedback Analysis

<h1>SQL</h1>

We were provided with multiple databases with the necessary information to carry out our analysis. Among them: Products, Geography, Engagement Data, Customers, Customer Reviews, Customer Journey. Here is a preview of what each looks like:

![image](https://github.com/user-attachments/assets/9732cb10-c08d-4a67-893e-006ef8c57991) ![image](https://github.com/user-attachments/assets/f6a89ebe-e808-4731-8e85-1c7434d82259) 
![image](https://github.com/user-attachments/assets/91aa59d1-6498-47fe-a7d5-360627b54e5b) ![image](https://github.com/user-attachments/assets/8d22562b-6b43-4fd4-9e86-47f4b79b6e85)
![image](https://github.com/user-attachments/assets/8603280d-cafd-4db3-837b-baf21262b8dc) ![image](https://github.com/user-attachments/assets/2f4e756d-9b23-43ec-8c72-733e41a1d67a)

<br/>

### Data Normalization

En esta etapa vamos a ajustar la disposicion de los datos para facilitar su manipulacion en las siguientes etapas. Iremos tabla por tabla para verificar que cosas pordemos ir mejorando. Primero, vamos a verificar que no existan datos repetidos o casillas vacias en todas las tablas. Para ellos vamos a utilizar el siguienre query en la tabla de "customer journey":

<br/>

```
SELECT
	JourneyID,
	CustomerID,
	ProductID,
	VisitDate,
	Stage,
	Action,
	COALESCE(Duration, avg_duration) AS Duration
FROM
	(
	SELECT
		JourneyID,
		CustomerID,
		ProductID,
		VisitDate,
		UPPER(Stage) AS Stage, 
		Action,
		Duration,
		AVG(Duration) OVER (PARTITION BY VisitDate) AS avg_duration,
		ROW_NUMBER() OVER (
			PARTITION BY CustomerID, ProductID, VisitDate, UPPER(Stage), Action
			ORDER BY JourneyID
		) AS row_num
	FROM
		dbo.customer_journey
	) AS subquery
WHERE
	row_num = 1;
```
<br/>

La columna de "Druration" contiene null spaces. Para rellenar esos espacios con informacion util, vamos a clacular un promedio de los valores que tienen otras casillas en esa misma fecha, y asi reemplazar el espacio vacio con informacion probable. Tambien aplicaremos cierta logica para identificar las filas exactamente iguales (duplicadas) y eliminar una de las dos para mantener solo una copia. Repetiremos estos mismo pasos con todas las tablas para garantizar que no tengan datos repetidos ni espacios nulos. Respecto a las modificaciones especificas de la tabla de "customer journey", aprovechamos para normalizar la columna "stage" con upper case. El resultado luce asi:

<br/>

![image](https://github.com/user-attachments/assets/7314de3f-55f3-4816-8fd2-766250a2466c)


La tabla de "customer reviews" presenta dobles espacios para la columna de "ReviewText", vamos a aplicar un query que elimine los espacios adicionales: 


<br/>

```
SELECT * FROM dbo.customer_reviews

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
```

<br/>

Ahora los campos de texto lucen mucho mejor. Esto tambien sera util mas adelante para facilitar su interpretacion mediante python.

<br/>

![image](https://github.com/user-attachments/assets/8b0339a0-5fd9-4342-ba9b-6fc538a07379)
![image](https://github.com/user-attachments/assets/103c9b3e-c97b-4472-b757-d8241c2444af)

<br/>

Para la tabla de "engagement data" fue necesario separar una columna (ViewsClicksCombined) en dos para categorizar correctamente la informacion. Tambien cambiamos el formato de la columna "ContentType" para que sea mayuscula sostenida. 

<br/>

```
SELECT
	EngagementID,
	ContentID,
	CampaignID,
	ProductID,
	UPPER(REPLACE(ContentType, 'SocialMedia', 'Social Media')) AS ContentType,
	LEFT(ViewsClicksCombined, CHARINDEX('-', ViewsClicksCombined) - 1) AS Views,
	RIGHT(ViewsClicksCombined, LEN(ViewsClicksCombined) - CHARINDEX('-', ViewsClicksCombined)) AS Clicks, 
	Likes,
	FORMAT(CONVERT(DATE, EngagementDate), 'dd.MM.yyyy') AS EngagementDate
-- INTO dbo.fixed_engagement_data
FROM
	dbo.engagement_data
```
<br/>

El resultado puede compararse con su version original en las siguientes imagenes:

<br/>

![image](https://github.com/user-attachments/assets/c8001197-11dc-4699-8b3d-d6cc4a32a581)

![image](https://github.com/user-attachments/assets/a2cb4704-1d58-4a70-8749-19893b330f9f)

<br/>

Las tablas de "customer" y "geography" contienen informacion referente a los datos de los clientes. Podemos combinarlas para presentar la informacion de forma mas coherente y resumida mediante este query:

<br/>

```
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
```



![image](https://github.com/user-attachments/assets/9e1e0b66-9541-4205-8c45-7daac2291826)

<br/>

Finalmente, en la tabla de "prices" vamos a organizar los productos segun su valor para obtener una visualizacion mas facil de interpretar mediante el siguiente query:

<br/>

```
SELECT
	ProductID,
	ProductName,
	Price,

	CASE
		WHEN Price < 50 THEN 'Low'
		WHEN Price BETWEEN 50 AND 200 THEN 'Medium'
		ELSE 'High'
	END AS PriceCategory
--INTO dbo.fixed_products
FROM
	dbo.products
```

<br/>

de este modo cada producto tiene una interpretacion

<br/>

![image](https://github.com/user-attachments/assets/11a86674-9d85-44cf-abee-be3e75e64c4a)

<br/>

# Python

