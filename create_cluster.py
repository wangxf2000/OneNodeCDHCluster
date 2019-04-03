from __future__ import print_function
import cm_client
from cm_client.rest import ApiException
from collections import namedtuple
from pprint import pprint
import json
import time

cm_client.configuration.username = 'admin'
cm_client.configuration.password = 'admin'
api_client = cm_client.ApiClient("http://localhost:7180/api/v32")

cm_api = cm_client.ClouderaManagerResourceApi(api_client)

# accept trial licence
cm_api.begin_trial()

# create hosts
#hosts_api = cm_client.HostsResourceApi(api_client)
#api_host_list = cm_client.ApiHostList([cm_client.ApiHost(hostname='YourHostName', ip_address='YourHostIpAddress')])
#hosts_api.create_hosts(body=api_host_list)

instargs = cm_client.ApiHostInstallArguments(host_names=['fab.ue2v4pwgnmtevd3wmxx0ndpkka.bx.internal.cloudapp.net'], 
                                             user_name='root', 
                                             private_key=YourPrivateKey, 
                                             cm_repo_url='https://archive.cloudera.com/cm6/6.2.0', 
                                             java_install_strategy='NONE', 
                                             ssh_port=22, 
                                             passphrase='')

cm_api.host_install_command(body=instargs)

# create MGMT/CMS
mgmt_api = cm_client.MgmtServiceResourceApi(api_client)
api_service = cm_client.ApiService()

api_service.roles = [cm_client.ApiRole(type='SERVICEMONITOR'), 
    cm_client.ApiRole(type='HOSTMONITOR'), 
    cm_client.ApiRole(type='EVENTSERVER'),  
    cm_client.ApiRole(type='ALERTPUBLISHER')]

mgmt_api.auto_assign_roles() # needed?
mgmt_api.auto_configure()    # needed?
mgmt_api.setup_cms(body=api_service)
mgmt_api.start_command()

# create the cluster using the template
with open('OneNodeCluster_template.json') as in_file:
    json_str = in_file.read()

Response = namedtuple("Response", "data")
dst_cluster_template=api_client.deserialize(response=Response(json_str),response_type=cm_client.ApiClusterTemplate)
command = cm_api.import_cluster_template(body=dst_cluster_template)
