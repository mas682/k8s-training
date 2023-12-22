from flask import Flask, jsonify
import os
import threading
import time

app = Flask(__name__)

# Flag to indicate whether the health check should fail
health_check_failed = True

def simulate_health_check():
    global health_check_failed
    while True:
        time.sleep(60)  # Simulate a delay of 1 minute
        health_check_failed = not health_check_failed

# Start the health check failure simulation in a separate thread
thread = threading.Thread(target=simulate_health_check)
thread.start()

@app.route('/')
def hello():
    return f'Hello, Dockerized Flask App! {os.environ.get("TEST_SECRET", "NOT FOUND")} {os.environ.get("LITERAL_SECRET", "NOT FOUND")}'

@app.route('/health')
def health_check():
    global health_check_failed

    # Check if the health check has failed
    if health_check_failed:
        return jsonify(status='error', message='Health check failed after 1 minute')

    # For simplicity, just return a JSON response indicating the application is healthy
    return jsonify(status='ok', message='Health check passed')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
