# Dockerfile
FROM python:3.11

WORKDIR /repo/flask-docker-app

COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

CMD ["python", "app.py"]