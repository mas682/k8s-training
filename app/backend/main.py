from flask import Flask, jsonify, abort
import os
import threading
import time
import socket
import logging
from app.utils.database import DataBase
from kubernetes import client, config

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
# Load in-cluster config
config.load_incluster_config()
# Create an API client
v1 = client.CoreV1Api()


# Flag to indicate whether the health check should fail
health_check_failed = True
app_ready = False
db_connection_tries = 0

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

def connect_to_database():
    """
    Function to connect to the database if not connected
    """
    global db_connection_tries
    while True:
        if db.db_connection is None or db.db_connection.closed:
            try:
                db.connect(max_attempts=3, sleep_time=1)
                db_connection_tries = 0
            except Exception as e:
                db_connection_tries = db_connection_tries + 1
                logger.error(f"Error connecting to database: {e}")

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
    global db_connection_tries
    connected = None if db is None or db.db_connection is None else not db.db_connection.closed
    if db_connection_tries > 2:
        return jsonify(status='error', message='Failed to connect to database', db_connnected=connected), 500
    return jsonify(status='ok', message='Health check passed', db_connnected=connected), 200


@app.route('/readiness')
def readiness_check():
    global app_ready

    if db is None or not db.connected:
        return jsonify(status='error', message="Backend not connected to the database"), 500

    try:
        db.query("SELECT 1")
        app_ready = True
        return jsonify(status='ok', message='Readiness check passed')

    except Exception as e:
        app_ready = False
        return jsonify(status='error', message=f"Readiness check failed. Error connecting to database: {str(e)}"), 500


@app.route('/get_users')
def get_users():
    global app_ready
    if not app_ready:
        return jsonify(error='Application not ready'), 500
    result = db.query("SELECT * FROM sample_table")

    return jsonify(
        result=result
    )

@app.route('/get-secret/<secret_name>', methods=['GET'])
def get_secret(secret_name):
    try:
        namespace = 'default'
        # Access the specified secret in the given namespace
        secret = v1.read_namespaced_secret(name=secret_name, namespace=namespace)

        # Decode and print secret data
        secret_data = {key: value.decode('utf-8') for key, value in secret.data.items()}
        
        return jsonify(secret_data), 200
    except client.exceptions.ApiException as e:
        return jsonify({"error": str(e)}), 404


db = None

# Start the health check failure simulation in a separate thread
fail_health_check = bool(os.environ.get("FAIL_HEALTHCHECK", "False") == "True")
logger.info(f"Fail health check: {fail_health_check}")
if not fail_health_check:
    health_check_failed = False
else:
    thread = threading.Thread(target=simulate_health_check)
    thread.start()

if __name__ == '__main__':
    db = DataBase(DataBase.getCredentials())
    thread = threading.Thread(target=connect_to_database)
    thread.start()
    app.run(debug=True, host='0.0.0.0', port=5000)
