import googleapiclient.discovery
from flask import request


def stop(request):
    request_json = request.get_json(force=True)
    compute = googleapiclient.discovery.build('compute', 'v1')
    projectid=request_json['project']
    gcpzone=request_json['zone']
    name=request_json['name']
    return compute.instances().stop(project=projectid,zone=gcpzone,instance=name).execute()