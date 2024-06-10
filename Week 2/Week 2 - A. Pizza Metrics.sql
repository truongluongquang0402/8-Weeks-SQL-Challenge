use week2


-- 1. How many pizzas were ordered?

select count(*) as pizza_count
from customer_orders_cleaned
;
-- 2. How many unique customer orders were made?

select count(distinct order_id) as unique_order_count
from customer_orders_cleaned
;
-- 3. How many successful orders were delivered by each runner?

select runner_id, 
       count(order_id) as successful_order_count
from runner_orders_cleaned
where cancellation not like '% Cancellation'
group by runner_id
;

-- 4. How many of each type of pizza was delivered?
select pizza_name, 
       count(*) as order_count
from customer_orders_cleaned c
    inner join pizza_names n 
        on c.pizza_id = n.pizza_id
group by pizza_name
;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
select customer_id,
       sum(
           case
               when pizza_id = 1 then
                   1
               else
                   0
            end
           ) as meatlovers_count,
       sum(
           case
               when pizza_id = 2 then
                   1
               else 
                   0
               end
           ) as vegetarian_count
from customer_orders
group by customer_id 
;

-- 6. What was the maximum number of pizzas delivered in a single order?
with cte AS
(
select order_id, 
       count(*) as total_pizza_count,
       rank() over(order by count(*) DESC) as ranked
from customer_orders_cleaned
group by order_id
)
select order_id, 
       total_pizza_count
from cte
where ranked = 1
;
-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
select customer_id,
       sum(
           case when exclusions != '' or extras != '' then
               1
           else
               0
           end
          ) as changed_pizza_count,
       sum(
           case when exclusions = '' and extras = '' then 
               1 
           else 
               0
           end
          ) as unchanged_pizza_count
from customer_orders_cleaned
group by customer_id
;

-- 8. How many pizzas were delivered that had both exclusions and extras?
select sum(
           case when exclusions != '' and extras != '' then 
               1 
           else 
               0 
           end
          ) as changed_pizza_count
from customer_orders_cleaned
;
-- 9. What was the total volume of pizzas ordered for each hour of the day?
with cte AS
(
select *, 
       datepart(HOUR,order_time) as hour_num
from customer_orders_cleaned
)
select hour_num, 
       count(*) as total_pizza_count
from cte
group by hour_num
;
-- 10. What was the volume of orders for each day of the week?

with cte as
(
select *, 
       DATENAME(weekday, order_time) as week_day
from customer_orders_cleaned
)
select week_day, 
       count(distinct order_id) as order_count
from cte
group by week_day
;
select * from customer_orders_cleaned
select * from runner_orders_cleaned
--select * from customer_orders
select * from pizza_names
select * from pizza_recipes
select * from pizza_toppings
--select * from runner_orders 
select * from runners