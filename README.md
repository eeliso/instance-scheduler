Automating Google Cloud Platform VM's starts and stops
---------------

The solution does the following:
1. Creates a Service Account for the Cloud Functions with minimal custom role to turn and turn off VM's in a project.
2. Creates a Service account for Cloud Scheduler to authenticate to the function
3. Gives the needed permissions for both service accounts (custom role and cloud functions invoker)
4. Deploys HTTP Cloud Functions for starting and stopping instances that only work when the call is authenticated
5. Creates Cloud Scheduler Jobs that send the payload information about the instance being targeted by the start or stop function.

To run deploy.sh, first git clone this repository to a local folder.