#!/bin/bash

# Set up logging
LOG_FILE="deploy.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

# Error handling function
handle_error() {
    local exit_code=$?
    local line_number=$1
    echo "❌ Error occurred at line $line_number (exit code: $exit_code)" | tee -a "$LOG_FILE"
    echo "📋 Check the log file: $LOG_FILE" | tee -a "$LOG_FILE"
    exit $exit_code
}

# Set error trap
trap 'handle_error $LINENO' ERR

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "🔍 Checking prerequisites..." | tee -a "$LOG_FILE"

if ! command_exists terraform; then
    echo "❌ Terraform is not installed. Please install Terraform first." | tee -a "$LOG_FILE"
    exit 1
fi

if ! command_exists aws; then
    echo "❌ AWS CLI is not installed. Please install AWS CLI first." | tee -a "$LOG_FILE"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "❌ AWS credentials not configured. Please run 'aws configure' first." | tee -a "$LOG_FILE"
    exit 1
fi

echo "🚀 Starting full deployment of NailColorizer Lite..." | tee -a "$LOG_FILE"
echo "⏱️  Expected deployment time: 5-10 minutes (CloudFront takes 5-7 minutes)" | tee -a "$LOG_FILE"

# Step 1: Terraform Init
echo "🔧 Initializing Terraform..." | tee -a "$LOG_FILE"
if ! terraform init; then
    echo "❌ Terraform init failed" | tee -a "$LOG_FILE"
    exit 1
fi

# Step 2: Terraform Apply
echo "⚙️  Applying infrastructure..." | tee -a "$LOG_FILE"
echo "📋 This includes EC2, S3, API Gateway, and CloudFront..." | tee -a "$LOG_FILE"
if ! terraform apply -auto-approve; then
    echo "❌ Terraform apply failed" | tee -a "$LOG_FILE"
    exit 1
fi

# Step 3: Upload UI files to S3
echo "📤 Uploading UI files to S3 bucket..." | tee -a "$LOG_FILE"

# Check for local files
if [ ! -f "index.html" ] || [ ! -f "main.js" ]; then
    echo "❌ UI files (index.html, main.js) not found in the current directory." | tee -a "$LOG_FILE"
    echo "Please ensure these files exist before deploying." | tee -a "$LOG_FILE"
    exit 1
fi

API_URL=$(terraform output -raw api_url)
WEBSITE_BUCKET_NAME=$(terraform output -raw website_bucket_name)

if [ -z "$WEBSITE_BUCKET_NAME" ] || [ -z "$API_URL" ]; then
    echo "❌ Could not retrieve website bucket name or API URL from Terraform output" | tee -a "$LOG_FILE"
    exit 1
fi

# Create api-info.json
echo "{\"api_url\": \"$API_URL\"}" > api-info.json
echo "✅ api-info.json created" | tee -a "$LOG_FILE"

echo "✅ Website bucket name retrieved: ${WEBSITE_BUCKET_NAME}" | tee -a "$LOG_FILE"

echo "📤 Uploading index.html..." | tee -a "$LOG_FILE"
aws s3 cp index.html "s3://${WEBSITE_BUCKET_NAME}/index.html"

echo "📤 Uploading main.js..." | tee -a "$LOG_FILE"
aws s3 cp main.js "s3://${WEBSITE_BUCKET_NAME}/main.js"

echo "📤 Uploading api-info.json..." | tee -a "$LOG_FILE"
aws s3 cp api-info.json "s3://${WEBSITE_BUCKET_NAME}/api-info.json"

echo "✅ UI files uploaded successfully." | tee -a "$LOG_FILE"

# Step 4: Wait for services to stabilize
echo "⏳ Waiting for services to stabilize..." | tee -a "$LOG_FILE"
echo "🔄 EC2 instance and API Gateway should be ready in ~30 seconds" | tee -a "$LOG_FILE"
sleep 30

# Step 5: Display Outputs with error handling
echo "📊 Retrieving deployment outputs..." | tee -a "$LOG_FILE"

API_URL=""
WEBSITE_URL=""

if API_URL=$(terraform output -raw api_url 2>/dev/null); then
    echo "✅ API URL retrieved successfully" | tee -a "$LOG_FILE"
else
    echo "⚠️  Could not retrieve API URL from Terraform output" | tee -a "$LOG_FILE"
    API_URL="Not available"
fi

if WEBSITE_URL=$(terraform output -raw website_url 2>/dev/null); then
    echo "✅ Website URL retrieved successfully" | tee -a "$LOG_FILE"
else
    echo "⚠️  Could not retrieve Website URL from Terraform output" | tee -a "$LOG_FILE"
    WEBSITE_URL="Not available"
fi

echo "" | tee -a "$LOG_FILE"
echo "✅ Deployment complete!" | tee -a "$LOG_FILE"
echo "📮 API Endpoint: $API_URL" | tee -a "$LOG_FILE"
echo "🌍 Website: $WEBSITE_URL" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "⚠️  Important Notes:" | tee -a "$LOG_FILE"
echo "   • CloudFront may take 5-7 minutes to fully deploy" | tee -a "$LOG_FILE"
echo "   • The website URL will work once CloudFront is ready" | tee -a "$LOG_FILE"
echo "   • API endpoint should be available immediately" | tee -a "$LOG_FILE"
echo "📋 Full deployment log: $LOG_FILE" | tee -a "$LOG_FILE"

# Remove error trap on successful completion
trap - ERR
