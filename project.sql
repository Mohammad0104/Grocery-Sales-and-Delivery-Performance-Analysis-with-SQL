-- What does the sales data look like?
-- Show the first 20 orders, sorted by order date from oldest to newest
use loblaw;
select *from loblaw
order by `Order Date` asc limit 20
;
-- Which orders have strong sales and low discounts?
--  Find orders with sales above 2,000, a discount below 15%, and positive profit. Sort by sales descending.

use loblaw;
select order_id,Sales,Discount
from loblaw
where Sales >=2000 and Discount <0.15
order by Sales desc;

-- How is the business performing overall?
-- Calculate total sales, total profit, distinct order count, average order value, and profit margin percentage.
-- Display: Total sales, total profit, total orders, average order value, and profit margin %.

use loblaw;

select 
Category,
sum(sales) as total_sales,
round(sum(profit),2) as total_profit,
count(distinct order_id ) as number_of_order,
round((sum(sales)/count(distinct order_id ) ) ,2)as average_order_value,
round((sum(sales)/sum(profit)),2) * 100 as profit_margin
from loblaw
group by Category;

-- Which categories and subcategories drive business performance?
-- Calculate sales, profit, order count, and profit margin for each category and subcategory combination. Sort by total profit descending.

use loblaw;

select 
Category, `Sub Category`,
sum(sales) as total_sales,
round(sum(profit),2) as total_profit,
count(distinct order_id ) as number_of_order,
round((sum(sales)/count(distinct order_id ) ) ,2)as average_order_value,
round((sum(sales)/sum(profit)),2) * 100 as profit_margin
from loblaw
group by Category, `Sub Category`;

-- Which cities generate significant sales?
-- Find cities with total sales above 500,000 and at least 300 distinct orders.
-- Display: City, total sales, total profit, and order count.

use loblaw;

select 
city,
sum(sales) as total_sales,
round(sum(profit),2) as total_profit,
count(distinct order_id ) as number_of_order

from loblaw
group by City
having sum(sales) > 500000 and count(distinct order_id ) >=300
;

-- How does business performance change each month?
-- Calculate monthly sales, profit, and order counts for each year. Identify the year and month with the highest sales.

use loblaw;

with date_convert as(

select 
sales,profit,order_id,
STR_TO_DATE(`Order Date`, '%m/%d/%Y') as order_date

from loblaw
)
select 
sum(sales) as total_sales,
round(sum(profit),2) as total_profit,
count(distinct order_id ) as order_count,

month(order_date) as order_month,

year(order_date) as order_year

from date_convert
WHERE order_date IS NOT NULL
group by month(order_date),year(order_date)

order by order_month and order_year desc limit 1
;




-- What happened during the latest 30 days in the dataset?
-- Using the latest order date as the reference, calculate daily sales and distinct order counts for that date and the previous 29 days. Return only days with sales.
-- Display: Order date, daily sales, and order count.

use loblaw;

with new_date as (
select
Sales, order_id ,
STR_TO_DATE(`Order Date`, '%m/%d/%Y') as order_date
from loblaw

)
select 
sum(sales) as daily_sales,
count(distinct order_id ) as daily_order,
order_date
from new_date
WHERE  order_date between 
(select 
date_sub(max(order_date), interval 29 day) from new_date) and 
(select max(order_date) from new_date)
group by order_date 
order by order_date 
;
-- How do shipping methods compare?
-- Use an INNER JOIN to combine sales and shipping records. 
-- For each shipping method, calculate matched order count, total sales, recorded profit, total shipping cost, and average shipping cost.
-- Display: Shipping method, order count, total sales, total profit, total

use loblaw;
use loblaw1;
select 
s2.shipping_method,
sum(sales) as total_sales,
round(sum(s1.profit),2) as total_profit,
count(distinct s1.order_id ) as number_of_order,
sum(s2.shipping_cost) as total_shipping_cost,
avg(s2.shipping_cost) as total_shipping_cost
from loblaw.loblaw as s1
inner join loblaw1.loblaw1 as s2

on s1.order_id = s2.order_id
group by s2.shipping_method;


-- Which sales orders have no shipping records?
-- Use a LEFT JOIN to find orders without matching shipping details. Then summarize their order count and sales value by region.
-- Display: Order ID, order date, region, and sales; followed by a regional summary.

use loblaw1;
select 
s2.order_id,
s2.ship_date,
s1.Region,
sum(sales) as total_sales,
count(distinct s1.order_id ) as number_of_order

from loblaw.loblaw as s1
left join loblaw1.loblaw1 as s2

on s1.order_id = s2.order_id
where s2.order_id is NULL
group by s2.order_id,
s2.ship_date,
s1.Region;


-- Are deliveries meeting their expected dates?
-- Use CASE WHEN to classify matched orders as Early, On Time, or Late, based on delivery date compared with expected delivery date. Count orders in each group.
-- Display: Delivery status and order count.

USE loblaw1;

