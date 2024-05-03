import sys
from app.utils.database import DataBase

if __name__ == '__main__':
    db = DataBase(DataBase.getCredentials())
    db.connect()
    table_name = 'sample_table'
    result = db.check_if_table_exists(table_name)
    if result:
        print("Table exists")
    else:
        print("Table does not exist, creating table with fake data...")
        db.create_or_insert(f"CREATE TABLE IF NOT EXISTS {table_name} (id SERIAL PRIMARY KEY, name VARCHAR(100), age INT)")
        db.create_or_insert(f"INSERT INTO {table_name} (name, age) VALUES ('John', 30), ('Alice', 25), ('Bob', 35)")
        result = db.check_if_table_exists(table_name)
        if result:
            print("Table created successfully")
        else:
            print("Table could not be found")
    
    db.disconnect()
    sys.stdout.flush()