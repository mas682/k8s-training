from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return f'Hello, Dockerized Flask App! {os.environ.get("TEST_SECRET", "NOT FOUND")} {os.environ.get("LITERAL_SECRET", "NOT FOUND")}'

@app.route('/health')
def health_check():
    # Perform any health check logic here
    # For simplicity, just return a JSON response indicating the application is healthy
    
    return jsonify(status='ok', message='Health check passed')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')