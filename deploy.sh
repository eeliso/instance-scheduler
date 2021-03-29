#!/bin/sh

# Enable apis
gcloud services enable cloudbuild.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable sourcerepo.googleapis.com
gcloud services enable cloudscheduler.googleapis.com



# Create Service Accounts
gcloud iam service-accounts create instance-cost-saver \
    --description="Used to turn VM's on and off" \
    --display-name="instance-cost-saver"


gcloud iam service-accounts create instance-scheduler-auth \
    --description="Used to authenticate instance schedules" \
    --display-name="instance-scheduler-auth"


function_sa=$(gcloud iam service-accounts list --filter=instance-cost-saver --format="value(email)")
scheduler_sa=$(gcloud iam service-accounts list --filter=instance-scheduler-auth --format="value(email)")
project=$(gcloud config get-value project)
projectnumber=$(gcloud projects describe $project --format='value(projectNumber)')

# Add Custom Role permissions for the Service Account (start/stop instances in project)
gcloud iam roles create ComputeStartStop --project=$project \
  --file=startstop_role.yaml

gcloud projects add-iam-policy-binding $project \
    --member="serviceAccount:$function_sa" \
    --role="projects/$project/roles/ComputeStartStop"


# Ask for zone and instance to control (Add validation to both of these?)
echo "What zone is the VM you want to control in?: "
read zone
echo "What is the VM instance name you want to control?: "
read name

# Create functions for starting and stopping (http authenticated)
yes n | gcloud functions deploy start --entry-point start \
    --memory 128MB \
    --runtime python38 \
    --service-account $function_sa \
    --source $PWD/start/ \
    --trigger-http \
    --region europe-west1


yes n gcloud functions deploy stop --entry-point stop \
    --memory 128MB \
    --runtime python38 \
    --service-account $function_sa \
    --source $PWD/stop/ \
    --trigger-http \
    --region europe-west1

starturl=$(gcloud functions describe start --region europe-west1 --format="value(httpsTrigger.url)")
stopurl=$(gcloud functions describe stop --region europe-west1 --format="value(httpsTrigger.url)")

gcloud functions add-iam-policy-binding start \
    --region europe-west1 \
    --member serviceAccount:$scheduler_sa \
    --role roles/cloudfunctions.invoker

gcloud functions add-iam-policy-binding stop \
    --region europe-west1 \
    --member serviceAccount:$scheduler_sa \
    --role roles/cloudfunctions.invoker



# Create Scheduler jobs with asked variables in payload (application/json as type?)
gcloud scheduler jobs create http startcall \
    --schedule="0 9 * * 1-5" \
    --uri="$starturl" \
    --time-zone="Europe/Helsinki" \
    --message-body="{\"project\":\"$project\",\"zone\":\"$zone\",\"name\":\"$name\"}" \
    --oidc-service-account-email="$scheduler_sa"

gcloud scheduler jobs create http stopcall \
    --schedule="0 17 * * 1-5" \
    --uri="$stopurl" \
    --time-zone="Europe/Helsinki" \
    --message-body="{\"project\":\"$project\",\"zone\":\"$zone\",\"name\":\"$name\"}" \
    --oidc-service-account-email="$scheduler_sa"