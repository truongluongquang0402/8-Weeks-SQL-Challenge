use week2

--- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
with cte as
(
select order_id, 
       customer_id, 
       pizza_id, 
       pizza_num,
       case when pizza_id = 1 then
            12
       else
            10
       end as price
from customer_orders_num 
)
select runner_id, 
       concat('$',sum(price)) as earnings
from runner_orders_cleaned r
        inner join cte c 
                on r.order_id = c.order_id
where cancellation not like '%Cancellation'
group by runner_id
;
--- 2. What if there was an additional $1 charge for any pizza extras? Add cheese is $1 extra
with cte as
(
select order_id, 
       customer_id, 
       pizza_id, 
       pizza_num,
       case when pizza_id = 1 then
            12
       else
            10
       end as price,
       len(replace(extras, ', ', '')) as extras_fee
from customer_orders_num 
)
select runner_id, 
       concat('$',sum(price + extras_fee)) as earnings
from runner_orders_cleaned r
        inner join cte c 
                on r.order_id = c.order_id
where cancellation not like '%Cancellation'
group by runner_id
;
--- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset
-- - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

drop table if exists runner_ratings
create table runner_ratings(
        order_id INTEGER,
        rating INTEGER,
        review NVARCHAR(MAX)
)

insert into runner_ratings 
VALUES
        (1, 4, 'a bit cold, but expected as the distance is far'),
        (2, 4, null),
        (3, 5, 'speedy delivery'),
        (4, 2, 'pizza is cold'),
        (5, 5, null),
        (7, 4, 'fast delivery but the pizzas were messed up a bit'),
        (8, 5, 'faster than my previous order'),
        (10, 5, 'OK')
;
select * 
from runner_ratings

;
/* 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
        customer_id
        order_id
        runner_id
        rating
        order_time
        pickup_time
        Time between order and pickup
        Delivery duration
        Average speed
        Total number of pizzas
*/
with cte1 as
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
),
cte2 as
(
select runner_id, 
       order_id, 
       distance, 
       round(duration/60,2) as duration_hour, 
       round(distance/(duration/60),2) as average_speed_kmh
from runner_orders_cleaned
where duration != 0
),
cte3 as
(
select order_id, 
       customer_id,  
       count(*) as pizza_count
from customer_orders_cleaned
group by order_id,
         customer_id
)
select cte3.customer_id, 
       r1.order_id, 
       r1.runner_id, 
       r2.rating, 
       coalesce(r2.review, '') as review,
       cte1.order_time, 
       cte1.pickup_time, 
       cte1.pickup_minutes, 
       r1.duration, 
       r1.distance, 
       cte2.average_speed_kmh, 
       cte3.pizza_count
from runner_orders_cleaned r1
        left join runner_ratings r2 ON
                r1.order_id = r2.order_id
        left join cte1 ON
                r1.order_id = cte1.order_id AND
                r1.runner_id = cte1.runner_id
        left join cte2 ON
                r1.order_id = cte2.order_id AND
                r1.runner_id = cte2.runner_id
        left join cte3 ON
                r1.order_id = cte3.order_id
where r1.cancellation not like '%Cancellation'
order by r1.order_id ASC
;


--- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

with 
cte1 as
(
select order_id, 
       customer_id, 
       pizza_id, 
       pizza_num,
       case when pizza_id = 1 then
            12
       else
            10
       end as price
from customer_orders_num 
),
cte2 as
(
select order_id, 
       sum(cte1.price) as gross_revenue
from cte1
group by order_id
),
cte3 as
(
select order_id, 
       runner_id, 
       distance * 0.3 AS runner_pay
from runner_orders_cleaned
where cancellation not like '%Cancellation'
),
cte4 as
(
select cte2.order_id,  
       gross_revenue - runner_pay as net_revenue
from cte2
        inner join cte3 ON
                cte2.order_id = cte3.order_id
)
select round(sum(net_revenue), 2) as total_revenue
from cte4
;



select * from customer_orders_cleaned
select * from runner_orders_cleaned
--select * from customer_orders
select * from pizza_names
select * from pizza_recipes
select * from pizza_toppings
--select * from runner_orders 
select * from runners

select * from customer_orders_num