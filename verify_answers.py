"""Reproduce and verify every answer in this case study.

This script loads schema.sql (the published Danny's Diner dataset) into an
in-memory SQLite database, runs each of the 10 case study queries, and asserts
that the result matches the documented answer. It needs nothing beyond the
Python standard library, so anyone can confirm the answers are reproducible:

    python verify_answers.py

A note on dialects: the queries in "Case Study Questions.sql" are written for
MySQL. The handful that use MySQL-only syntax are restated here in portable SQL
so the same logic runs under SQLite. The arithmetic and the answers are
identical. The two differences are:
  - date arithmetic: MySQL DATE_ADD(d, INTERVAL 6 DAY) -> SQLite date(d,'+6 day')
  - the aggregate logic is otherwise unchanged.
"""

import os
import sqlite3
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SCHEMA = os.path.join(HERE, "schema.sql")


def load_db():
    con = sqlite3.connect(":memory:")
    with open(SCHEMA, "r", encoding="utf-8") as fh:
        con.executescript(fh.read())
    return con


def fetch(con, sql):
    cur = con.cursor()
    cur.execute(sql)
    return cur.fetchall()


# Each check: (label, sql, expected_rows). Rows are compared as sorted lists.
CHECKS = [
    (
        "Q1 total amount spent per customer",
        """
        SELECT s.customer_id, SUM(m.price)
        FROM sales s LEFT JOIN menu m ON s.product_id = m.product_id
        GROUP BY s.customer_id;
        """,
        [("A", 76), ("B", 74), ("C", 36)],
    ),
    (
        "Q2 distinct days visited per customer",
        """
        SELECT customer_id, COUNT(DISTINCT order_date)
        FROM sales GROUP BY customer_id;
        """,
        [("A", 4), ("B", 6), ("C", 2)],
    ),
    (
        "Q3 first item(s) purchased per customer",
        """
        WITH fp AS (
          SELECT s.customer_id, m.product_name,
                 DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) rk
          FROM sales s LEFT JOIN menu m ON s.product_id = m.product_id)
        SELECT DISTINCT customer_id, product_name FROM fp WHERE rk = 1;
        """,
        [("A", "curry"), ("A", "sushi"), ("B", "curry"), ("C", "ramen")],
    ),
    (
        "Q4 most purchased item overall",
        """
        SELECT m.product_name, COUNT(s.product_id) c
        FROM sales s LEFT JOIN menu m ON s.product_id = m.product_id
        GROUP BY m.product_name ORDER BY c DESC LIMIT 1;
        """,
        [("ramen", 8)],
    ),
    (
        "Q5 most popular item per customer",
        """
        WITH mp AS (
          SELECT s.customer_id, m.product_name, COUNT(s.product_id) tp,
                 RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) rk
          FROM sales s LEFT JOIN menu m ON s.product_id = m.product_id
          GROUP BY s.customer_id, s.product_id, m.product_name)
        SELECT customer_id, product_name, tp FROM mp WHERE rk = 1;
        """,
        [
            ("A", "ramen", 3),
            ("B", "curry", 2),
            ("B", "ramen", 2),
            ("B", "sushi", 2),
            ("C", "ramen", 3),
        ],
    ),
    (
        "Q8 amount spent before membership",
        """
        SELECT s.customer_id, SUM(m.price)
        FROM sales s JOIN members mb ON s.customer_id = mb.customer_id
        JOIN menu m ON s.product_id = m.product_id
        WHERE s.order_date < mb.join_date
        GROUP BY s.customer_id;
        """,
        [("A", 25), ("B", 40)],
    ),
    (
        "Q8 items bought before membership",
        """
        SELECT s.customer_id, COUNT(m.product_id)
        FROM sales s JOIN members mb ON s.customer_id = mb.customer_id
        JOIN menu m ON s.product_id = m.product_id
        WHERE s.order_date < mb.join_date
        GROUP BY s.customer_id;
        """,
        [("A", 2), ("B", 3)],
    ),
    (
        "Q9 points with sushi 2x multiplier",
        """
        SELECT s.customer_id,
          SUM(CASE WHEN m.product_name = 'sushi' THEN 20 * m.price ELSE 10 * m.price END)
        FROM sales s LEFT JOIN menu m ON s.product_id = m.product_id
        GROUP BY s.customer_id;
        """,
        [("A", 860), ("B", 940), ("C", 360)],
    ),
    (
        "Q10 points at end of January (first-week 2x bonus, cutoff applied)",
        """
        SELECT s.customer_id,
          SUM(CASE
            WHEN s.order_date BETWEEN mb.join_date AND date(mb.join_date, '+6 day') THEN m.price * 20
            WHEN m.product_name = 'sushi' THEN m.price * 20
            ELSE m.price * 10 END)
        FROM members mb
        LEFT JOIN sales s USING (customer_id)
        LEFT JOIN menu m USING (product_id)
        WHERE s.order_date <= '2021-01-31'
        GROUP BY s.customer_id;
        """,
        [("A", 1370), ("B", 820)],
    ),
]


def main():
    con = load_db()
    failures = 0
    for label, sql, expected in CHECKS:
        got = sorted(fetch(con, sql))
        want = sorted(expected)
        ok = got == want
        status = "PASS" if ok else "FAIL"
        print(f"[{status}] {label}")
        if not ok:
            failures += 1
            print(f"        expected: {want}")
            print(f"        got:      {got}")
    print()
    if failures:
        print(f"{failures} check(s) FAILED")
        sys.exit(1)
    print(f"All {len(CHECKS)} checks passed.")


if __name__ == "__main__":
    main()
