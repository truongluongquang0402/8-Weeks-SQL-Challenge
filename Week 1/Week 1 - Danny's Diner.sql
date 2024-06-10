--- drop DATABASE if exists week1;
--- create database week1;
use week1;
/*
drop table if exists sales;
drop table if exists menu;
drop table if exists sales;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
*/
/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
select s.customer_id, 
       sum(m2.price) as total_spent
from sales s
  inner join menu m2 on 
    s.product_id = m2.product_id
group by s.customer_id
;
-- 2. How many days has each customer visited the restaurant?
select customer_id, 
       count(distinct order_date) as total_days_visited
from sales
group by customer_id 
;
-- 3. What was the first item from the menu purchased by each customer?
with cte AS
(
select sales.customer_id, 
       sales.product_id, 
       ROW_NUMBER() over(partition by sales.customer_id order by order_date asc) as row_num
from sales
)
select customer_id, 
       menu.product_name
from cte
  inner join menu on 
    cte.product_id = menu.product_id
where row_num = 1

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select top 1 sales.product_id, 
             product_name, 
             count(*) total_orders
from sales
  inner join menu on 
    sales.product_id = menu.product_id
group by sales.product_id, 
         product_name
order by total_orders DESC
;
-- 5. Which item was the most popular for each customer?

with cte as
(
select customer_id, 
       product_id, 
       count(*) as total_orders, 
       DENSE_RANK() over(partition by customer_id order by count(*) desc) as ranked
from sales
group by customer_id, 
         product_id
)
select customer_id, 
       cte.product_id, 
       product_name, 
       total_orders
from cte
  inner join menu on 
    cte.[product_id] = menu.product_id
where ranked = 1
;
-- 6. Which item was purchased first by the customer after they became a member?

with cte AS
(
select sales.customer_id, 
       sales.product_id, 
       ROW_NUMBER() over(partition by sales.customer_id order by order_date asc) as row_num
from sales
  inner join members on 
    sales.customer_id = members.customer_id
where order_date >= join_date
)
select cte.customer_id, 
       product_name
from cte
  inner join menu on 
    cte.product_id = menu.product_id
where row_num = 1
;
-- 7. Which item was purchased just before the customer became a member?
with cte AS
(
select sales.customer_id, 
       sales.product_id, 
       ROW_NUMBER() over(partition by sales.customer_id order by order_date desc) as row_num
from sales
  inner join members on 
    sales.customer_id = members.customer_id
where order_date < join_date
)
select cte.customer_id, 
       product_name
from cte
  inner join menu on 
    cte.product_id = menu.product_id
where row_num = 1
;
-- 8. What is the total items and amount spent for each member before they became a member?

select sales.customer_id, 
       sum(price) as total_spent
from sales
  inner join members on 
    sales.customer_id = members.customer_id
  inner join menu on
    sales.product_id = menu.[product_id]
where order_date < join_date
group by sales.customer_id
;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with cte AS
(
select product_id,
       case when product_id = 1 then
        price * 2 * 10 
       else 
        price * 10 
       END as points
from menu
)
select customer_id, 
       sum(points) as total_points
from cte
  inner join sales on 
    cte.product_id = sales.product_id
group by customer_id
;
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
with cte as
(
select s.customer_id, 
       s.order_date, 
       s.product_id,
       case when order_date between join_date and dateadd(day, 7, join_date) then
        1 
       else 
        0 
       end as within_first_week
from sales s
  left JOIN members m1 on 
    s.customer_id = m1.customer_id
)
select cte.customer_id,
       sum(case when within_first_week = 0 THEN
            (case when cte.product_id = 1 then 
              price * 2 * 10 
             else 
              price * 10 
             end)
           else 
            price * 2 * 10 
           end) as total_points
from menu
  inner join cte on 
    menu.product_id = cte.product_id
group by customer_id
;

--- Bonus Question #1: Create a table with a column that indicates if the purchase made when the customer was a customer or not ---
with cte AS
(
select sales.customer_id, 
       sales.product_id, 
       sales.order_date, 
       members.join_date
from sales
  left join members on 
    sales.customer_id = members.customer_id
)
select cte.customer_id, 
       cte.order_date, 
       m2.product_name, 
       m2.price,
       case when cte.order_date >= cte.join_date then 
        'Y' 
       else 
        'N' 
       END as member
from cte
  inner join menu m2 on
    cte.product_id = m2.product_id
;
--- Bonus Question #2: Adding a column to the previous table that rank the order date of members ---

with temp as
(
select cte.customer_id, 
       cte.order_date, 
       m2.product_name, 
       m2.price,
       case when cte.order_date >= cte.join_date then 
        'Y' 
       else 
        'N' 
       END as member
from (
      select sales.customer_id, 
             sales.product_id, 
             sales.order_date, 
             members.join_date
      from sales
        left join members on 
          sales.customer_id = members.customer_id
     ) as cte
  inner join menu m2 on
    cte.product_id = m2.product_id
)
select *,
      case when member = 'Y' then 
        rank() over(partition by customer_id order by case when member ='N' then 1 else 0 end, order_date asc)
      else 
        null 
      end as ranking
from temp
order by customer_id, 
         order_date
;


select * from members
select * from menu
select * from sales