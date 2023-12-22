from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return f'Hello, Dockerized Flask App! {os.environ.get("TEST_SECRET", "NOT FOUND")} {os.environ.get("LITERAL_SECRET", "NOT FOUND")}'

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')