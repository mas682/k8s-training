
create virtual environment from k8s-training:
virtualenv venv

actiave the virtual environment:
source venv/bin/activate

install requirements:
pip install -r app/requirements.txt

run backend:
python -m app.backend.main