use week2

-- creating a table of pizzas' recipes with topping_id and topping_name split
drop table if exists recipe_topping_split;

SELECT pizza_id, 
       cast([value] as int) as topping_id,
       topping_name
into recipe_topping_split
FROM pizza_recipes r
    CROSS APPLY STRING_SPLIT(toppings, ',')
        inner join pizza_toppings t 
            on cast([value] as int) = t.topping_id
;

--- 1. What are the standard ingredients for each pizza?
select pizza_id, 
       string_agg(topping_name, ', ') as ingredients
from recipe_topping_split
group by pizza_id
order by pizza_id
;


--- 2. What was the most commonly added extra?
with cte as
( 
select cast([value] as int) as topping_id
from customer_orders_cleaned
    cross APPLY string_split(extras, ',')
where extras != ''
)
select top 1 topping_name,
       count(*) as extras_count
from cte
    inner join pizza_toppings pt
        on cte.topping_id = pt.topping_id
group by topping_name
order by extras_count DESC
;
/*
Bacon was the most common extra topping added
*/

--- 3. What was the most common exclusion?

with cte as
( 
select cast([value] as int) as topping_id
from customer_orders_cleaned
    cross APPLY string_split(exclusions, ',')
where exclusions != ''
)
select top 1
       topping_name,
       count(*) as exclusions_count
from cte
    inner join pizza_toppings pt
        on cte.topping_id = pt.topping_id
group by topping_name
order by exclusions_count DESC
;
/*
Cheese was the most commonly excluded topping
*/

--- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

-- adding a new column to the customer_order_cleaned table that indicates the number of pizza in an order: (for question 4)

drop table if exists customer_orders_num
select order_id,
       customer_id,
       pizza_id,
       ROW_NUMBER() over(partition by order_id order by pizza_id) as pizza_num,
       exclusions,
       extras
into customer_orders_num
from customer_orders_cleaned

;
select *
from customer_orders_num
;


-- creating a split table of exclusions from orders

drop table if exists order_exclusions_split;
drop table if exists exclusions_temp;

with cte AS
(
select order_id,
       pizza_id,
       pizza_num,
       cast(value as int) as exclusion_id
from customer_orders_num
    cross apply string_split(exclusions, ',')
where exclusions != ''
)
select order_id,
       pizza_id,
       pizza_num,
       exclusion_id,
       topping_name
into order_exclusions_split
from cte
    inner join pizza_toppings pt
        on cte.exclusion_id = pt.topping_id
group by order_id,
         pizza_id,
         pizza_num,
         exclusion_id,
         topping_name
/*;
select * from order_exclusions_split
*/
;
select c.order_id,
       c.pizza_id,
       c.pizza_num,
       string_agg(exs.topping_name, ', ') as exclusions
into exclusions_temp
from customer_orders_num c
    left join order_exclusions_split exs 
        on c.order_id = exs.order_id
         and c.pizza_id = exs.pizza_id 
         and c.pizza_num = exs.pizza_num
group by c.order_id, 
         c.pizza_id,
         c.pizza_num
;
select *
from exclusions_temp
;
-- creating a split table of extras from orders
drop table if exists order_extras_split;
drop table if exists extras_temp;

with cte AS
(
select order_id,
       pizza_id, 
       pizza_num, 
       cast(value as int) as extra_id
from customer_orders_num
    cross apply string_split(extras, ',')
where extras != ''
)
select order_id, 
       pizza_id, 
       pizza_num, 
       extra_id, 
       topping_name
into order_extras_split
from cte
    inner join pizza_toppings pt 
        on cte.extra_id = pt.topping_id
group by order_id, 
         pizza_id, 
         pizza_num, 
         extra_id, 
         topping_name
;
select * 
from order_extras_split
;
select c.order_id, 
       c.pizza_id, 
       c.pizza_num,
       es.extra_id,
       string_agg(es.topping_name, ', ') as extras
into extras_temp
from customer_orders_num c
    left join order_extras_split es 
        on c.order_id = es.order_id
         and c.pizza_id = es.pizza_id 
         and c.pizza_num = es.pizza_num
group by c.order_id, 
         c.pizza_id, 
         c.pizza_num,
         es.extra_id
