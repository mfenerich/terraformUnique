#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Get ACR name from Terraform output
ACR_NAME=$(terraform output -raw acr_name)

# Set image variables
IMAGE_TAG="3.1.0"
GHCR_IMAGE="ghcr.io/huggingface/text-generation-inference:$IMAGE_TAG"
REPO_NAME="text-generation-inference"
ACR_IMAGE="$REPO_NAME:$IMAGE_TAG"

echo "🔍 Checking if image '$IMAGE_TAG' exists in ACR: $ACR_NAME..."

# Check if the repository exists in ACR
REPOSITORY_EXISTS=$(az acr repository list --name "$ACR_NAME" --output tsv | grep -w "text-generation-inference" || true)

if [[ -z "$REPOSITORY_EXISTS" ]]; then
  echo "📂 Repository 'text-generation-inference' does not exist in ACR. Importing image..."
else
  # Check if the image tag exists in the repository
  IMAGE_EXISTS=$(az acr repository show-tags --name "$ACR_NAME" --repository "$REPO_NAME" --output tsv | grep -w "$IMAGE_TAG" || true)

  if [[ -z "$IMAGE_EXISTS" ]]; then
    echo "🚀 Image '$IMAGE_TAG' not found in ACR. Importing from GHCR to ACR..."
  else
    echo "✅ Image '$IMAGE_TAG' already exists in ACR. No action needed."
    exit 0
  fi
fi

# Import the image from GHCR to ACR
echo "📥 Importing image from GHCR: $GHCR_IMAGE to ACR: $ACR_NAME"
az acr import \
  --name "$ACR_NAME" \
  --source "$GHCR_IMAGE" \
  --image "$ACR_IMAGE"

echo "✅ Image successfully imported to ACR: $ACR_IMAGE"