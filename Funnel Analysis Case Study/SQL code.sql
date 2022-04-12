-- issues with the dataset
-- some customers are missing sign up source 
-- based on the criteria defined for success, terms of service sign up date should be before the first purchase date, the column date_diff mesure the difference in days and success is based on if days < or equal to 30 
-- How is terms of service tracked for non compliance ? we will need to exclude values where this is null 
-- future recommendation would be to create an additional column that measures when terms of service was violated and date of violation


--Check for duplicates in the primary key (customer_id) column
select customer_id, count(*)
from customers
group by customer_id
having count(*) > 1

--Check for char length consistency in customer_state 
select customer_state, LEN(customer_state) as len
from [dbo].[customers]
where LEN(customer_state) <> 2

-- Checking for invalid entries in the referrable_id column
select referrable_id 
from customers
where signup_source = 'referral_partner' and referrable_id != 'NULL' and referrable_id NOT BETWEEN 1 AND 8


-- Creating new columns to count the difference in days from one step to the next
-- Also a column to state if the transition was a success or not
select *
from 
(Select customer_id, customer_name, signup_date, signup_source, referrable_id, customer_state,
customer_type, tier, tos_accepted_date, first_purchase_date, DATEDIFF(day, signup_date, tos_accepted_date) as signup_diff,
DATEDIFF(day, tos_accepted_date, first_purchase_date) as diffbetweentos_purchase,

case 
	when DATEDIFF(day, tos_accepted_date, first_purchase_date) <= 30 and DATEDIFF(day, signup_date, tos_accepted_date) <= 7   then 'Y'
	else 'N'
end as Success_measure
from
(select customer_id, customer_name, 
TRY_CAST(signup_date as date) as signup_date, 
signup_source, referrable_id,
customer_state,customer_type ,tier,
TRY_CAST(tos_accepted_date as date) as tos_accepted_date,
TRY_CAST(first_purchase_date as date) as first_purchase_date
from customers)a
					)b
where tos_accepted_date is not null 

-- Successful onboardings for january (can be replicated for april(signup_month = 4), july and september)
select count(customer_id) as Success_count
from
(select customer_id, customer_name, signup_date, signup_source, referrable_id, customer_state,
customer_type, tier, tos_accepted_date, first_purchase_date, diffbetweentos_purchase, signup_diff, success_measure, month(signup_date) as signup_month
from 
(Select customer_id, customer_name, signup_date, signup_source, referrable_id, customer_state,
customer_type, tier, tos_accepted_date, first_purchase_date, DATEDIFF(day, tos_accepted_date, first_purchase_date) as diffbetweentos_purchase,
DATEDIFF(day, signup_date, tos_accepted_date) as signup_diff,
case 
	when DATEDIFF(day, tos_accepted_date, first_purchase_date) <= 30 and DATEDIFF(day, signup_date, tos_accepted_date) <= 7   then 'Y'
	else 'N'
end as Success_measure
from
(select customer_id, customer_name, 
TRY_CAST(signup_date as date)
as signup_date, signup_source, referrable_id,
customer_state,customer_type ,tier,
TRY_CAST(tos_accepted_date as date)
as tos_accepted_date,
TRY_CAST(first_purchase_date as date)
as first_purchase_date
from customers)a)b
where tos_accepted_date is not null)c
where signup_month = 9 and success_measure = 'Y' --(can be replicated for april(signup_month = 4), july and september)

--Success measure for each stage in isolation, from a monthly POV
--Initial signup stage
select count(customer_id)
from customers
where signup_date is not null and signup_date like '2020-01-%';

--ToS and first purchase
select count(customer_id) as Success_count
from
(select customer_id, customer_name, signup_date, signup_source, referrable_id, customer_state,
customer_type, tier, tos_accepted_date, first_purchase_date, diffbetweentos_purchase, signup_diff, 
success_measure, 
month(signup_date) as signup_month
from 
(Select customer_id, customer_name, signup_date, signup_source, referrable_id, customer_state,
customer_type, tier, tos_accepted_date, first_purchase_date, DATEDIFF(day, tos_accepted_date, first_purchase_date) as diffbetweentos_purchase,
DATEDIFF(day, signup_date, tos_accepted_date) as signup_diff,
case 
when DATEDIFF(day, signup_date, tos_accepted_date) <= 7    then 'Y' 
else 'N' end as Success_measure 
-- substitute the DATEDIFF condition in the case-when above with " DATEDIFF(day, tos_accepted_date, first_purchase_date) <= 30 " to measure success of first purchase
from
(select customer_id, customer_name, 
TRY_CAST(signup_date as date)
as signup_date, signup_source, referrable_id,
customer_state,customer_type ,tier,
TRY_CAST(tos_accepted_date as date)
as tos_accepted_date,
TRY_CAST(first_purchase_date as date)
as first_purchase_date
from customers)a)b
where tos_accepted_date is not null)c
where signup_month = 9 and success_measure = 'Y' --MONTHLY FILTER


-- average time it takes for customers to move from each step 
select avg(diffbetweentos_purchase) as avg_tos_to_purchase, avg(signup_diff) as avg_signup_to_tos
from
(Select customer_id, customer_name, signup_date, signup_source, referrable_id, customer_state,
customer_type, tier, tos_accepted_date, first_purchase_date, DATEDIFF(day, tos_accepted_date, first_purchase_date) as diffbetweentos_purchase,
DATEDIFF(day, signup_date, tos_accepted_date) as signup_diff,
case 
	when DATEDIFF(day, tos_accepted_date, first_purchase_date) <= 30 and DATEDIFF(day, signup_date, tos_accepted_date) <= 7   then 'Y'
	else 'N'
end as Success_measure
from
(select customer_id, customer_name, 
TRY_CAST(signup_date as date)
as signup_date, signup_source, referrable_id,
customer_state,customer_type ,tier,
TRY_CAST(tos_accepted_date as date)
as tos_accepted_date,
TRY_CAST(first_purchase_date as date)
as first_purchase_date
from customers)a)b
where tos_accepted_date is not null  and Success_measure='Y';


-- average time for referred individuals (partner referrals and customer referrals)
select avg(diffbetweentos_purchase) as avg_tos_to_purchase, avg(signup_diff) as avg_signup_to_tos
from
(Select customer_id, customer_name, signup_date, signup_source, referrable_id, customer_state,
customer_type, tier, tos_accepted_date, first_purchase_date, DATEDIFF(day, tos_accepted_date, first_purchase_date) as diffbetweentos_purchase,
DATEDIFF(day, signup_date, tos_accepted_date) as signup_diff,
case 
	when DATEDIFF(day, tos_accepted_date, first_purchase_date) <= 30 and DATEDIFF(day, signup_date, tos_accepted_date) <= 7   then 'Y'
	else 'N'
end as Success_measure
from
(select customer_id, customer_name, 
TRY_CAST(signup_date as date)
as signup_date, signup_source, referrable_id,
customer_state,customer_type ,tier,
TRY_CAST(tos_accepted_date as date)
as tos_accepted_date,
TRY_CAST(first_purchase_date as date)
as first_purchase_date
from customers)a)b
where tos_accepted_date is not null and Success_measure ='Y' and signup_source = 'referral_partner' OR signup_source = 'customer_referral' 

select *
from customers 
where signup_source = 'NULL'