;
select * 
from extras_temp
;
-- create table with the order name
with cte AS
(
select c.order_id, 
       c.pizza_id, 
       c.pizza_num, 
       e1.exclusions, 
       e2.extras
from customer_orders_num c
    inner join exclusions_temp e1
        on c.order_id = e1.order_id
         and c.pizza_id = e1.pizza_id 
         and c.pizza_num = e1.pizza_num
    inner join extras_temp e2 
        on c.order_id = e2.order_id
         and c.pizza_id = e2.pizza_id 
         and c.pizza_num = e2.pizza_num
)
select c.*,
       case when exclusions is null and extras is null then
               pn.pizza_name
            when exclusions is not null and extras is null then
               concat(pn.pizza_name, ' - ', 'Exclude ', exclusions)
            when exclusions is null and extras is not null then
               concat(pn.pizza_name, ' - ', 'Extra ', extras)
            else
               concat(pn.pizza_name, ' - ', 'Exclude ', exclusions, ' - ', 'Extra ', extras)
            end as order_name
from cte c
    inner join pizza_names pn
        on c.pizza_id = pn.pizza_id

;
--- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

with cte1 as 
(
select 
    c.order_id, 
    c.pizza_id, 
    c.pizza_num, 
    r.topping_name, 
    count(*) AS topping_total
from customer_orders_num c
    left join recipe_topping_split r 
        on c.pizza_id = r.pizza_id
group by c.order_id, 
         c.pizza_id, 
         c.pizza_num, 
         r.topping_name
),
cte2 AS 
(
select 
    order_id, 
    pizza_id, 
    pizza_num, 
    topping_name, 
    count(*) AS extras_total
from order_extras_split
group by order_id, 
         pizza_id, 
         pizza_num, 
         topping_name
),
cte3 AS 
(
select 
    cte1.order_id, 
    cte1.pizza_id, 
    cte1.pizza_num, 
    cte1.topping_name, 
    cte1.topping_total, 
    coalesce(cte2.extras_total, 0) AS extras_total
from cte1
    left join cte2 on
        cte1.order_id = cte2.order_id AND 
        cte1.pizza_id = cte2.pizza_id AND 
        cte1.pizza_num = cte2.pizza_num AND 
        cte1.topping_name = cte2.topping_name
),
cte4 AS 
(
select
    order_id, 
    pizza_id, 
    pizza_num, 
    topping_name, 
    topping_total + extras_total as topping_count,
    case when topping_total + extras_total = 1 then 
        topping_name
    else
        concat(topping_total + extras_total, 'x', topping_name)
    end as topping_count_name
from cte3
)
select
    cte4.order_id, 
    cte4.pizza_id, 
    cte4.pizza_num,
    concat(n.pizza_name, ' - ', string_agg(cte4.topping_count_name, ', ')) as ingredient_list
from cte4
    inner join pizza_names n 
        on cte4.pizza_id = n.pizza_id
group by cte4.order_id, 
         cte4.pizza_id, 
         cte4.pizza_num, 
         n.pizza_name
order by cte4.order_id, 
         cte4.pizza_id, 
         cte4.pizza_num;


--- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
with cte1 as 
(
select 
    c.order_id, 
    c.pizza_id, 
    c.pizza_num, 
    r.topping_name, 
    count(*) AS topping_total
from customer_orders_num c
    left join recipe_topping_split r 
        on c.pizza_id = r.pizza_id
group by c.order_id, 
         c.pizza_id, 
         c.pizza_num, 
         r.topping_name
),
cte2 AS 
(
select 
    order_id, 
    pizza_id, 
    pizza_num, 
    topping_name, 
    count(*) AS extras_total
from order_extras_split
group by order_id, 
         pizza_id, 
         pizza_num, 
         topping_name
),
cte3 AS 
(
select 
    cte1.order_id, 
    cte1.pizza_id, 
    cte1.pizza_num, 
    cte1.topping_name, 
    cte1.topping_total, 
    coalesce(cte2.extras_total, 0) AS extras_total
from cte1
    left join cte2 on
        cte1.order_id = cte2.order_id AND 
        cte1.pizza_id = cte2.pizza_id AND 
        cte1.pizza_num = cte2.pizza_num AND 
        cte1.topping_name = cte2.topping_name
),
cte4 as
(
select *, 
       topping_total + extras_total as topping_count
from cte3
)
select topping_name, sum(topping_count) as frequency
from cte4
group by topping_name
order by sum(topping_count) DESC

;

/*
select * 
from customer_orders_cleaned
select * 
from runner_orders_cleaned
--select * from customer_orders



select * from pizza_names
select * from pizza_recipes
select * from pizza_toppings


--select * from runner_orders 

select * from runners

;
select * from order_extras_split
select * from order_exclusions_split
*/
