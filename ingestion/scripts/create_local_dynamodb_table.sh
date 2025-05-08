#!/bin/bash
aws dynamodb create-table \
  --table-name gapwatch_articles \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --endpoint-url http://localhost:8000 \
  --region us-west-1

echo "Local DynamoDB table 'gapwatch_articles' created."
