#!/bin/bash

# --- Configuration ---
PROFILE="glaum"
BUCKET_NAME="yoga-school-qa"
DIST_ID="E3IFGG7F5XU8IS"
BUILD_PATH="build\web" 

# 1. Build the project
echo "Building Flutter application..."
flutter build web -t lib/main_qa.dart

# 2. Sync to S3 using the 'glaum' profile
echo "Syncing to S3 with profile: $PROFILE..."
aws s3 sync $BUILD_PATH s3://$BUCKET_NAME --delete --profile $PROFILE

# 3. Invalidate CloudFront using the 'glaum' profile
echo "Invalidating CloudFront cache..."
aws cloudfront create-invalidation \
  --distribution-id $DIST_ID \
  --paths "/*" \
  --profile $PROFILE

echo "Successfully deployed using profile: $PROFILE! 🚀"