-- The Database has been Created using the Schema.sql Script file and 
-- The Table data is created using the Data.sql Script
-- Using the Database 
USE film_rental;
-- 1.	What is the total revenue generated from all rentals in the database? 
-- 	Selecting aggregate of Amount 
SELECT SUM(amount) AS Total_Revenue 
FROM payment;

-- 2. 	How many rentals were made in each month_name?
-- Selecting Payment Month dates , Counting it by means of grouping it
SELECT MONTHNAME(payment_date) AS Month_name, COUNT(rental_id) AS Monthly_Rental_Count 
FROM payment
GROUP BY Month_name 
ORDER BY Monthly_Rental_Count DESC;


-- 3. 	What is the rental rate of the film with the longest title in the database?
SELECT Rental_Rate, Title, LENGTH(Title) AS Title_Length 
FROM film
GROUP BY Rental_Rate, Title 
ORDER BY Title_Length DESC 
LIMIT 1;


-- 4. 	What is the average rental rate for films that were taken from the last 30 days from the date("2005-05-05 22:04:30")?
SELECT AVG(f.rental_rate) AS Average_rental_rate 
FROM film AS f
JOIN inventory AS inv ON inv.film_id = f.film_id 
JOIN rental AS rent ON rent.inventory_id = inv.inventory_id
JOIN payment AS pay ON pay.rental_id = rent.rental_id 
WHERE rent.rental_date BETWEEN '2005-05-05 22:04:30' AND DATE_ADD('2005-05-05 22:04:30', INTERVAL 30 DAY);


-- 5. What is the most popular category of films in terms of the number of rentals?
-- Count Rentals based on Category Name by Joining all the tables
SELECT c.name AS Category_Name, COUNT(p.rental_id) AS Number_of_Rentals 
FROM Inventory AS i 
JOIN Film AS f ON f.film_id = i.film_id 
JOIN Rental AS r ON r.inventory_id = i.inventory_id
JOIN Film_Category AS fc ON fc.film_id = f.film_id 
JOIN Category AS c ON c.category_id = fc.category_id 
JOIN Payment AS p ON p.rental_id = r.rental_id
GROUP BY Category_Name 
ORDER BY Number_of_Rentals DESC;

-- 6.	Find the longest movie duration from the list of films that have not been rented by any customer
--  	Rented is Null so its not rented and Order by Duration Length idea is to create left join else
-- we lose null values where we have to get it
SELECT f.title AS Movie_Title, f.length AS Movie_Length 
FROM film f 
LEFT JOIN inventory i ON i.film_id = f.film_id 
LEFT JOIN rental r ON r.inventory_id = i.inventory_id 
LEFT JOIN customer c ON c.customer_id = r.customer_id 
WHERE c.customer_id IS NULL 
GROUP BY 1,2 
ORDER BY 2 DESC;


-- 7.	What is the average rental rate for films, broken down by category? (3 Marks)
-- Find Categories and group by it and average it by joining the corresponding table
SELECT c.Name, AVG(f.rental_rate) AS Average_Rental_Rate 
FROM film f
JOIN film_category fc ON fc.film_id = f.film_id 
JOIN category c ON c.category_id = fc.category_id 
GROUP BY 1;


-- 8.	What is the total revenue generated from rentals for each actor in the database?
-- Selecting Actor name group him as it contains duplicates , join tables linking upto payments as it contains 
-- amount and sum it up as Total_revenue.

SELECT CONCAT(a.first_name, ' ', a.last_name) AS Actor_Name, SUM(p.amount) AS Total_Revenue 
FROM actor a 
JOIN film_actor fa ON fa.actor_id = a.actor_id 
JOIN inventory i ON i.film_id = fa.film_id 
JOIN rental r ON r.inventory_id = i.inventory_id 
JOIN payment p ON p.customer_id = r.customer_id 
GROUP BY Actor_Name 
ORDER BY Total_Revenue DESC;


-- 9.Show all the actresses who worked in a film having a "Wrestler" in the description.
-- Actress  means Gender = Female but no Gender Table // Ignoring and considering all Actors
-- selecting Actor and linking the Tables to flim and filtering Description to have 'Wrestler' 
SELECT CONCAT(a.first_name, ' ', a.last_name) AS Name 
FROM film f  
JOIN film_actor fa ON fa.film_id = f.film_id 
JOIN actor a ON a.actor_id = fa.actor_id 
WHERE f.description LIKE '%Wrestler%' 
GROUP BY Name;

-- 10. Which customers have rented the same film more than once?
-- Selecting the Customer names and Counting how many flims they rented and filtering it more than once
-- Removing Null value
SELECT CONCAT(c.first_name, " ", c.last_name) AS cust_name, COUNT(f.film_id) AS Count
FROM customer AS c
JOIN rental AS r ON r.customer_id = c.customer_id
JOIN payment AS p ON p.rental_id = r.rental_id 
JOIN inventory AS i ON i.inventory_id = r.inventory_id 
RIGHT JOIN film AS f ON f.film_id = i.film_id 
WHERE c.first_name IS NOT NULL AND c.last_name IS NOT NULL
GROUP BY cust_name
HAVING Count > 1 
ORDER BY Count DESC ;


