from pathlib import Path

from db import get_connection

RAW = Path("data/raw")

TABLES = [
    ("product_category_name_translation", "product_category_name_translation.csv"),
    ("customers", "olist_customers_dataset.csv"),
    ("sellers", "olist_sellers_dataset.csv"),
    ("products", "olist_products_dataset.csv"),
    ("orders", "olist_orders_dataset.csv"),
    ("order_items", "olist_order_items_dataset.csv"),
    ("order_payments", "olist_order_payments_dataset.csv"),
    ("order_reviews", "olist_order_reviews_dataset.csv"),
    ("geolocation", "olist_geolocation_dataset.csv"),
]


def main():
    with get_connection() as conn, conn.cursor() as cur:
        cur.execute("TRUNCATE " + ", ".join(t for t, _ in TABLES) + " CASCADE")
        for table, file in TABLES:
            with open(RAW / file, encoding="utf-8") as f:
                cur.copy_expert(
                    f"COPY {table} FROM STDIN WITH (FORMAT csv, HEADER true)", f
                )
            cur.execute(f"SELECT COUNT(*) FROM {table}")
            print(f"{table}: {cur.fetchone()[0]}")


if __name__ == "__main__":
    main()