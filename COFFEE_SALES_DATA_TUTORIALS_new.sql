create database coffee_db;
use coffee_db;
create table coffee_sales(
transaction_id int,
transaction_date DATE,	
transaction_time TIME,	
transaction_qty INT,	
store_id INT,	
store_location VARCHAR(50),
product_id INT,
unit_price INT,	
product_category VARCHAR(100),
product_type VARCHAR(100),	
product_detail VARCHAR(100)
)
SELECT * FROM coffee_sales;
alter table coffee_sales
modify unit_price DOUBLE;
DESCRIBE coffee_sales;

load data infile 'Coffee Shop Sales.csv' into table coffee_sales
fields terminated by ','
ignore 1 lines;

select * from coffee_sales;
-- eg sales for month of march
select concat((round(sum(unit_price*transaction_qty)))/1000, 'K') AS total_sales
from coffee_sales
where month(transaction_date) = 3;

-- TOTAL SALES KPI - MOM DIFFERENCE AND MOM GROWTH current month - may (5) , previous month - april (4)

select 
	month(transaction_date) as month, -- to get month no
    round(sum(unit_price*transaction_qty)) as total_sales, -- sales
    (sum(unit_price*transaction_qty) - lag(sum(unit_price*transaction_qty), 1) -- saLES DIFFERENCE
	over(order by month(transaction_date))) / lag(sum(unit_price*transaction_qty), 1) -- division
    over(order by month(transaction_date)) * 100 as mom_percentage_increase -- percentage
from coffee_sales
where month(transaction_date) in (4,5) -- for months of april and may
group by month(transaction_date)
order by month(transaction_date);

-- total orders for month of may
select count(transaction_id) as total_orders
from coffee_sales
where month(transaction_date) = 5;

-- mom decrease/increase in no of orders
select 
	month(transaction_date) as month,
    round(count(transaction_id)) as total_orders,
    (round(count(transaction_id)) - lag(count(transaction_id), 1)
    over(order by month(transaction_date)))/ lag(count(transaction_id),1)
    over(order by month(transaction_date)) * 100 as mom_percent_order_increase
from coffee_sales
where month(transaction_date) in (4,5)
group by month(transaction_date)
order by month(transaction_date);
    
-- total quantity sold
select sum(transaction_qty) as total_orders
from coffee_sales
where month(transaction_date) = 5;
-- mom increase/decrease in total quantity sold

SELECT 
    MONTH(transaction_date) AS month,
    ROUND(SUM(transaction_qty)) AS total_quantity_sold,
    (SUM(transaction_qty) - LAG(SUM(transaction_qty), 1) 
    OVER (ORDER BY MONTH(transaction_date))) / LAG(SUM(transaction_qty), 1) 
    OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage
FROM 
    coffee_sales
WHERE 
    MONTH(transaction_date) IN (4, 5)   -- for April and May
GROUP BY 
    MONTH(transaction_date)
ORDER BY 
    MONTH(transaction_date);

--  CALENDAR TABLE – DAILY SALES, QUANTITY and TOTAL ORDERS
select 
concat(round(sum(unit_price * transaction_qty)/1000,1) , 'K') as total_sales,
CONCAT(ROUND(sum(transaction_qty)/1000,1) , 'K') as total_qty,
CONCAT(count(transaction_id), 'K') as total_orders
from coffee_sales
where transaction_date = '2023-05-18';

-- WEEKDAYS = MON-FRI & WEEKENDS = SAT -SUN
-- IN SQL SUN =1 MON =2 SAT =7
-- sales on weekdays and weekends

select 
	case when dayofweek(transaction_date) in (1,7) then 'weekends'
    else 'weekdays'
    end as day_type,
    concat(round(sum(unit_price * transaction_qty)/1000,1), 'K')
FROM coffee_sales
WHERE month(transaction_date) = 5
group by 
case when dayofweek(transaction_date) in (1,7) then 'weekends'
else 'weekdays'
end

-- sales by store location

