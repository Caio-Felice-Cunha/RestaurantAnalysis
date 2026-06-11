# Restaurant Analysis
Analyzing Danny's Diner data with SQL ([Case Study Questions.sql](https://github.com/Caio-Felice-Cunha/RestaurantAnalysis/blob/main/Case%20Study%20Questions.sql))

<img align="center" src=https://user-images.githubusercontent.com/111542025/230171030-1e71c560-e7f9-47c9-80e9-039d8e927d05.png>

## This is the 2nd Version

## Introduction
Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.<br>
Danny's Diner is in need of your assistance to help the restaurant stay afloat. The restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.

## Business Problem
> Data source: the data was provided by Danny on his [website](https://8weeksqlchallenge.com/case-study-1/)

Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they've spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.<br>
He plans on using these insights to help him decide whether he should expand the existing customer loyalty program. Additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.

## Data
Three tables, captured over the first months of 2021:
* `sales` (customer_id, order_date, product_id): every order placed.
* `menu` (product_id, product_name, price): the 3 items and their prices.
* `members` (customer_id, join_date): when each customer joined the loyalty program.

The full schema and seed rows are in [`schema.sql`](schema.sql), reproduced from the published challenge so the repo runs standalone.

## How to run
The queries are written for MySQL. To run them as published:

```sql
-- in a MySQL client
SOURCE schema.sql;                 -- create tables and load the data
SOURCE "Case Study Questions.sql"; -- run the 10 case study queries
```

You do not need MySQL to confirm the answers. A standard library Python script loads the same data into SQLite, runs every query, and asserts each documented result:

```bash
python verify_answers.py
```

It prints a PASS line per question and exits non-zero if any answer drifts. No third party packages are required.

## Solution Strategy
We used MySQL as the database management system to solve this problem, building up from basic clauses to window functions:
* Step 01: SELECT
* Step 02: WHERE
* Step 03: GROUP BY and ORDER BY
* Step 04: JOINs
* Step 05: Common Table Expressions (CTE) and window functions (DENSE_RANK, RANK)

## Results
All results below come from the queries in this repo, verified against the published dataset by `verify_answers.py`.

| # | Question | Answer |
|---|----------|--------|
| 1 | Total amount each customer spent | A $76, B $74, C $36 |
| 2 | Distinct days each customer visited | A 4, B 6, C 2 |
| 3 | First item purchased per customer | A sushi and curry (tied, both on 2021-01-01), B curry, C ramen |
| 4 | Most purchased item overall | ramen, 8 purchases |
| 5 | Most popular item per customer | A ramen (3x); B curry, sushi and ramen (2x each); C ramen (3x) |
| 6 | First item after joining the program | A curry, B sushi, C is not a member |
| 7 | Item bought just before joining | A sushi or curry, B sushi, C is not a member |
| 8 | Spend and items before joining | A $25 over 2 items, B $40 over 3 items |
| 9 | Loyalty points (sushi earns 2x) | A 860, B 940, C 360 |
| 10 | Points at end of January (first-week 2x bonus) | A 1370, B 820 |

A few things worth calling out for the business:
* Ramen is the single most purchased item (8 orders) and the favourite of customers A and C, so it is the safest item to anchor promotions on.
* Customer B is the most frequent visitor (6 distinct days) but spreads spend evenly across all three items, so B has no single favourite to target.
* For question 10, only orders through January 31 count toward the end of January total. Customer B's February 1 ramen order is excluded, which is why B has 820 points rather than 940.

## Next Steps
* Accepting suggestions.

## Disclaimer
The whole case, including the database and questions, is authored by Danny Ma as part of his [#8WeekSQLChallenge](https://8weeksqlchallenge.com/). This is [Case Study #1, Danny's Diner](https://8weeksqlchallenge.com/case-study-1/). The dataset in `schema.sql` is reproduced from that published challenge and all credit for it belongs to the original author.
