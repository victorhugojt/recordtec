# 1. First, get your VM's service account email
gcloud compute instances describe vm-backend \
  --zone=us-central1-a \
  --format="value(serviceAccounts[0].email)"

# 2. Grant Cloud SQL Client role to that service account
gcloud projects add-iam-policy-binding project-2c268745-0c2f-477a-b6a \
  --member="serviceAccount:270415419966-compute@developer.gserviceaccount.com" \
  --role="roles/cloudsql.client"

gcloud compute instances describe vm-backend \
  --zone=us-central1-a \
  --format="value(serviceAccounts[0].scopes)"


gcloud compute instances set-service-account vm-backend \
  --zone=us-central1-a \
  --scopes=https://www.googleapis.com/auth/cloud-platform


gcloud services enable sqladmin.googleapis.com --project=project-2c268745-0c2f-477a-b6als
