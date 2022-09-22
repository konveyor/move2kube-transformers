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

    ## Q&A to fill the contract file
    usesVPC = m2k.query({"id": "move2kube.ibmvpc", "type": "Select", "description": "Do you use IBM VPC?", "hints": ["A VPC contract file will be created."], "options": ["Yes", "No"]})
    if usesVPC == "No":
        return {'pathMappings': pathMappings, 'artifacts': artifacts}

    confTypes = m2k.query({"id": "move2kube.ibmvpc.types", "type": "MultiSelect", "description": "Choose the types : ", "options": ["workload", "env"]})

    if len(confTypes) == 0:
        return {'pathMappings': pathMappings, 'artifacts': artifacts}

    data = {}

    configs = {}

    configs['VpcContractSec'] = {}


    for confType in confTypes:
        if confType == "env":
            logHostName = m2k.query({"id": "move2kube.ibmvpc.env.loghostname", "type": "Input", "description": "Enter the log DNA hostname : ", "default": ""})
            ingestionKey = m2k.query({"id": "move2kube.ibmvpc.env.ingestionkey", "type": "Input", "description": "Enter the ingestion key : ", "default": ""})
            logPortStr = m2k.query({"id": "move2kube.ibmvpc.env.logport", "type": "Input", "description": "Enter the log port : ", "default": "8080"})
            volumeCountStr = m2k.query({"id": "move2kube.ibmvpc.env.volumecount", "type": "Input", "description": "Enter the number of volumes : ", "default": "0"})
            volumeCount = int(volumeCountStr)
            volumes = {}

            for i in range(volumeCount):
                volumeName = m2k.query({"id": "move2kube.ibmvpc.env.volumes[%d].name" % (i), "type": "Input", "description": "Enter the volume %d name : " % (i+1), "default": ""})
                volumeSeed = m2k.query({"id": "move2kube.ibmvpc.env.volumes[%d].seed" % (i), "type": "Input", "description": "Enter the volume %d seed : " % (i+1), "default": ""})
                volumeMount = m2k.query({"id": "move2kube.ibmvpc.env.volumes[%d].mount" % (i), "type": "Input", "description": "Enter the volume %d mount : " % (i+1), "default": ""})
                volumeFS = m2k.query({"id": "move2kube.ibmvpc.env.volumes[%d].fs" % (i), "type": "Input", "description": "Enter the volume %d filesystem : " % (i+1), "default": ""})
                volume = {"mount": volumeMount, "seed": volumeSeed, "filesystem": volumeFS}
                volumes[volumeName] = volume

            data["EnvType"] = confType
            data["LogHostName"] = logHostName
            data["IngestionKey"] = ingestionKey
            data["LogPort"] = logPortStr
            data["EnvVolumes"] = volumes

            configs["VpcContractSec"]["envType"] = confType

        elif confType == "workload":
            authsCountStr = m2k.query({"id": "move2kube.ibmvpc.workload.authscount", "type": "Input", "description": "Enter the number of workloads : ", "default": "0"})
            authsCount = int(authsCountStr)
            auths = {}
            for i in range(authsCount):
                serviceAdress = m2k.query({"id": "move2kube.ibmvpc.workload.service[%d].address" % (i), "type": "Input", "description": "Enter the service %d address : " % (i+1), "default": ""})
                serviceUserName = m2k.query({"id": "move2kube.ibmvpc.env.service[%d].username" % (i), "type": "Input", "description": "Enter the username : ", "default": ""})
                servicePass = m2k.query({"id": "move2kube.ibmvpc.env.service[%d].pass" % (i), "type": "Input", "description": "Enter the password : ", "default": ""})
                auth = {"username": serviceUserName, "password": servicePass}
                auths[serviceAdress] = auth
            composeContent = m2k.query({"id": "move2kube.ibmvpc.workload.compose", "type": "MultiLineInput", "description": "Enter the docker compose file contents : ", "default": ""})
            fs.write(fs.path_join(temp_dir, "docker-compose.yaml"), composeContent)
            composeDigest = archive.arch_tar_gzip_str(fs.path_join(temp_dir, "docker-compose.yaml"))
            imagesCountStr = m2k.query({"id": "move2kube.ibmvpc.workload.imagescount", "type": "Input", "description": "Enter the number of images : ", "default": "0"})
            imagesCount = int(imagesCountStr)
            images = {}

            for i in range(imagesCount):
                registryAdress = m2k.query({"id": "move2kube.ibmvpc.workload.registry[%d].address" % (i), "type": "Input", "description": "Enter the image %d registry address : " % (i+1), "default": ""})
                registryNotary = m2k.query({"id": "move2kube.ibmvpc.env.registry[%d].notary" % (i), "type": "Input", "description": "Enter the image %d notary : " % (i+1), "default": ""})
                registryPublicKey = m2k.query({"id": "move2kube.ibmvpc.env.registry[%d].publickey" % (i), "type": "Input", "description": "Enter the image %d public key : " % (i+1), "default": ""})
                image = {"notary": registryNotary, "publicKey": registryPublicKey}
                images[registryAdress] = image

            workloadVolumeCountStr = m2k.query({"id": "move2kube.ibmvpc.workload.volumecount", "type": "Input", "description": "Enter the number of volumes : ", "default": "0"})
            workloadVolumeCount = int(workloadVolumeCountStr)
            
            workloadVolumes = {}

            for i in range(workloadVolumeCount):
                volumeName = m2k.query({"id": "move2kube.ibmvpc.workload.volumes[%d].name" % (i), "type": "Input", "description": "Enter the volume %d name : "% (i+1), "default": ""})
                volumeSeed = m2k.query({"id": "move2kube.ibmvpc.workload.volumes[%d].seed" % (i), "type": "Input", "description": "Enter the volume %d seed : " % (i+1), "default": ""})
                volumeMount = m2k.query({"id": "move2kube.ibmvpc.workload.volumes[%d].mount" % (i), "type": "Input", "description": "Enter the volume %d mount : " % (i+1), "default": ""})
                volumeFS = m2k.query({"id": "move2kube.ibmvpc.workload.volumes[%d].fs" % (i), "type": "Input", "description": "Enter the volume %d filesystem : " % (i+1), "default": ""})
                volume = {"mount": volumeMount, "seed": volumeSeed, "filesystem": volumeFS}
                workloadVolumes[volumeName] = volume

            workloadEnvsCountStr = m2k.query({"id": "move2kube.ibmvpc.workload.envcount", "type": "Input", "description": "Enter the number of environment variables : ", "default": "0"})
            workloadEnvsCount = int(workloadEnvsCountStr)

            workloadEnvs = {}

            for i in range(workloadEnvsCount):
                envKey = m2k.query({"id": "move2kube.ibmvpc.workload.envs[%d].key" % (i), "type": "Input", "description": "Enter the environment variable %d key : " % (i+1), "default": ""})
                envValue = m2k.query({"id": "move2kube.ibmvpc.workload.envs[%d].value" % (i), "type": "Input", "description": "Enter the environment variable %d value : " % (i+1), "default": ""})
                workloadEnvs[envKey] = envValue

            data["WorkloadType"] = confType
            data["Auths"] = auths
            data["composeDigest"] = composeDigest
            data["Images"] = images
            data["WorkloadVolumes"] = workloadVolumes
            data["WorkloadEnvs"] = workloadEnvs

            configs["VpcContractSec"]["workloadType"] = confType

    artifact = {'name': 'VpcContract', 'type': 'VpcContract', 'paths': {'VpcContract': [fs.path_join(output_dir, 'ibm_vpc_artifacts')]}, 'configs': configs}
    artifacts.append(artifact)
    pathMappings.append({'type': 'Template', 'templateConfig': data, 'destinationPath': 'ibm_vpc_artifacts/'})
    return {'pathMappings': pathMappings, 'artifacts': artifacts}
