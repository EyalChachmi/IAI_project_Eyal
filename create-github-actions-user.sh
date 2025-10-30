#!/bin/bash
# Script to create IAM user for GitHub Actions deployment

set -e

USER_NAME="github-actions-deployer"
POLICY_NAME="GitHubActionsEKSDeployPolicy"

echo "Creating IAM user: $USER_NAME..."
aws iam create-user --user-name $USER_NAME

echo "Creating custom IAM policy..."
POLICY_ARN=$(aws iam create-policy \
  --policy-name $POLICY_NAME \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:ListImages"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "sts:GetCallerIdentity"
        ],
        "Resource": "*"
      }
    ]
  }' \
  --query 'Policy.Arn' \
  --output text)

echo "Policy ARN: $POLICY_ARN"

echo "Attaching policy to user..."
aws iam attach-user-policy \
  --user-name $USER_NAME \
  --policy-arn $POLICY_ARN

echo "Creating access key..."
aws iam create-access-key --user-name $USER_NAME --output json > github-actions-credentials.json

echo ""
echo "✅ IAM user created successfully!"
echo ""
echo "Access credentials saved to: github-actions-credentials.json"
echo ""
echo "To add to GitHub Secrets:"
cat github-actions-credentials.json | jq -r '"AWS_ACCESS_KEY_ID: \(.AccessKey.AccessKeyId)\nAWS_SECRET_ACCESS_KEY: \(.AccessKey.SecretAccessKey)"'
echo ""
echo "⚠️  IMPORTANT: Store these credentials securely and delete the JSON file after adding to GitHub!"
