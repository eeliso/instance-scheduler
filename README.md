Automating Google Cloud Platform VM's starts and stops
---------------

The solution does the following:
1. Creates a Service Account for the Cloud Functions with minimal custom role to turn and turn off VM's in a project.
2. Deploys HTTP Cloud Functions for starting and stopping instances that only work when the call is authenticated
3. Creates Cloud Scheduler Jobs that send the payload information about the instance being targeted by the start or stop function.