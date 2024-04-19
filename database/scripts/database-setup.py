import psycopg2
from psycopg2 import sql
import os

def initdb():
    db_user = os.environ.get("POSTGRES_USER")
    db_password = os.environ.get("POSTGRES_PASSWORD")
    database = os.environ.get("POSTGRES_DB")
    print(f"db_user: {db_user}")
    print(f"db_password: {db_password}")
    print(f"database: {database}")

def setupdb():
    # Connect to your PostgreSQL database
    conn = psycopg2.connect(
        dbname="",
        user="",
        password="",
        host="",
        port=""
    )

    # Create a cursor object using the cursor() method
    cursor = conn.cursor()

    # Create a table
    create_table_query = """
    CREATE TABLE IF NOT EXISTS sample_table (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100),
        age INT
    )
    """
    cursor.execute(create_table_query)
    print("Table created successfully")

    # Sample data to insert into the table
    sample_data = [
        ('John', 30),
        ('Alice', 25),
        ('Bob', 35)
    ]

    # Insert sample data into the table
    insert_query = sql.SQL("INSERT INTO sample_table (name, age) VALUES (%s, %s)")

    for data in sample_data:
        cursor.execute(insert_query, data)

    # Commit changes
    conn.commit()
    print("Sample data inserted successfully")

    # Close the cursor and connection
    cursor.close()
    conn.close()

if __name__ == '__main__':
    initdb()