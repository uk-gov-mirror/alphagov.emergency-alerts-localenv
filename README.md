# Emergency Alerts Localenv

This is a opinionated and unperfect Docker Compose-based instance of the Emergency Alerts system in a turnkey fashion.
It also forms part of a development environment, with a VS Code workspace mostly pre-configured to work across repos.
There is also a devcontainer configuration, but this is experimental and may not work for your needs.

It will use the exact same Dockerfiles as used to build the main system as well as approximations of AWS components running locally.
You may of course run components manually, or only use a subset of these components.
Containers will bind-mount the actual relevant repos in, so applications changes can take effect after a simple container restart instead of rebuilding them.

Notably it does *not* include the Cell Broadcast Controller Proxy functionality (a Lambda). 'Sending' a broadcast will almost immediately pass via a very silly hardcoded response (the 'lambda' container).


## Getting started

You will want a machine running Docker (with compose), Python 3.12, and Node.JS (22).

This repository expects a specific folder layout. More specifically, repositories should be checked out to `repos/<repo>` within this repository.

```bash
git clone https://github.com/alphagov/emergency-alerts-localenv
mkdir -p emergency-alerts-localenv/repos
cd emergency-alerts-localenv/repos
git clone https://github.com/alphagov/emergency-alerts-api.git
git clone https://github.com/alphagov/emergency-alerts-govuk.git
git clone https://github.com/alphagov/emergency-alerts-utils.git
git clone https://github.com/alphagov/emergency-alerts-tooling.git
git clone https://github.com/alphagov/emergency-alerts-admin.git
git clone https://github.com/alphagov/emergency-alerts-functional-tests.git
```

Running on Linux? Make sure the repos have rw for everyone - as the containers run as non-root and will need access to bind mounts of their respective repo folders.

**If you're using a VPN which does MitM traffic inspection**: You will need to install the root CA certificate on your base image. The quickest way to do this is to go to Keychain Access (on macOS), search for the VPN CA (e.g., "Zscaler"), right-click, and export the CA certificate as a `.pem` file. Then place that under the root of your `emergency-alerts-utils` repository, named `vpn-ca.pem`. It'll be picked up by the Docker build, and in turn inherited by the application images.

> You'll want to have suitable virtual environments for each Python project and run a `make bootstrap` within them. But if you're just after running containers locally immediately you can sidestep this a bit:
> ```bash
> # in repos/
> # Get GovUK's JavaScript and CSS compiled
> cd emergency-alerts-govuk
> make generate-version-file && npm ci && npm run build
> # Generate version files to be imported at runtime
> cd ../emergency-alerts-api
> make generate-version-file
> cd ../emergency-alerts-admin
> # and copy the small test DB instead of the large one (this will semi-break area selection)
> make generate-version-file && npm ci && npm run build && cp app/broadcast_areas/broadcast-areas-test.sqlite3 app/broadcast_areas/broadcast-areas.sqlite3
> ```

For proper development you'll want to create a Python virtual environment in each repo and install Python dependencies (and build Node components too)
```bash
# in repos/
cd emergency-alerts-govuk
python -m venv venv
source venv/bin/activate; make bootstrap; deactivate
cd ../emergency-alerts-api
python -m venv venv
source venv/bin/activate; make bootstrap; deactivate
cd ../emergency-alerts-admin
python -m venv venv
source venv/bin/activate; make bootstrap; deactivate
cd ../emergency-alerts-utils
python -m venv venv
source venv/bin/activate; make bootstrap; deactivate
cd ../emergency-alerts-functional-tests
python -m venv venv
source venv/bin/activate; make bootstrap; deactivate
```

Admin requires a large SQLite Database of location libraries. You can fetch this from the `infra-mgt` AWS account in an S3 bucket.
It will need copying to `emergency-alerts-localenv/repos/emergency-alerts-admin/app/broadcast_areas/broadcast-areas.sqlite3`.

Modify the `emergency-alerts-localenv/environment.env` file by adding the credentials for the environment variables:
 - MASTER_USERNAME
 - MASTER_PASSWORD
 - TEST_RDS_USER
 - TEST_RDS_PASSWORD
 - NOTIFY_API_CLIENT_SECRET
 - SECRET_KEY
 - DANGEROUS_SALT
 - ENCRYPTION_DANGEROUS_SALT
 - ENCRYPTION_SECRET_KEY
 - ADMIN_CLIENT_SECRET
 - GOVUK_CLIENT_SECRET
 - GOVUK_ALERTS_PUBLISH_CLIENT_SECRET
 - POSTGRES_PASSWORD
 - POSTGRES_USER

In general you can largely make these values up, but you'll only want to set these once for a given DB's lifetime.

You will also need to edit `emergency-alerts-localenv/repos/emergency-alerts-functional-tests/environment-localenv.env`
to set secrets to match those you defined above.

Now you should be able to ask Docker Compose to come up. We use a shared based image which there isn't great native support for.
You may also need to ensure Postgres and Localstack are up and running before the others.
```
# For Postgres container envs to be populated:
set -a && source environment.env && set +a
docker compose up -d --build utils localstack pg jaeger lambda
docker compose build api
docker compose up -d api db-init
docker compose up -d
```

If you're debugging outside of the container:
```
docker compose stop admin  # then start admin locally on port 6012
docker compose stop api    # then start api locally on port 6011
docker compose stop govuk  # then start govuk locally on port 6017

Ensure that you have the follwing `hosts` file entry:
127.0.0.1 localstack api pg
```

This should automatically provision Postgres with a test database and auto-populate LocalStack with 'AWS' resources.
The admin UI should be reachable at http://localhost:6012 and the GovUK at http://local-govuk-alerts.s3-website.localhost.localstack.cloud:4566/alerts.
