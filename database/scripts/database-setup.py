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
    db_host = os.environ.get("DB_HOST")
    db_port = os.environ.get("DB_PORT")
    return Credentials(dbname=database, user=db_user, password=db_password, host=db_host, port=db_port)

class DataBase:
    def __init__(self, credentials: Credentials):
        self.credentials = credentials
        self.db_connection = None

    
    def getCredentials() -> Credentials:
        db_user = os.environ.get("POSTGRES_USER")
        db_password = os.environ.get("POSTGRES_PASSWORD")
        database = os.environ.get("POSTGRES_DB")
        db_host = os.environ.get("DB_HOST")
        db_port = os.environ.get("DB_PORT")
        return Credentials(dbname=database, user=db_user, password=db_password, host=db_host, port=db_port)

    
    def connect(self) -> None:
        self.db_connection = psycopg2.connect(
            dbname=self.credentials.dbname,
            user=self.credentials.user,
            password=self.credentials.password,
            host=self.credentials.host,
            port=self.credentials.port
        )

    def disconnect(self) -> None:
        self.db_connection.close()
    
    def query(self, query: str) -> list:
        cursor = self.db_connection.cursor()
        cursor.execute(query)
        result = cursor.fetchall()
        self.db_connection.commit()
        cursor.close()
        return result

    def check_if_table_exists(self, table_name: str) -> bool:
        return self.query(f"SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = '{table_name}');")

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
    db = DataBase(DataBase.getCredentials())
    db.connect()
    result = db.check_if_table_exists('sample_table')
    if result:
        print("Table exists")
    elif not result:
        print("Table does not exist")
    else:
        print("Something went wrong")
    
    db.disconnect()