-- 11.	How many films in the comedy category have a rental rate higher than the average rental rate?
-- 	Select Flims joining with required tables and filtering Category with 'Comedy' and 
-- filtering rental rate > average rental rate by using a subquery


SELECT COUNT(*) AS Films_with_comedy_category 
FROM film AS f
JOIN film_category AS fc ON fc.film_id = f.film_id 
JOIN category AS c ON c.category_id = fc.category_id 
WHERE c.name = "Comedy" AND f.rental_rate > (SELECT AVG(rental_rate) FROM film);

-- 12.	Which films have been rented the most by customers living in each city? (3 Marks)
-- Selecting Films ,city ,rental count and creating a table 
-- which contains customers and grouping films and city and we use partion or city by row number to 
-- take the value of rental count as more films is rented same number of times in the city 


SELECT Film_name, City_name, Rental_Count 
FROM (
    SELECT f.title AS Film_name, c.city AS City_name, COUNT(cust.customer_id) AS Rental_Count, 
    ROW_NUMBER() OVER(PARTITION BY c.city ORDER BY COUNT(cust.customer_id) DESC) AS Ranks
    FROM film AS f 
    JOIN inventory AS inv ON inv.film_id = f.film_id
    JOIN customer AS cust ON cust.store_id = inv.store_id 
    JOIN address AS a ON a.address_id = cust.address_id 
    JOIN city AS c ON c.city_id = a.city_id 
    GROUP BY f.title, c.city
) AS subquery
WHERE Ranks = 1;


-- 13. 	What is the total amount spent by customers whose rental payments exceed $200?
-- 		Select Name , Amount by joing tables and Grouping it and amount is > 200
SELECT CONCAT(c.first_name, " ", c.last_name) AS customer_name, p.customer_id, SUM(p.amount) AS Total
FROM payment AS p
JOIN customer AS c ON c.customer_id = p.customer_id 
GROUP BY customer_name, p.customer_id
HAVING Total > 200;


-- 14. Display the fields which are having foreign key constraints related to the "rental" table. [Hint: using Information_schema] 
-- 		Using Information Schema key column usage we get name of the column , constaing and refrence table and reference column
-- 		And we give table_name as rentel to filter out and we give constrain as primary key to filter out foreign key links

select column_name,constraint_name,referenced_table_name,referenced_column_name from INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
where table_name = 'rental' and constraint_name <> 'PRIMARY';

-- 15. Create a View for the total revenue generated by each staff member, broken down by store city with the country name. (4 Marks)
-- Selecting Staffmember and their respective Total revenue grouped by Store city and Country Name

CREATE VIEW staff_revenue AS 
SELECT p.staff_id, CONCAT(s.first_name, " ", s.last_name) AS staff_name, c.city, co.country, SUM(p.amount) AS Total_revenue 
FROM payment AS p 
JOIN staff AS s ON s.staff_id = p.staff_id 
JOIN address AS a ON a.address_id = s.address_id 
JOIN city AS c ON c.city_id = a.city_id 
JOIN country AS co ON co.country_id = c.country_id 
GROUP BY p.staff_id, staff_name, c.city;
select * from staff_revenue;

-- 16. Create a view based on rental information consisting of visiting_day, customer_name, 
-- the title of the film, no_of_rental_days, the amount paid by the customer along with the percentage of customer spending. 

-- Selecting the rental date, Day name , Customer name , Film Title , Difference of Rental and return date
--  Amount paid and Percentage of Customer Spending and linking the necessary tables to combine and 
-- Finally making it in a view

CREATE VIEW rental_information AS
SELECT DAY(r.rental_date) AS day, DAYNAME(r.rental_date) AS Dayname, CONCAT(c.first_name, " ", c.last_name) AS Name_of_Customer, f.title AS Film_title,
DATEDIFF(r.return_date, r.rental_date) AS no_of_rental_days, p.amount,
(p.amount / (SELECT SUM(amount) FROM payment WHERE customer_id = c.customer_id)) * 100 AS percentage_customer_spending 
FROM rental AS r
JOIN customer AS c ON c.customer_id = r.customer_id
JOIN inventory AS i ON i.inventory_id = r.inventory_id
JOIN film AS f ON f.film_id = i.film_id
JOIN payment AS p ON p.rental_id = r.rental_id;
SELECT * FROM rental_information;

-- 17. Display the customers who paid 50% of their total rental costs within one day.
-- Selecting the Customers name and Total Amount > 50% of their rental rate , and Date Difference 
-- of payment and rantal date is less or equal to 1 grouping it by customer name

SELECT CONCAT(cust.first_name, " ", cust.last_name) AS cust_name 
FROM customer AS cust 
JOIN rental AS rent ON rent.customer_id = cust.customer_id
JOIN (
    SELECT pay.rental_id, SUM(pay.amount) AS Total_rental_amount 
    FROM payment AS pay 
    GROUP BY pay.rental_id
) AS subquery ON subquery.rental_id = rent.rental_id
JOIN inventory AS inv ON inv.inventory_id = rent.inventory_id
JOIN film AS f ON f.film_id = inv.film_id
JOIN payment AS pay2 ON pay2.rental_id = subquery.rental_id
WHERE (subquery.Total_rental_amount) >= (f.rental_rate)/2 AND DATEDIFF(pay2.payment_date, rent.rental_date) <= 1 
GROUP BY cust_name;

