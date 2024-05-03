import psycopg2
import os
import sys
from time import sleep

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


class DataBase:
    def __init__(self, credentials: Credentials):
        self.credentials = credentials
        self.db_connection = None

    
    @classmethod
    def getCredentials(cls) -> Credentials:
        db_user = os.environ.get("POSTGRES_USER")
        db_password = os.environ.get("POSTGRES_PASSWORD")
        database = os.environ.get("POSTGRES_DB")
        db_host = os.environ.get("DB_HOST")
        db_port = os.environ.get("DB_PORT")
        return Credentials(dbname=database, user=db_user, password=db_password, host=db_host, port=db_port)

    
    def connect(self) -> None:
        attempts = 0
        max_attempts = 20
        sleep_time = 5
        while attempts < max_attempts:
            try:
                self.db_connection = psycopg2.connect(
                    dbname=self.credentials.dbname,
                    user=self.credentials.user,
                    password=self.credentials.password,
                    host=self.credentials.host,
                    port=self.credentials.port
                )
                break
            except psycopg2.OperationalError:
                attempts += 1
                print(f"Failed to connect to database. Attempt {attempts}/{max_attempts}...")
                if attempts < max_attempts:
                    print(f"Sleeping for {sleep_time} seconds...")
                    sys.stdout.flush()
                    sleep(sleep_time)
                else:
                    print(f"Failed to connect to database after {max_attempts} attempts.")
                    raise


    def disconnect(self) -> None:
        self.db_connection.close()
    
    def query(self, query: str) -> tuple:
        cursor = self.db_connection.cursor()
        cursor.execute(query)
        result = cursor.fetchall()
        self.db_connection.commit()
        cursor.close()
        return result
    
    def create_or_insert(self, query: str) -> None:
        cursor = self.db_connection.cursor()
        cursor.execute(query)
        self.db_connection.commit()
        cursor.close()

    def check_if_table_exists(self, table_name: str) -> bool:
        return self.query(f"SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = '{table_name}');")