# GCP Deployment Guide

This document provides instructions for setting up the CI/CD pipeline to deploy Tobira to Google Cloud Platform (GCP) using GitHub Actions.

## Infrastructure Overview

The Tobira frontend is deployed as two services on Google Cloud:

1. **Mock Service** - A simplified version without WebAssembly for testing
2. **Shinri-no-Tobira Service** - The full WebAssembly-powered frontend

Both services are deployed using:
- GCP Artifact Registry for container image storage
- GCP Cloud Run for serverless container execution

The infrastructure is managed using Pulumi through the Gugu component.

## Required GitHub Secrets

To enable the CI/CD pipeline, you need to set up the following GitHub secrets in your repository:

| Secret Name | Description | How to Obtain |
|-------------|-------------|---------------|
| `GCP_PROJECT_ID` | Your GCP project ID | Found in GCP Console under Project Info |
| `GCP_SA_KEY` | Service account key JSON | Generated when creating a service account |

## Setup Instructions

### 1. Create a GCP Service Account

1. Go to the GCP Console and navigate to **IAM & Admin** > **Service Accounts**
2. Click **Create Service Account**
3. Name: `github-action-tobira`
4. Grant the following roles:
   - `Artifact Registry Writer`
   - `Cloud Run Admin`
   - `Service Account User`
   - `Storage Admin` (for Pulumi state if needed)

### 2. Generate Service Account Key

1. Find your service account in the list and click on it
2. Go to the **Keys** tab
3. Click **Add Key** > **Create new key**
4. Select JSON format and click **Create**
5. Save the downloaded key file securely

### 3. Configure GitHub Secrets

1. Go to your GitHub repository settings
2. Navigate to **Secrets and variables** > **Actions**
3. Click **New repository secret**
4. Add the secrets:
   - Name: `GCP_PROJECT_ID`, Value: Your GCP project ID
   - Name: `GCP_SA_KEY`, Value: The entire contents of the JSON key file

### 4. Set Up Artifact Registry

If you're using Pulumi via Gugu:
- The repository will be created automatically by the infrastructure code

If you're setting up manually:
1. Go to **Artifact Registry** in GCP Console
2. Click **Create Repository**
3. Name: `tobira-containers`
4. Format: `Docker`
5. Location: `us-central1` (or your preferred region)
6. Click **Create**

### 5. Deploy the Infrastructure

The infrastructure can be deployed in two ways:

**Option 1: Using Pulumi via Gugu (Recommended)**
```bash
cd gugu
scala-cli run .
```

**Option 2: Manual Setup**
1. Create the Artifact Registry as described above
2. Create Cloud Run services manually:
   ```bash
   # Create Mock service
   gcloud run deploy tobira-mock \
     --image=us-central1-docker.pkg.dev/YOUR_PROJECT_ID/tobira-containers/mock:latest \
     --region=us-central1 \
     --platform=managed \
     --allow-unauthenticated \
     --memory=512Mi \
     --cpu=1000m \
     --min-instances=0 \
     --max-instances=2 \
     --port=8080 \
     --set-env-vars=IHOJE_ENVIRONMENT=production

   # Create Shinri-no-Tobira service
   gcloud run deploy shinri-no-tobira \
     --image=us-central1-docker.pkg.dev/YOUR_PROJECT_ID/tobira-containers/shinri-no-tobira:latest \
     --region=us-central1 \
     --platform=managed \
     --allow-unauthenticated \
     --memory=1Gi \
     --cpu=1000m \
     --min-instances=0 \
     --max-instances=3 \
     --port=8080 \
     --set-env-vars=IHOJE_ENVIRONMENT=production,IHOJE_API_URL=https://api.ihoje.app
   ```

## Triggering Deployments

Deployments are automatically triggered when:
- Code is pushed to the `main` branch
- Changes are made to files in the `tobira/`, `pokeball/`, or `sharingan/` directories
- You can also manually trigger a deployment using the **Actions** tab in GitHub

## Troubleshooting

### Common Issues:

1. **Authentication Errors**:
   - Verify the service account has the correct permissions
   - Check that the GCP_SA_KEY secret contains the complete JSON key

2. **Container Registry Issues**:
   - Ensure the Artifact Registry is created and service account has access
   - Check that the region matches in the GitHub Actions workflow

3. **Cloud Run Deployment Failures**:
   - View deployment logs in the GCP Console
   - Common errors include insufficient permissions or misconfigured containers

### Debugging:

1. Access the GitHub Actions logs to see detailed error messages
2. Use `gcloud` commands to check service status:
   ```bash
   gcloud run services describe tobira-mock --region=us-central1
   gcloud run services describe shinri-no-tobira --region=us-central1
   ```
3. Check container images:
   ```bash
   gcloud artifacts docker images list us-central1-docker.pkg.dev/YOUR_PROJECT_ID/tobira-containers
   ```