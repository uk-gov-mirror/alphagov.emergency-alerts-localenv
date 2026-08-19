#!/bin/bash
# Intended to be invoked via functional tests as a GitHub Action
# Effectively assumes a fresh clone of this repo

set -e

echo "##[group]Prep environment.env"
# Prep environment.env with some good-enough values
sed -i.orig 's/_KEY=$/_KEY='${TEST_SECRET:-test-env}'/' environment.env
sed -i.orig 's/_SECRET=$/_SECRET='${TEST_SECRET:-test-env}'/' environment.env
sed -i.orig 's/_SALT=$/_SALT='${TEST_SECRET:-test-env}'/' environment.env
sed -i.orig 's/POSTGRES_USER=$/POSTGRES_USER=eas-user/' environment.env
sed -i.orig 's/MASTER_USERNAME=$/MASTER_USERNAME=eas-user/' environment.env
sed -i.orig 's/_PASSWORD=$/_PASSWORD=password/' environment.env

echo "##[endgroup]"
echo "##[group]Clone repositories"
set -x
# Partial clone repos but allowing the branch to be overridden by env
cd $(dirname "$0")/repos
git clone --filter=tree:0 -b ${REPO_BRANCH_API:-main} https://github.com/alphagov/emergency-alerts-api.git
git clone --filter=tree:0 -b ${REPO_BRANCH_GOVUK:-main} https://github.com/alphagov/emergency-alerts-govuk.git
git clone --filter=tree:0 -b ${REPO_BRANCH_ADMIN:-main} https://github.com/alphagov/emergency-alerts-admin.git
git clone --filter=tree:0 -b ${REPO_BRANCH_UTILS:-main} https://github.com/alphagov/emergency-alerts-utils.git
# Tooling is private
git clone --filter=tree:0 -b ${REPO_BRANCH_TOOLING:-main} https://${EAS_GITHUB_RUNNER_RO_TOKEN}@github.com/alphagov/emergency-alerts-tooling.git
set +x

echo "##[endgroup]"
echo "##[group]Resolved Git repositories"
echo "Localenv: $(git show -s --pretty='format:%H - %s')"
echo "Functional Tests: $(cd ../../; git show -s --pretty='format:%H - %s')"
echo "API: $(cd emergency-alerts-api; git show -s --pretty='format:%H - %s')"
echo "GovUK: $(cd emergency-alerts-govuk; git show -s --pretty='format:%H - %s')"
echo "Admin: $(cd emergency-alerts-admin; git show -s --pretty='format:%H - %s')"
echo "Utils: $(cd emergency-alerts-utils; git show -s --pretty='format:%H - %s')"
echo "Tooling: $(cd emergency-alerts-tooling; git show -s --pretty='format:%H - %s')"

echo "##[endgroup]"
echo "##[group]Prep services (generate version and compile JS/CSS)"
set -x
# Get the repos to be 'runnable' (i.e. have version.py, JS built, and some location data)
cd emergency-alerts-govuk
make generate-version-file && npm ci && npm run build
cd ../emergency-alerts-api
make generate-version-file
cd ../emergency-alerts-admin
make generate-version-file && npm ci && npm run build && cp app/broadcast_areas/broadcast-areas-test.sqlite3 app/broadcast_areas/broadcast-areas.sqlite3
# Back to root of this repo
cd ../../
set +x

echo "##[endgroup]"
echo "##[group]Import environment variables"
set -x
source environment-container.sh
set +x

echo "##[endgroup]"
echo "##[group]Build utils and start ancillaries"
set -x
docker compose up -d --build utils localstack pg jaeger lambda
set +x

echo "##[endgroup]"
echo "##[group]Build API"
set -x
docker compose build api
set +x

echo "##[endgroup]"
echo "##[group]Start API and DB init"
set -x
docker compose up -d api db-init
set +x

echo "##[endgroup]"
echo "##[group]Build and start other containers"
set -x
# We haven't built admin and govuk yet, so this'll do that while db-init is running in the background
docker compose up -d
set +x

echo "##[endgroup]"

while true; do
    if docker compose ps -q db-init | grep -q .; then
        echo "DB init is still running..."
        sleep 5
    else
        echo "DB init has finished"
        break
    fi
done
