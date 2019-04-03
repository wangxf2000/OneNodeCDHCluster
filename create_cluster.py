import cm_client
from cm_client.rest import ApiException
from collections import namedtuple
from pprint import pprint
import json
import time
from __future__ import print_function

cm_client.configuration.username = 'admin'
cm_client.configuration.password = 'admin'
api_client = cm_client.ApiClient("http://localhost:7180/api/v32")

cm_api = cm_client.ClouderaManagerResourceApi(api_client)

# accept trial licence
cm_api.begin_trial()

# create hosts
# uhm, not sure but doesn't look necessary...

# create MGMT/CMS
mgmt = cm_client.MgmtServiceResourceApi(api_client)
body = cm_client.ApiService()

body.roles = [cm_client.ApiRole(type='SERVICEMONITOR'), 
    cm_client.ApiRole(type='HOSTMONITOR'), 
    cm_client.ApiRole(type='EVENTSERVER'),  
    cm_client.ApiRole(type='ALERTPUBLISHER')]

mgmt.auto_assign_roles() # needed?
mgmt.auto_configure()    # needed?
mgmt.setup_cms(body=body)
mgmt.start_command()

# create the cluster using the template
with open('OneNodeCluster_template.json') as in_file:
    json_str = in_file.read()

Response = namedtuple("Response", "data")
dst_cluster_template=api_client.deserialize(response=Response(json_str),response_type=cm_client.ApiClusterTemplate)
command = cm_api.import_cluster_template(body=dst_cluster_template)
