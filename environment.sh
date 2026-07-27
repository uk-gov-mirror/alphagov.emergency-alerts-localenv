#!/usr/bin/env bash
#localenv

export HOST='hosted'
export ENVIRONMENT='local'

export AWS_ACCESS_KEY_ID=aws_key
export AWS_SECRET_ACCESS_KEY=aws_secret
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL_CLOUDWATCH=http://localstack:4566
export AWS_ENDPOINT_URL_SQS=http://localstack:4566
export AWS_ENDPOINT_URL_S3=http://localstack:4566
export AWS_ENDPOINT_URL_SES=http://localstack:4566
export AWS_ENDPOINT_URL_SSM=http://localstack:4566

export DLQ_URL="http://sqs.us-east-1.localstack:4566/000000000000/local-dramatiq-dlq"
export FAILED_QUEUE_URL="http://sqs.us-east-1.localstack:4566/000000000000/local-dramatiq-failed"

export FLASK_APP=application.py
export FLASK_DEBUG=False
export WERKZEUG_DEBUG_PIN=off

export DATABASE='emergency_alerts'
export TEST_DATABASE='test_emergency_alerts_master'
export RDS_HOST='pg'
export RDS_PORT=5432

export USE_RDS_IAM_AUTH="false"

export API_HOST_NAME=http://api:6011
export ADMIN_EXTERNAL_URL=http://localhost:6012
export ADMIN_ACTION_ALLOW_SELF_APPROVAL=true
export AREAS_SOURCE_BUCKET_NAME='local-area-sources'
# Version determines where area data copied to, in localstack.sh
export AREAS_SOURCE_VERSION='1.0.0'
export GOVUK_ALERTS_S3_BUCKET_NAME='local-govuk-alerts'
export GOVUK_ALERTS_BLUE_S3_BUCKET_NAME='local-govuk-alerts-blue'
export GOVUK_ALERTS_GREEN_S3_BUCKET_NAME='local-govuk-alerts-green'
export GOVUK_ALERTS_ARCHIVE_S3_BUCKET_NAME='local-govuk-alerts-archive'
export GOVUK_ALERTS_CURRENT_BUCKET_PARAM='govuk-website-current'
# Cloudfront endpoint not available in free localstack, so disable
export GOVUK_ALERTS_CLOUDFRONT_ENABLED=false
export GOVUK_ALERTS_HOST_URL=http://localhost:6017
# SesV2 endpoint not available in free localstack, do disable
export SES_ENABLED=false
export FASTLY_ENABLED=false
# If running the functional tests on a host - this is the IP of the host from the container's PoV
# (at least from the perspective of Docker Desktop on macOS)
export FUNCTIONAL_TEST_IPS='172.18.0.1'
export FUNCTIONAL_TEST_USER_ID='44153bb8-db31-4cb0-8cee-b909a5482d1a'

# ----

# Confusingly master here refers to the application's DB user (i.e. not the DB superuser)
# Make sure this username is different to POSTGRES_USER below
export MASTER_USERNAME=
export MASTER_PASSWORD=

export NOTIFY_API_CLIENT_SECRET=
export SECRET_KEY=
export DANGEROUS_SALT=
export ENCRYPTION_DANGEROUS_SALT=
export ENCRYPTION_SECRET_KEY=
export ADMIN_CLIENT_SECRET=
export GOVUK_CLIENT_SECRET=
export GOVUK_ALERTS_PUBLISH_CLIENT_SECRET=

# The superuser within Postgres
export POSTGRES_USER=
export POSTGRES_PASSWORD=