WITH delivery AS (
    SELECT
        DATEDIFF(delivery_date, expected_delivery_date) AS day_difference,
        COUNT(DISTINCT order_id) AS number_of_order
    FROM loblaw1
    GROUP BY DATEDIFF(delivery_date, expected_delivery_date)
)
SELECT
    number_of_order,
    day_difference,
    CASE
        WHEN day_difference > 0 THEN 'late'
        WHEN day_difference < 0 THEN 'early'
        WHEN day_difference = 0 THEN 'same'
        ELSE 'unknown'
    END AS delivery_status
FROM delivery;

-- Which shipping methods have the most delivery problems?
-- For each shipping method, calculate matched order count, late order count, late-delivery percentage, and average days between order date and delivery date.
-- Display: Shipping method, total orders, late orders, late-delivery %, and average delivery days.

Use loblaw1;

with delivey_info as (
select shipping_method,order_id,
datediff(delivery_date,order_date) as delivery_days,
case
	when delivery_date > expected_delivery_date then 1
    else 0
end as late_delivery
from loblaw1)

select 
shipping_method,
count(order_id) as total_orders,

round(((sum(late_delivery)/count(order_id)) *100),2) as late_delivery_percentage,
round(avg(delivery_days),2) as avg_delivery_day
from delivey_info
group by shipping_method

;


-- Which late deliveries had above-average sales?
-- Join the sales and shipping tables using order ID.
-- Find orders delivered after their expected delivery date whose sales were greater than the average sales across all orders in the sales table, calculated using a subquery. 
-- Sort by sales descending.
-- Display: Order ID, customer name, sales, shipping method, expected delivery date, and actual delivery date.

use loblaw;
use loblaw1;

select
s1.order_id, s1.`Customer Name`, sum(s1.sales) as total_sales, s2.shipping_method,s2.expected_delivery_date,s2.ship_date

from loblaw.loblaw as s1

inner join loblaw1.loblaw1 as s2

on s1.order_id = s2.order_id
where s2.delivery_date >s2.expected_delivery_date
group by s1.order_id, 
s1.`Customer Name`,
s2.shipping_method,
s2.expected_delivery_date,
s2.ship_date

having sum(s1.sales) > (
select avg(order_sales)
	from( select
			s3.order_id,
            sum(s3.sales) as order_sales
            
            from loblaw.loblaw as s3

inner join loblaw1.loblaw1 as s4

on s3.order_id = s4.order_id
group by s3.order_id) as order_totals
)
order by total_sales asc
;

-- Which early deliveries had below-average sales?
-- Join the sales and shipping tables using order ID. 
-- Find orders delivered before their expected delivery date whose total sales were less than the average order total across all orders in the sales table, calculated using a subquery.
-- Sort by total sales ascending.
-- Display: Order ID, customer name, total sales, shipping method, expected delivery date, and actual delivery date.

SELECT
    s1.order_id,
    s1.`Customer Name`,
    SUM(s1.Sales) AS total_sales,
    s2.shipping_method,
    s2.expected_delivery_date,
    s2.delivery_date
FROM loblaw.loblaw AS s1
INNER JOIN loblaw1.loblaw1 AS s2
    ON s1.order_id = s2.order_id

WHERE s2.delivery_date < s2.expected_delivery_date

GROUP BY
    s1.order_id,
    s1.`Customer Name`,
    s2.shipping_method,
    s2.expected_delivery_date,
    s2.delivery_date

HAVING SUM(s1.Sales) < (
    SELECT AVG(order_total)
    FROM (
        SELECT
            s3.order_id,
            SUM(s3.Sales) AS order_total
        FROM loblaw.loblaw AS s3
        GROUP BY s3.order_id
    ) AS total_sales_order
)

ORDER BY total_sales ASC
LIMIT 0, 1000;


-- Find each customer’s most recent order. If dates tie, choose the highest order_id. Return one order per customer.
-- Display: Customer name, order ID, order date, and sales.

use loblaw;
with rank_order as (
select `Customer Name`,order_id,
 STR_TO_DATE(`Order Date`, '%m/%d/%Y') AS order_date,
 sales,
 row_number() over(
 
 partition by `Customer Name`
 order by STR_TO_DATE(`Order Date`, '%m/%d/%Y') desc,
 order_id desc
 
 
 
 
 )as rn
from loblaw
)
select `Customer Name`,order_id,order_date, sales
from rank_order
where rn = 1;

-- Rank customers by total sales from highest to lowest. 
-- Equal totals should receive the same rank, 
-- with gaps after ties.
-- Display: Customer name, total sales, and sales rank.

use loblaw;
select `Customer name`, sum(sales) as total_sales,
rank () over (
order by sum(sales) desc
)as sales_rank
from loblaw
group by `Customer name`
order by sales_rank;


-- Find all orders with the third-highest distinct total sales 
-- amount across the sales table.
-- Display: Order ID, total sales, and sales rank
use loblaw;

with rank_orders as ( select 
order_id, sum(sales) as total_sales,
dense_rank() over (
	order by sum(sales)desc

)as rank_order
from loblaw
group by order_id
)
select
order_id,rank_order,total_sales from rank_orders

order by order_id, ;