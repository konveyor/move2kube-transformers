#   Copyright IBM Corporation 2021
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# Creates IBM VPC contract file
def transform(new_artifacts, old_artifacts):
    pathMappings = []
    artifacts = []

    # get certificate from assets folder
    ibmHyperProtectCert = fs.read(fs.path_join(resources_dir, "ibm-hyper-protect-container-runtime-1-0-s390x-4-encrypt.cer"))

    for new_artifact in new_artifacts:
        data = {}
        if "envType" in new_artifact["configs"]["VpcContractSec"].keys():
            envPass = m2k.query({"id": "move2kube.ibmvpc.env.password", "type": "Password", "description": "Enter the password for encryption of env(Private Key) : ", "hint": ["If ignored, encrypted contract file would be empty"], "default": ""})
            envData = fs.read(fs.path_join(new_artifact["paths"]["VpcContract"][0], 'env.yaml'))
            data["EnvData"] = envData
            data["EnvPass"] = envPass
        if "workloadType" in new_artifact["configs"]["VpcContractSec"].keys():
            workloadPass = m2k.query({"id": "move2kube.ibmvpc.workload.password", "type": "Password", "description": "Enter the password for encryption of workload (Private Key) : ", "hint": ["If ignored, encrypted contract file would be empty"], "default": ""})
            workloadData = fs.read(fs.path_join(new_artifact["paths"]["VpcContract"][0], 'workload.yaml'))
            data["WorkloadData"] = workloadData
            data["WorkloadPass"] = workloadPass
        data["IbmHyperProtectCert"] = ibmHyperProtectCert
        pathMappings.append({'type': 'Template', 'templateConfig': data, 'destinationPath': 'ibm_vpc_artifacts/'})
    return {'pathMappings': pathMappings, 'artifacts': artifacts}
