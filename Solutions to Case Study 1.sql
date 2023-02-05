/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

--1. total amount each customer spent at the restaurant--
select s.customer_id,
       sum(m.price)
from   sales s
join   menu m
on     s.product_id = m.product_id
group by s.customer_id

--2. number of days each customer has visited the restaurant--
select   customer_id, 
         count(distinct(order_date)) number_of_days_visited
from     sales
group by customer_id

--3. first item in the menu order by each customer--
with CTE as
(select s.customer_id,
        k.product_name,
		s.order_date,
        dense_rank()over(partition by s.customer_id order by s.order_date) rn
from sales s
join menu k
on   s.product_id = k.product_id
group by s.customer_id, k.product_name, s.order_date)
select customer_id, product_name
from CTE
where rn = 1

--4.most purchased item and number of times it was purchases--
select top 1 m.product_name, count(s.product_id)
from   menu m
join   sales s
on     s.product_id = m.product_id
group by m.product_name
order by count(s.product_id) desc

--5. item that was most popular--
select top 1 m.product_name
from   menu m
join   sales s
on     s.product_id = m.product_id
group by s.customer_id, m.product_name
order by count(s.product_id) desc

--6. which item was purchased by the customer after they became a member?--
with CTE as
(select s.customer_id,
        m.product_name,
        dense_rank() over (partition by s.customer_id order by s.order_date) rn
 from   menu m
 join   sales s
 on     s.product_id = m.product_id
 join   members k
 on     k.customer_id = s.customer_id
 where  s.order_date >= k.join_date)
 select customer_id, product_name
 from   CTE
 where  rn = 1

--7. which item was purchased by the customer just before they became a member?--
with CTE as
(select s.customer_id,
        m.product_name,
        dense_rank() over (partition by s.customer_id order by s.order_date) rn
 from   menu m
 join   sales s
 on     s.product_id = m.product_id
 join   members k
 on     k.customer_id = s.customer_id
 where  s.order_date < k.join_date)
 select customer_id,product_name
 from   CTE
 where  rn = 1

 --8. what is the total items and amount spent for each member before they became a member?--
 select s.customer_id,
        count(s.product_id) total_items,
        sum(m.price) total_amount
 from   sales s
 join   menu m
 on     s.product_id = m.product_id
 join   members k
 on     s.customer_id = k.customer_id
 where  s.order_date < k.join_date
 group by s.customer_id

 -- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

with Points as
(
select *, case when product_id = 1 then price*20
               else price*10
	       end as Points
from menu
)
select S.customer_id, sum(P.points) as Points
from sales S
join Points p
on p.product_id = S.product_id
group by S.customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

with dates as
(
   select *, 
      dateadd(day, 6, join_date) as valid_date, 
      eomonth('2021-01-31') as last_date
   from members 
)
select S.customer_id, 
       sum(
	   case 
	  when m.product_ID = 1 then m.price*20
	  when S.order_date between D.join_date and D.valid_date then m.price*20
	  end 
	  ) as Points
from dates D
join sales S
on D.customer_id = S.customer_id
join menu M
on M.product_id = S.product_id
where S.order_date < d.last_date
group by S.customer_id