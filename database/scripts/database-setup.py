import psycopg2
from psycopg2 import sql
import os

class Credentials:
    def __init__(self, dbname: str, user: str, password: str, host: str, port: str):
        """
        Initializes a new instance of the Credentials class.

        Args:
            dbname (str): The name of the database.
            user (str): The username for authentication.
            password (str): The password for authentication.
            host (str): The host address of the database.
            port (str): The port number for the database connection.
        """
        self.dbname = dbname
        self.user = user
        self.password = password
        self.host = host
        self.port = port

def getCredentials() -> Credentials:
    db_user = os.environ.get("POSTGRES_USER")
    db_password = os.environ.get("POSTGRES_PASSWORD")
    database = os.environ.get("POSTGRES_DB")
    return Credentials(dbname=database, user=db_user, password=db_password, host="localhost", port="5432")

def connect(credentials: Credentials) -> psycopg2.extensions.connection:
    conn = psycopg2.connect(
        dbname=credentials.dbname,
        user=credentials.user,
        password=credentials.password,
        host=credentials.host,
        port=credentials.port
    )
    return conn

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
    credentials = getCredentials()
    print(credentials.dbname)
    print(credentials.user)
    print(credentials.password)
    db_connection = connect(credentials)
    db_connection.cursor().execute("SELECT * FROM sample_table")
    print(db_connection.cursor().fetchall())