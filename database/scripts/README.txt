# setup virtual envrionment
1. create virtual env: virtualenv myenv
2. activate the virtual environment: source myenv/bin/activate

# install dependencies
1. may need to run this first if you get an pg_config required error: sudo apt-get install libpq-dev
2. install dependencies: 
    - pip install psycopg2


# running scripts
- python database/scripts/database-setup.py