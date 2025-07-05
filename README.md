# Data-Management-Sketch-

<br/>

<h1>What is this about? 🤓</h1> 

<br/>

The idea is to perform a data study exercise and market analysis according to the data provided by the project managers. Multiple technologies such as <b>SQL</b>, <b>Python</b> and <b>PowerBI</b> will be used.

<h3>Index</h3>


- [Problem Description](#Problem-Description)
- [SQL](#SQL)
- [Python](#python)

# Problem Description

An online retailer is facing a drop in engagement and sales despite launching multiple campaigns to improve their marketing strategy, which is increasing their costs without significant returns. They decided to contact a data analyst to identify opportunities to improve their strategies.

<br/>

Key Points: 
- Reduced Customer Engagement
- Decreased Conversion Rates
- High Marketing Expenses
- Need for Customer Feedback Analysis

<br/>

<h1>SQL</h1>

We were provided with multiple databases with the necessary information to carry out our analysis. Among them: Products, Geography, Engagement Data, Customers, Customer Reviews, Customer Journey. Here is a preview of what each looks like:

![image](https://github.com/user-attachments/assets/9732cb10-c08d-4a67-893e-006ef8c57991) ![image](https://github.com/user-attachments/assets/f6a89ebe-e808-4731-8e85-1c7434d82259) 
![image](https://github.com/user-attachments/assets/91aa59d1-6498-47fe-a7d5-360627b54e5b) ![image](https://github.com/user-attachments/assets/8d22562b-6b43-4fd4-9e86-47f4b79b6e85)
![image](https://github.com/user-attachments/assets/8603280d-cafd-4db3-837b-baf21262b8dc) ![image](https://github.com/user-attachments/assets/2f4e756d-9b23-43ec-8c72-733e41a1d67a)

<br/>

### Data Normalization

In this stage we are going to adjust the data layout to facilitate its manipulation in the following stages. We will go table by table to verify what things we can improve. First, we will verify that there are no repeated data or empty cells in all the tables. For this we will use the following query in the 'customer journey' table:

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

The 'Druration' column contains null spaces. To fill those spaces with useful information, we are going to average the values that other cells have on that same date, and replace the empty space with probable information. We will also apply some logic to identify the exact same rows (duplicates) and delete one of the two to keep only one copy. We will repeat these same steps with all tables to ensure that they have no duplicate data and no null spaces. Regarding the modifications specific to the 'customer journey' table, we take the opportunity to normalize the 'stage' column with upper case. The result looks like this:

<br/>

![image](https://github.com/user-attachments/assets/7314de3f-55f3-4816-8fd2-766250a2466c)

The 'customer reviews' table has double spaces for the 'ReviewText' column, let's apply a query to remove the extra spaces:


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

Now the text fields look much better. This will also be useful later to facilitate their interpretation in python.

<br/>

![image](https://github.com/user-attachments/assets/8b0339a0-5fd9-4342-ba9b-6fc538a07379)
![image](https://github.com/user-attachments/assets/103c9b3e-c97b-4472-b757-d8241c2444af)

<br/>

For the “engagement data” table it was necessary to separate one column (ViewsClicksCombined) in two to correctly categorize the information. We also changed the format of the “ContentType” column to be a sustained capital letter.

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

The result can be compared with the original version in the following images:

<br/>

![image](https://github.com/user-attachments/assets/c8001197-11dc-4699-8b3d-d6cc4a32a581)

![image](https://github.com/user-attachments/assets/a2cb4704-1d58-4a70-8749-19893b330f9f)

<br/>

The “customer” and “geography” tables contain information about customer data. We can combine them to present the information in a more coherent and summarized way using this query:

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

Finally, in the “prices” table we are going to organize the products according to their value in order to obtain a visualization easier to interpret by means of the following query:

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

each product has its own interpretation.

<br/>

![image](https://github.com/user-attachments/assets/11a86674-9d85-44cf-abee-be3e75e64c4a)

<br/>

# Python
Let's install some libraries that we will need to run the script.

<br/>

```
pip install pandas nltk pyodbc
```
<br/>

- pandas (pd): We use pandas to load, process, and manipulate structured data. In this project, it's responsible for handling the review data as a DataFrame, allowing us to apply sentiment analysis row by row, transform columns, and export the final dataset to a clean CSV file for reporting or further analysis.

- pyodbc: pyodbc is used to connect Python to our SQL Server database. It allows us to execute SQL queries and retrieve data directly into a pandas DataFrame. This connection is essential for pulling customer reviews stored in the database before performing sentiment analysis.

- nltk: We use the nltk library, specifically the SentimentIntensityAnalyzer from the VADER tool, to compute sentiment scores for each review. The sentiment score helps classify text into categories like positive, negative, or neutral. We download the required vader_lexicon at runtime to enable this functionality.

<br/>

Lets debrief function by function:

<br/>

## fetch_data_from_sql()
Connects to a local SQL Server (SQLEXPRESS) and retrieves customer review data from the fixed_customer_reviews table in the PortfolioProject_MarketingAnalytics database.
Returns the results as a pandas.DataFrame.

<br/>

## calculate_sentiment(review)
Uses NLTK’s SentimentIntensityAnalyzer to compute a sentiment score for the given review text.
Returns the compound score (a value from -1 to 1).

<br/>

## categorize_sentiment(score, rating)
Maps the compound sentiment score and the star rating into a custom sentiment label:

Positive, Negative, Neutral, Mixed Positive, or Mixed Negative.

Designed to account for alignment or conflict between textual sentiment and numerical rating.

<br/>

## sentiment_bucket(score)
Groups the sentiment score into one of four defined buckets:

'0.5 to 1.0', '0.0 to 4.9', '-0.49 to 0.0', or '-1.0 to -0.5'.

<br/>

In the end, we got a .csv file that looks something like this:

<br/>

![image](https://github.com/user-attachments/assets/064501f0-2d44-4faf-93aa-d904baf497f3)

<br/>