select 
store_location,
sum(unit_price* transaction_qty) as total_sales
from coffee_sales
where month(transaction_date) = 5
group by store_location
order by total_sales desc;

-- avg sales
select avg(total_sales) as avg_sales
from (
select sum(unit_price * transaction_qty) as total_sales
from coffee_sales
where month(transaction_date) = 5
group by transaction_date
)as internal_query;

-- daily sales
select day(transaction_date),
sum(unit_price*transaction_qty) as daily_sales
from coffee_sales
where month(transaction_date) = 5
group by day(transaction_date);

-- COMPARING DAILY SALES WITH AVERAGE SALES – IF GREATER THAN “ABOVE AVERAGE” and LESSER THAN “BELOW AVERAGE”
SELECT 
    day_of_month,
    CASE 
        WHEN total_sales > avg_sales THEN 'Above Average'
        WHEN total_sales < avg_sales THEN 'Below Average'
        ELSE 'Average'
    END AS sales_status,
    total_sales
FROM (
    SELECT 
        DAY(transaction_date) AS day_of_month,
        SUM(unit_price * transaction_qty) AS total_sales,
        AVG(SUM(unit_price * transaction_qty)) OVER () AS avg_sales
    FROM 
        coffee_sales
    WHERE 
        MONTH(transaction_date) = 5  -- Filter for May
    GROUP BY 
        DAY(transaction_date)
) AS sales_data
ORDER BY 
    day_of_month;
    
-- SALES BY PRODUCT CATEGORY
SELECT 
	product_category,
	ROUND(SUM(unit_price * transaction_qty),1) as Total_Sales
FROM coffee_sales
WHERE
	MONTH(transaction_date) = 5 
GROUP BY product_category
ORDER BY SUM(unit_price * transaction_qty) DESC

-- SALES BY PRODUCTS (TOP 10)
SELECT 
	product_type,
	ROUND(SUM(unit_price * transaction_qty),1) as Total_Sales
FROM coffee_sales
WHERE
	MONTH(transaction_date) = 5 
GROUP BY product_type
ORDER BY SUM(unit_price * transaction_qty) DESC
LIMIT 10

-- sales by day and hour

select 
	sum(unit_price* transaction_qty) as total_sales,
    sum(transaction_qty) as total_qty,
    count(transaction_id) as total_orders
from coffee_sales
where month(transaction_date) = 5
and DAYOFWEEK(transaction_date) = 2
and hour(transaction_time)= 8

-- TO GET SALES FROM MONDAY TO SUNDAY FOR MONTH OF MAY

SELECT 
	CASE
    WHEN DAYOFWEEK(transaction_date)=2 THEN 'MONDAY'
    WHEN DAYOFWEEK(transaction_date)=3 THEN 'Tuesday'
    WHEN DAYOFWEEK(transaction_date)=4 then 'WEDNESDAY'
    WHEN DAYOFWEEK(transaction_date)=5 THEN 'THURSDAY'
    WHEN DAYOFWEEK(transaction_date)=6 THEN 'FRIDAY'
    WHEN DAYOFWEEK(transaction_date)=7 THEN 'SATURDAY'
    ELSE 'SUNDAY'
    END AS DAY_OF_WEEK,
    SUM(unit_price*transaction_qty) as total_sales
from coffee_sales
where month(transaction_date) = 5
group by 
	CASE
    WHEN DAYOFWEEK(transaction_date)=2 THEN 'MONDAY'
    WHEN DAYOFWEEK(transaction_date)=3 THEN 'Tuesday'
    WHEN DAYOFWEEK(transaction_date)=4 then 'WEDNESDAY'
    WHEN DAYOFWEEK(transaction_date)=5 THEN 'THURSDAY'
    WHEN DAYOFWEEK(transaction_date)=6 THEN 'FRIDAY'
    WHEN DAYOFWEEK(transaction_date)=7 THEN 'SATURDAY'
    ELSE 'SUNDAY'
    end;
    








