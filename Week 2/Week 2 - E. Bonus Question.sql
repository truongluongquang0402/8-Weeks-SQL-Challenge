use week2

/* Bonus Question:
If Danny wants to expand his range of pizzas - how would this impact the existing data design?
Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
*/

delete from pizza_recipes where pizza_id = 3
delete from pizza_names where pizza_id = 3
;
insert into pizza_names
VALUES
(3, 'Supreme')
;
with cte as
(
select distinct cast(value as int) as topping_id
from pizza_recipes
cross apply string_split(toppings, ',')
)
insert into pizza_recipes
VALUES
(3, (select string_agg(topping_id, ', ') from cte))
;
select r.pizza_id, n.pizza_name, r.toppings
from pizza_recipes r
inner join pizza_names n on r.pizza_id = n.pizza_id
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