#!/usr/bin/env bash
# ==============================================================================
# Deploy Frontend Static Assets to AWS S3 & Invalidate CloudFront CDN Cache
# ==============================================================================
set -euo pipefail

# --- Color formatting ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Environment Configuration ---
ENV="${1:-dev}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT_DIR}/terraform/environments/${ENV}"
FRONTEND_SOURCE="${ROOT_DIR}/app/services/frontend/public"

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}🚀 Deploying TaskApp Frontend to Environment: [${ENV}]${NC}"
echo -e "${CYAN}====================================================${NC}"

# 1. Verify Prerequisites
command -v aws >/dev/null 2>&1 || { echo -e "${RED}❌ AWS CLI is not installed or not in PATH.${NC}" >&2; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo -e "${YELLOW}⚠️ Terraform CLI not found, falling back to AWS CLI auto-discovery.${NC}"; }

if [ ! -d "${FRONTEND_SOURCE}" ]; then
  echo -e "${RED}❌ Frontend source directory not found: ${FRONTEND_SOURCE}${NC}" >&2
  exit 1
fi

# 2. Resolve S3 Bucket & CloudFront Distribution
S3_BUCKET=""
CF_DIST_ID=""
CF_DOMAIN=""

if [ -d "${TF_DIR}" ] && command -v terraform >/dev/null 2>&1; then
  echo -e "🔍 Reading Terraform outputs from ${TF_DIR}..."
  S3_BUCKET="$(terraform -chdir="${TF_DIR}" output -raw frontend_s3_bucket 2>/dev/null || true)"
  CF_DIST_ID="$(terraform -chdir="${TF_DIR}" output -raw cloudfront_distribution_id 2>/dev/null || true)"
  CF_DOMAIN="$(terraform -chdir="${TF_DIR}" output -raw cloudfront_domain_name 2>/dev/null || true)"
fi

# Fallback: Query AWS CLI if Terraform outputs were not resolved
if [ -z "${S3_BUCKET}" ]; then
  echo -e "${YELLOW}🔍 Searching S3 buckets with tag Project=cloudops-taskapp...${NC}"
  S3_BUCKET="$(aws s3api list-buckets --query "Buckets[?contains(Name, 'cloudops-taskapp-${ENV}-frontend')].Name | [0]" --output text)"
fi

if [ -z "${S3_BUCKET}" ] || [ "${S3_BUCKET}" == "None" ]; then
  echo -e "${RED}❌ Could not determine frontend S3 bucket name.${NC}"
  echo -e "   Please specify manually via: S3_BUCKET=my-bucket-name $0 ${ENV}" >&2
  exit 1
fi

echo -e "✅ Target S3 Bucket: ${GREEN}${S3_BUCKET}${NC}"

# 3. Upload Static Files with Optimized HTTP Cache-Control Headers
echo -e "\n📦 Syncing files from ${FRONTEND_SOURCE} to s3://${S3_BUCKET}..."

# HTML files: no-cache to guarantee instantaneous updates on deployment
aws s3 sync "${FRONTEND_SOURCE}" "s3://${S3_BUCKET}" \
  --delete \
  --exclude "*" \
  --include "*.html" \
  --cache-control "max-age=0, no-cache, no-store, must-revalidate" \
  --content-type "text/html"

# Assets (JS, CSS, images, fonts): Long cache (1 year)
aws s3 sync "${FRONTEND_SOURCE}" "s3://${S3_BUCKET}" \
  --delete \
  --exclude "*.html" \
  --cache-control "public, max-age=31536000, immutable"

echo -e "✅ S3 static file synchronization complete."

# 4. Invalidate CloudFront CDN Cache
if [ -z "${CF_DIST_ID}" ] || [ "${CF_DIST_ID}" == "None" ]; then
  echo -e "🔍 Discovering CloudFront distribution ID for S3 bucket..."
  CF_DIST_ID="$(aws cloudfront list-distributions --query "DistributionList.Items[?contains(Origins.Items[0].DomainName, '${S3_BUCKET}')].Id | [0]" --output text 2>/dev/null || true)"
fi

if [ -n "${CF_DIST_ID}" ] && [ "${CF_DIST_ID}" != "None" ]; then
  echo -e "\n🔄 Invalidating CloudFront cache (Distribution ID: ${GREEN}${CF_DIST_ID}${NC})..."
  INVALIDATION_ID="$(aws cloudfront create-invalidation \
    --distribution-id "${CF_DIST_ID}" \
    --paths "/*" \
    --query "Invalidation.Id" \
    --output text)"
  echo -e "✅ CloudFront Invalidation submitted: ${GREEN}${INVALIDATION_ID}${NC}"
else
  echo -e "${YELLOW}⚠️ Could not automatically detect CloudFront Distribution ID. Skipping invalidation.${NC}"
fi

# 5. Summary & Live Application URL
echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}🎉 Frontend Deployment Successfully Completed!${NC}"
echo -e "${GREEN}====================================================${NC}"

if [ -n "${CF_DOMAIN}" ] && [ "${CF_DOMAIN}" != "None" ]; then
  echo -e "🌐 Application URL: ${CYAN}https://${CF_DOMAIN}${NC}"
else
  echo -e "🌐 Check CloudFront domain via: terraform -chdir=terraform/environments/${ENV} output cloudfront_domain_name"
fi
echo -e "${GREEN}====================================================${NC}\n"
