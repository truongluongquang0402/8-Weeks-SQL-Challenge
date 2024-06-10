use week2


--- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
with cte as
(
select *,
       DENSE_RANK() over(order by DATEADD(
                                            DAY,
                                            floor(DATEDIFF(DAY, '2021-01-01', registration_date)) / 7 * 7,
                                                     '2021-01-01'
                                         )
                        ) as registration_week
from runners
)
select registration_week, 
       count(runner_id) as registered_runner_count
from cte
group by registration_week

/*
- In the first week, two runners registered. The next two weeks each have one runner.
*/

;
--- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
-- assuming the pickup time and the prep time is the same (both equal to the difference between pickup time and order time)
with cte AS
(
select distinct
    r.order_id,
    r.runner_id, 
    r.pickup_time, 
    c.order_time, 
    datediff(MINUTE, c.order_time, r.pickup_time) pickup_minutes
from runner_orders_cleaned r
    inner join customer_orders_cleaned c 
        on r.order_id = c.order_id
where distance != 0
)
select runner_id, 
       AVG(pickup_minutes) as average_pickup_minutes
from cte
    group by runner_id
;

--- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
-- assuming the pickup time and the prep time is the same (both equal to the difference between pickup time and order time)

with cte AS
(
select r.order_id, 
       r.pickup_time, 
       c.order_time, 
       datediff(MINUTE, c.order_time, r.pickup_time) prep_minutes, 
       count(c.order_id) as pizza_count
from runner_orders_cleaned r
    inner join customer_orders_cleaned c 
        on r.order_id = c.order_id
where distance != 0
group by r.order_id, 
         r.pickup_time,
         c.order_time
)
select pizza_count, 
       AVG(prep_minutes) as average_prep_minutes
from cte
group by pizza_count
/*
- Orders with 1 pizza took an average of 12 minutes prep time. (12min/pizza)
- Orders with 2 pizza took an average of 18 minutes prep time. (9min/pizza)
- Orders with 3 pizza took an average of 30 minutes prep time. (10min/pizza)
*/
;

--- 4. What was the average distance travelled for each customer?

select c.customer_id, 
       round(avg(r.distance), 2) as average_distance
from customer_orders_cleaned c
    inner join runner_orders_cleaned r 
        on c.order_id = r.order_id
where r.distance != 0
group by customer_id
;

--- 5. What was the difference between the longest and shortest delivery times for all orders?

select max(duration) - min(duration) as difference_delivery_time
from runner_orders_cleaned
where duration != 0
;
-- the difference between the longest and shortest delivery times is 30 minutes

--- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
-- average speed equals to distance divided by time(hour)
select runner_id, 
       order_id, 
       distance, 
       round(duration/60,2) as duration_hour, 
       round(distance/(duration/60),2) as average_speed_kmh
from runner_orders_cleaned
where duration != 0
order by runner_id
/*
- the highest average speed of any runner was that of runner 2 when delivering order_id 8 with 93.6 km/h, the lowest was that of runner 2 when delivering order_id 4 with 35.1 km/h. This runner has the highest fluctuation among 3 runners.
- the average speed of runner 1 fluctuates between 37.5 km/h and 60 km/h
- the average speed of runner 3 is 40 km/h
*/


--- 7. What is the successful delivery percentage for each runner?
select runner_id,
       sum(
            case
                when distance != 0 then
                    1
                else
                    0 
            END
           ) * 100.0/count(*) as success_pct
from runner_orders_cleaned
group by runner_id
/*
- runner 1 has 100% success rate
- runner 2 has 75% success rate
- runner 3 has 50% success rate
however, this does not accurately represent the performance of each runner as the cancellation reason is out of the runner's control.
*/

select * from customer_orders_cleaned
select * from runner_orders_cleaned
--select * from customer_orders
select * from pizza_names
select * from pizza_recipes
select * from pizza_toppings
--select * from runner_orders 
select * from runners