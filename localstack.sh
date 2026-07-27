#!/bin/bash
set -ex

# Create SQS queues
DLQ_URL=$(awslocal sqs create-queue --queue-name local-dramatiq-dlq --attributes VisibilityTimeout=300 --query 'QueueUrl' --output text)
DLQ_ARN=$(awslocal sqs get-queue-attributes --queue-url "$DLQ_URL" --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)

awslocal sqs create-queue --queue-name local-dramatiq-failed --attributes VisibilityTimeout=300

awslocal sqs create-queue --queue-name local-dramatiq-periodic-tasks --attributes '{
  "RedrivePolicy": "{\"deadLetterTargetArn\":\"'"$DLQ_ARN"'\",\"maxReceiveCount\":\"3\"}",
  "VisibilityTimeout": "300"
}'
awslocal sqs create-queue --queue-name local-dramatiq-govuk-alerts --attributes '{
  "RedrivePolicy": "{\"deadLetterTargetArn\":\"'"$DLQ_ARN"'\",\"maxReceiveCount\":\"3\"}",
  "VisibilityTimeout": "300"
}'
awslocal sqs create-queue --queue-name local-dramatiq-broadcast-tasks --attributes '{
  "RedrivePolicy": "{\"deadLetterTargetArn\":\"'"$DLQ_ARN"'\",\"maxReceiveCount\":\"3\"}",
  "VisibilityTimeout": "300"
}'
awslocal sqs create-queue --queue-name local-dramatiq-high-priority-tasks --attributes '{
  "RedrivePolicy": "{\"deadLetterTargetArn\":\"'"$DLQ_ARN"'\",\"maxReceiveCount\":\"3\"}",
  "VisibilityTimeout": "300"
}'

# Create S3 buckets
awslocal s3 mb s3://local-govuk-alerts
awslocal s3 mb s3://local-govuk-alerts-blue
awslocal s3 mb s3://local-govuk-alerts-green
awslocal s3 mb s3://local-govuk-alerts-archive
awslocal s3 mb s3://local-area-sources

# Enable static website hosting
awslocal s3 website s3://local-govuk-alerts/ \
  --index-document index.html \
  --error-document error.html
awslocal s3 website s3://local-govuk-alerts-blue/ \
  --index-document index.html \
  --error-document error.html
awslocal s3 website s3://local-govuk-alerts-green/ \
  --index-document index.html \
  --error-document error.html
# Upload a sample index.html
echo "<html><body><h1>This is Gov.UK</h1><p>Well, not really, but you're probably meaning to head to <a href='/alerts'>/alerts</a>.</body></html>" \
  > /tmp/index.html

awslocal s3 cp /tmp/index.html s3://local-govuk-alerts/index.html
awslocal s3 cp /tmp/index.html s3://local-govuk-alerts-blue/index.html
awslocal s3 cp /tmp/index.html s3://local-govuk-alerts-green/index.html
awslocal s3 cp /area-data/"$AREAS_SOURCE_VERSION" s3://local-area-sources/"$AREAS_SOURCE_VERSION" --recursive
awslocal s3 cp /area-data/population_data.csv s3://local-area-sources/population_data.csv

# Create ssm parameter to indicate current state of blue/green deployment
awslocal ssm put-parameter \
  --name "govuk-website-current" \
  --type "String" \
  --value "blue"

# Verify test email identity
awslocal ses verify-email-identity --email-address support@localhost

