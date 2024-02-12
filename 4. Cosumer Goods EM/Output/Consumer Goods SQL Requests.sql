use gdb023

show tables

select * from dim_product
select * from dim_customer
select * from fact_gross_price
select * from fact_manufacturing_cost
select * from fact_pre_invoice_deductions
select * from fact_sales_monthly


/*1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.*/


select distinct(market) as market_list from dim_customer 
where region = 'APAC' and customer = 'Atliq Exclusive'


/*2. What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg*/

select
(select count(distinct product_code) 
    from fact_manufacturing_cost where cost_year = 2020) as unique_producs_2020,
(select count(distinct product_code) 
    from fact_manufacturing_cost where cost_year =2021) as unique_products_2021,
((select count(distinct product_code) 
    from fact_manufacturing_cost where cost_year =2021) - 
(select count(distinct product_code) 
    from fact_manufacturing_cost where cost_year =2020)) / 
(select count(distinct product_code) 
    from fact_manufacturing_cost where cost_year =2020) * 100 as percentage_cgh


/*3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count*/
select segment, count(product_code) as product_count from dim_product 
group by segment order by product_count desc


/*4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference */

with product_count as(
select dim_product.segment, 
count(distinct case when fact_manufacturing_cost.cost_year = 2020 
then fact_manufacturing_cost.product_code end) as product_count_2020,
count(distinct case when fact_manufacturing_cost.cost_year = 2021 
then fact_manufacturing_cost.product_code end) as product_count_2021
from dim_product join fact_manufacturing_cost 
on dim_product.product_code = fact_manufacturing_cost.product_code
group by dim_product.segment)
select segment, product_count_2020, product_count_2021, 
product_count_2021 - product_count_2020 as difference
from product_count
order by difference desc


/*5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost */
select dp.product_code, dp.product, fmc.manufacturing_cost
from dim_product dp 
join fact_manufacturing_cost fmc
on dp.product_code = fmc.product_code
where fmc.manufacturing_cost = 
(select max(manufacturing_cost) 
from fact_manufacturing_cost)
or fmc.manufacturing_cost = 
(select min(manufacturing_cost) from fact_manufacturing_cost) 
order by manufacturing_cost desc;

 
 
/*6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage */
select dc.customer_code, dc.customer, 
Round(avg(fpid.pre_invoice_discount_pct)*100,2) 
as average_discount_percentage
from dim_customer dc
join fact_pre_invoice_deductions fpid
on dc.customer_code = fpid.customer_code
where fpid.fiscal_year = 2021 and dc.market = 'India'
group by dc.customer_code,customer
order by average_discount_percentage desc 
limit 5;


/* 7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount*/
select monthname(fsm.date) as Month, Year(fsm.date) as 
Year, Round(sum(fsm.sold_quantity * fgp.gross_price)/1000000,2) 
as Gross_sales_Amount
from fact_sales_monthly fsm
join fact_gross_price fgp
on fsm.product_code = fgp.product_code
join dim_customer on fsm.customer_code = dim_customer.customer_code
where dim_customer.customer = 'Atliq Exclusive'
group by monthname(fsm.date), Year(fsm.date)
order by Year, month(Month) asc;


/* 8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity */
select
case when month(date) in (9,10,11) then 'Q1'
when month(date) in (12,1,2)  then 'Q2'
when month(date) in (3,4,5) then 'Q3'
else 'Q4' end as Quarter,
sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly
where fiscal_year = 2020
group by Quarter
order by total_sold_quantity desc;


/* 9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage
 */
with contribution as (
select dc.channel, round(sum(fsm.sold_quantity * 
fgp.gross_price)/1000000,2) as gross_sales_mln
from fact_sales_monthly fsm
left join fact_gross_price fgp
on fsm.product_code = fgp.product_code and fsm.fiscal_year = fgp.fiscal_year
join dim_customer dc
on fsm.customer_code = dc.customer_code
where fgp.fiscal_year = 2021
group by dc.channel)
select channel,gross_sales_mln, round((gross_sales_mln/
(select sum(gross_sales_mln) from contribution))*100,2) as percentage
from contribution
group by channel
order by percentage desc;


/* 10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these fields,
division
product_code
product
total_sold_quantity
rank_order */
with ranking as (
select dp.division, dp.product_code, dp.product, 
sum(fsm.sold_quantity) as total_sold_quantity,
row_number() over(partition by division 
order by sum(fsm.sold_quantity) desc) as rank_order
from dim_product as dp
join fact_sales_monthly as fsm
on dp.product_code = fsm.product_code
where fiscal_year = 2021
group by dp.division,dp.product_code,dp.product)
select *
from ranking
where rank_order < 4;


show tables