#!/bin/bash

SERVICE_NAME="backend2"        
REGION="europe-west1"          
PROJECT_ID="aliveshot-d816e"   

echo "Deploying Cloud Run service from source..."
gcloud run deploy $SERVICE_NAME \
  --source . \
  --region $REGION \
  --project $PROJECT_ID \
  --allow-unauthenticated

echo "Deploy complete!"
