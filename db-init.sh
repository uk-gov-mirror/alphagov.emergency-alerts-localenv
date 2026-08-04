#!/bin/bash

apt update
apt install ansible postgresql-client python3-psycopg2 -y

set -e

source /eas/environment-container.sh

psql postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@pg:5432/postgres <<-EOSQL
    CREATE DATABASE ${TEST_DATABASE}_master;
    CREATE DATABASE $DATABASE;
EOSQL

cd /eas/emergency-alerts-api

. /venv/emergency-alerts-api/bin/activate

# PostGIS requires superuser to create the extension during its migration
# So we override 'master' so that Python logs in as the super user here
export MASTER_USERNAME=$POSTGRES_USER
export MASTER_PASSWORD=$POSTGRES_PASSWORD

flask db upgrade
echo "Flask done"

# Now we've ran Flask migrations we reset MASTER_USERNAME to the local Postgres user (non-superuser)
source /eas/environment-container.sh

# Because the tables were created by the postgres user, they're owned by postgres, not eas-user
# So we patch that up by adding grants after the migrations.
psql postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@pg:5432/$DATABASE -v ON_ERROR_STOP=1 <<-EOSQL
DO \$\$
BEGIN
    IF NOT EXISTS ( SELECT FROM pg_roles WHERE rolname = '$MASTER_USERNAME') THEN
        CREATE USER "$MASTER_USERNAME";
    END IF;

    GRANT ALL PRIVILEGES ON DATABASE $DATABASE TO "$MASTER_USERNAME";
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "$MASTER_USERNAME";
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO "$MASTER_USERNAME";

    ALTER USER "$MASTER_USERNAME" WITH PASSWORD '$MASTER_PASSWORD';
END;
\$\$;
EOSQL

# Copies the population data from the bucket to the database table `populations`
python scripts/adding_area_data/add_population_data.py

# Copies the area data from the bucket to the database tables
python scripts/adding_area_data/add_areas_data.py

# Generate a secret for the API key based off the ENCRYPTION_SECRET_KEY
FUNCTIONAL_TEST_API_KEY_SECRET=$(python /eas/gen-api-key-secret.py)

# And now we can put data in those tables as the non-superuser
cd /eas/emergency-alerts-tooling/ansible/environments/development
ansible-playbook -e "database_host=pg database_username=$MASTER_USERNAME database_password=$MASTER_PASSWORD functional_test_api_key_secret=$FUNCTIONAL_TEST_API_KEY_SECRET email_address=eas.admin@digital.cabinet-office.gov.uk phone_number=07700900111" 02-database-setup-after-migrations.yml

if [ $? -eq 0 ]
then
	echo "===================================="
	echo "= DATABASE INITIALISATION COMPLETE ="
	echo "===================================="
	exit 0
else
	exit 1
fi

exit 0
