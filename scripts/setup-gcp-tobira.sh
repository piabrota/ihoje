#!/bin/bash
# Script to set up GCP infrastructure for Tobira deployment

set -e

# Display welcome banner
cat << "EOF"
┌───────────────────────────────────────────────────┐
│ 📦 Tobira GCP Infrastructure Setup                │
│                                                   │
│ This script will set up the necessary GCP         │
│ infrastructure for deploying Tobira frontends     │
│ (both mock and Shinri-no-Tobira versions)         │
└───────────────────────────────────────────────────┘
EOF

# Check if user is authenticated with gcloud
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" >/dev/null 2>&1; then
  echo "❌ Not authenticated with gcloud. Please run 'gcloud auth login' first."
  exit 1
fi

# Prompt for project ID
read -p "Enter your GCP project ID: " PROJECT_ID
if [ -z "$PROJECT_ID" ]; then
  echo "❌ Project ID is required."
  exit 1
fi

# Set project
echo "📦 Setting GCP project to $PROJECT_ID..."
gcloud config set project "$PROJECT_ID"

# Set default region
REGION="us-central1"
read -p "Enter GCP region (default: $REGION): " input_region
REGION=${input_region:-$REGION}

# Enable required APIs
echo "📦 Enabling required GCP APIs..."
gcloud services enable \
  artifactregistry.googleapis.com \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  iam.googleapis.com

# Create Artifact Registry repository
REPO_NAME="tobira-containers"
echo "📦 Creating Artifact Registry repository: $REPO_NAME in $REGION..."
if ! gcloud artifacts repositories describe "$REPO_NAME" --location="$REGION" >/dev/null 2>&1; then
  gcloud artifacts repositories create "$REPO_NAME" \
    --repository-format=docker \
    --location="$REGION" \
    --description="Container registry for Tobira frontends"
  echo "✅ Created Artifact Registry repository: $REPO_NAME"
else
  echo "ℹ️ Artifact Registry repository $REPO_NAME already exists."
fi

# Create service account for GitHub Actions
SA_NAME="github-action-tobira"
SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"
echo "📦 Creating service account for GitHub Actions: $SA_NAME..."

if ! gcloud iam service-accounts describe "$SA_EMAIL" >/dev/null 2>&1; then
  gcloud iam service-accounts create "$SA_NAME" \
    --display-name="GitHub Actions for Tobira"
  echo "✅ Created service account: $SA_EMAIL"
else
  echo "ℹ️ Service account $SA_EMAIL already exists."
fi

# Grant required roles to the service account
echo "📦 Granting required roles to service account..."
ROLES=(
  "roles/artifactregistry.writer"
  "roles/run.admin"
  "roles/iam.serviceAccountUser"
  "roles/storage.admin"
)

for ROLE in "${ROLES[@]}"; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="$ROLE"
done
echo "✅ Granted required roles to service account"

# Create a service account key
echo "📦 Creating service account key..."
KEY_FILE="$SA_NAME-key.json"
if [ -f "$KEY_FILE" ]; then
  read -p "Key file already exists. Generate a new one? (y/N): " generate_new
  if [ "$generate_new" != "y" ] && [ "$generate_new" != "Y" ]; then
    echo "ℹ️ Using existing key file: $KEY_FILE"
  else
    gcloud iam service-accounts keys create "$KEY_FILE" \
      --iam-account="$SA_EMAIL"
    echo "✅ Created new service account key: $KEY_FILE"
  fi
else
  gcloud iam service-accounts keys create "$KEY_FILE" \
    --iam-account="$SA_EMAIL"
  echo "✅ Created service account key: $KEY_FILE"
fi

# Encode the key file for GitHub Actions secrets
if [ -f "$KEY_FILE" ]; then
  SERVICE_ACCOUNT_KEY=$(cat "$KEY_FILE")
  echo ""
  echo "🔐 Add the following secrets to your GitHub repository:"
  echo ""
  echo "1. Name: GCP_PROJECT_ID"
  echo "   Value: $PROJECT_ID"
  echo ""
  echo "2. Name: GCP_SA_KEY"
  echo "   Value: <The contents of $KEY_FILE>"
  echo ""
fi

# Create placeholder Cloud Run services (optional)
read -p "Create placeholder Cloud Run services now? (y/N): " create_services
if [ "$create_services" = "y" ] || [ "$create_services" = "Y" ]; then
  echo "📦 Creating placeholder Cloud Run services..."
  
  # Create a simple placeholder image using distroless
  echo "FROM gcr.io/distroless/static-debian11
COPY index.html /
CMD [\"--port=8080\"]
ENTRYPOINT [\"/busybox/httpd\", \"-f\", \"-h\", \"/\"]" > Dockerfile.placeholder

  echo "<html><body><h1>Tobira Placeholder</h1><p>This is a placeholder for the Tobira service.</p></body></html>" > index.html
  
  # Build and push placeholder images
  echo "📦 Building and pushing placeholder images..."
  gcloud builds submit --tag "$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/mock:placeholder" \
    --dockerfile=Dockerfile.placeholder .
  gcloud builds submit --tag "$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/shinri-no-tobira:placeholder" \
    --dockerfile=Dockerfile.placeholder .
  
  # Deploy placeholder services
  echo "📦 Deploying placeholder Cloud Run services..."
  gcloud run deploy tobira-mock \
    --image="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/mock:placeholder" \
    --region="$REGION" \
    --platform=managed \
    --allow-unauthenticated \
    --memory=512Mi \
    --cpu=1000m \
    --min-instances=0 \
    --max-instances=2 \
    --port=8080 \
    --set-env-vars=IHOJE_ENVIRONMENT=production
  
  gcloud run deploy shinri-no-tobira \
    --image="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/shinri-no-tobira:placeholder" \
    --region="$REGION" \
    --platform=managed \
    --allow-unauthenticated \
    --memory=1Gi \
    --cpu=1000m \
    --min-instances=0 \
    --max-instances=3 \
    --port=8080 \
    --set-env-vars=IHOJE_ENVIRONMENT=production,IHOJE_API_URL=https://api.ihoje.app
  
  # Clean up temporary files
  rm -f Dockerfile.placeholder index.html
  
  echo "✅ Placeholder services created"
  
  # Get service URLs
  MOCK_URL=$(gcloud run services describe tobira-mock --region="$REGION" --format='value(status.url)')
  MAIN_URL=$(gcloud run services describe shinri-no-tobira --region="$REGION" --format='value(status.url)')
  
  echo "🌐 Service URLs:"
  echo "  Mock Tobira: $MOCK_URL"
  echo "  Shinri-no-Tobira: $MAIN_URL"
else
  echo "ℹ️ Skipping placeholder services creation"
fi

echo ""
echo "✅ GCP infrastructure setup complete!"
echo ""
echo "Next steps:"
echo "1. Add the GitHub secrets as described above"
echo "2. Push changes to the main branch to trigger a deployment"
echo "3. Check the GitHub Actions logs for deployment status"
echo ""
echo "For more information, refer to the GCP deployment documentation:"
echo "  /docs/project/gcp_deployment.md"
echo ""