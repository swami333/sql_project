-- Ad-Hoc Request #1 --
SELECT DISTINCT(market)
FROM dim_customer
WHERE customer="Atliq Exclusive"
AND region="APAC";

-- Ad-Hoc Request #2 --
with cte1 as(
	SELECT 
			fiscal_year,
			COUNT(DISTINCT s.product_code) as unique_products_2020
	FROM fact_sales_monthly s
	JOIN dim_product p
	ON p.product_code = s.product_code
	WHERE fiscal_year= 2020
    GROUP BY fiscal_year
),
cte2 as(
	SELECT 
			fiscal_year,
			COUNT(DISTINCT s.product_code) as unique_products_2021
	FROM fact_sales_monthly s
	JOIN dim_product p
	ON p.product_code = s.product_code
	WHERE fiscal_year= 2021
    GROUP BY fiscal_year
)
SELECT 
		unique_products_2020,
        unique_products_2021,
        ROUND((unique_products_2021-unique_products_2020)/unique_products_2020*100, 2) as percentage_chg
FROM cte1
CROSS JOIN cte2;


-- Ad-Hoc Request #3 --
SELECT
		DISTINCT segment,
        COUNT(product) as product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count desc;


-- Ad-Hoc Request #4 --
with cte1 as (
	SELECT 
			segment,
			COUNT(DISTINCT s.product_code) as product_count_2020
	FROM fact_sales_monthly s
	JOIN dim_product p
	ON p.product_code = s.product_code
	WHERE fiscal_year= 2020
	GROUP BY segment
),
cte2 as (
	SELECT 
			segment,
			COUNT(DISTINCT s.product_code) as product_count_2021
	FROM fact_sales_monthly s
	JOIN dim_product p
	ON p.product_code = s.product_code
	WHERE fiscal_year= 2021
	GROUP BY segment
)
SELECT 
		*,
		(product_count_2021-product_count_2020) as difference
FROM cte1
JOIN cte2
USING (segment)
ORDER BY difference DESC;


-- Ad-Hoc Request #5 --

SELECT 
		product_code,
        product,
        manufacturing_cost
FROM dim_product
JOIN fact_manufacturing_cost
USING (product_code)
WHERE manufacturing_cost= (
		SELECT MAX(manufacturing_cost) from fact_manufacturing_cost
)
    
UNION

SELECT 
		product_code,
        product,
        manufacturing_cost
FROM dim_product
JOIN fact_manufacturing_cost
USING (product_code)
WHERE manufacturing_cost= (
		SELECT MIN(manufacturing_cost) from fact_manufacturing_cost
);


-- Ad-Hoc Request #6 --
SELECT 
		DISTINCT(customer_code),
        customer,
        ROUND(AVG(pre_invoice_discount_pct),2)*100 as avg_discount_pct
FROM dim_customer c
JOIN fact_pre_invoice_deductions p
USING (customer_code)
WHERE fiscal_year= 2021
AND market= "India"
GROUP BY customer_code, customer
ORDER BY avg_discount_pct desc
LIMIT 5;


-- Ad-Hoc Request #7 --

SELECT 
		MONTHNAME(s.date) as Month,
        s.fiscal_year,
        CONCAT(ROUND(SUM((g.gross_price*s.sold_quantity)/1000000),2),"M") as gross_sales_amount
FROM fact_sales_monthly s
JOIN fact_gross_price g
ON s.product_code = g.product_code
AND s.fiscal_year = g.fiscal_year
JOIN dim_customer c
ON s.customer_code = c.customer_code
WHERE customer= "Atliq Exclusive"
GROUP BY Month, fiscal_year
ORDER BY fiscal_year;

-- Ad-Hoc Request #8 --

with cte1 as (
	SELECT 
			MONTH(date) as Month,
			case
				when MONTH(date) in (9,10,11) then "Q1"
				when MONTH(date) in (12,1,2) then "Q2"
				when MONTH(date) in (3,4,5) then "Q3"
				when MONTH(date) in (6,7,8) then "Q4"		
			end as quarter,
			sold_quantity
	FROM fact_sales_monthly s
	where fiscal_year= 2020
),
cte2 as (
	SELECT 
			quarter,
            ROUND(SUM(sold_quantity)/1000000,2) as total_sold_quantity
	FROM cte1
    GROUP BY quarter
)

SELECT * FROM cte2
ORDER BY total_sold_quantity DESC;


-- Ad-Hoc Request #9 --

with cte1 as (
	SELECT 
			c.channel,
			SUM(g.gross_price * s.sold_quantity) as gross_sales_mln
	FROM fact_sales_monthly s
	JOIN fact_gross_price g
	ON s.product_code = g.product_code
	JOIN dim_customer c
	ON s.customer_code = c.customer_code
    WHERE s.fiscal_year= 2021
	GROUP BY channel
    ORDER BY gross_sales_mln DESC
)
SELECT
		channel,
        CONCAT(ROUND(gross_sales_mln/1000000,2),"M") as gross_sales_mln,
        CONCAT(ROUND((gross_sales_mln/SUM(gross_sales_mln) OVER()) *100, 2), "%") as percentage
FROM cte1;


-- Ad-Hoc Request #10 --

with cte1 as (
	SELECT
			p.division,
			p.product_code,
			p.product,
			SUM(s.sold_quantity) as sold_quantity,
            RANK() OVER(PARTITION BY division ORDER BY SUM(s.sold_quantity) DESC) as rank_order
	FROM fact_sales_monthly s
	JOIN dim_product p
	USING (product_code)
    WHERE s.fiscal_year= 2021
    GROUP BY p.division, p.product_code, p.product
)

SELECT *
FROM cte1
WHERE rank_order <=3
ORDER BY division, rank_order;