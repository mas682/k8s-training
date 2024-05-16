from flask import Flask, jsonify, abort
import os
import threading
import time
import socket
import logging
import requests

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Flag to indicate whether the health check should fail
health_check_failed = True
app_ready = False
readiness_failures = 0


def get_local_ip():
    try:
        # Create a socket to get the local IP address
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('8.8.8.8', 80))  # Connect to a known external server
        local_ip = s.getsockname()[0]
        s.close()
        return local_ip
    except Exception as e:
        logger.error(f"Error getting local IP address: {e}")
        return "UNKNOWN"


def simulate_health_check():
    global health_check_failed

    # Number of times health check flipped
    flip_count = 1
    time.sleep(30)
    # set to ready for startUp probe
    health_check_failed = not health_check_failed
    while True:
        # incrementing time so that livenessProbe fails eventually
        sleep_time = 15 * flip_count
        logger.info(f"Health check flipped.  Failed: {health_check_failed}")
        logger.info(f"Sleep time: {sleep_time}")
        time.sleep(sleep_time)  # Simulate a delay
        health_check_failed = not health_check_failed
        flip_count += 1

# Start the health check failure simulation in a separate thread
fail_health_check = bool(os.environ.get("FAIL_HEALTHCHECK", "False") == "True")
logger.info(f"Fail health check: {fail_health_check}")
if not fail_health_check:
    health_check_failed = False
else:
    thread = threading.Thread(target=simulate_health_check)
    thread.start()

@app.route('/')
def base():
    global app_ready
    if not app_ready:
        return jsonify(error='Application not ready'), 500
    ip = get_local_ip()
    pod_name = socket.gethostname()
    return jsonify(
        ip=ip,
        pod_name=pod_name
    )


@app.route('/health')
def health_check():
    # For simplicity, just return a JSON response indicating the application is healthy
    global readiness_failures
    if readiness_failures > 30:
        return jsonify(status='error', message='Readiness check failed too many times'), 500
    return jsonify(status='ok', message='Health check passed')


@app.route('/readiness')
def readiness_check():
    global app_ready
    global readiness_failures
    backend_host = os.environ.get("BACKEND_INTERNAL_SERVICE_HOST", "NOT FOUND")
    backend_port = os.environ.get("BACKEND_INTERNAL_SERVICE_PORT", "NOT FOUND")
    url = f"http://{backend_host}:{backend_port}/"

    try:
        response = requests.get(url, timeout=5)

        if response.status_code == 200:
            app_ready = True
            readiness_failures = 0
            return jsonify(status='ok', message='Readiness check passed')
        else:
            app_ready = False
            readiness_failures += 1
            return jsonify(status='error', message=f'Readiness check failed. Backend responded with a {response.status_code} status'), 500

    except requests.exceptions.RequestException as e:
        app_ready = False
        readiness_failures += 1
        return jsonify(status='error', message=f"Readiness check failed. Error connecting to backend: {str(e)}"), 500


@app.route('/test_backend_connection')
def test_backend_connection():
    global app_ready
    if not app_ready:
        return jsonify(error='Application not ready'), 500

    # using the _SERVICE_HOST environment variable is one option
    # one drawback to this is the service must be created first
    # if you use backend-internal.default instead, the dns lookup makes it so the service 
    # does not need to be created first
    
    backend_host = os.environ.get("BACKEND_INTERNAL_SERVICE_HOST", "NOT FOUND")
    backend_port = os.environ.get("BACKEND_INTERNAL_SERVICE_PORT", "NOT FOUND")
    url = f"http://{backend_host}:{backend_port}/"

    try:
        response = requests.get(url, timeout=5)

        if response.status_code == 200:
            data = response.json()
            return jsonify(backend_response=data)
        else:
            return jsonify(error='Failed to retrieve data from backend'), 500

    except requests.exceptions.RequestException as e:
        return jsonify(error=str(e)), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
