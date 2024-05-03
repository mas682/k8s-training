from flask import Flask, jsonify, abort
import os
import threading
import time
import socket
import logging
from app.utils.database import getCredentials

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Flag to indicate whether the health check should fail
health_check_failed = True

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

@app.route('/')
def hello():
    ip = get_local_ip()
    pod_name = socket.gethostname()
    return jsonify(
        ip=ip,
        pod_name=pod_name
    )

@app.route('/health')
def health_check():
    global health_check_failed

    # Check if the health check has failed
    if health_check_failed:
        abort(500, description='Health check failing')

    # For simplicity, just return a JSON response indicating the application is healthy
    return jsonify(status='ok', message='Health check passed')




# Start the health check failure simulation in a separate thread
fail_health_check = bool(os.environ.get("FAIL_HEALTHCHECK", "False") == "True")
logger.info(f"Fail health check: {fail_health_check}")
if not fail_health_check:
    health_check_failed = False
else:
    thread = threading.Thread(target=simulate_health_check)
    thread.start()

if __name__ == '__main__':
    credentials = getCredentials()
    print(credentials.dbname)
    app.run(debug=True, host='0.0.0.0', port=5000)
