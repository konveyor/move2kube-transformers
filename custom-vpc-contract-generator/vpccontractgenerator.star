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

def directory_detect(dir):
    fileList = fs.get_files_with_pattern(dir, '.yaml')
    print(fileList)
    for fPath in fileList:
        fName = fs.path_base(fPath)
        fDir = fPath[:-len(fName)]
        if fPath.endswith('docker-compose.yaml'):
            return  {"": [{
                "paths": {"DockerComposeDir": [fDir]} }
            ]}
        data = fs.read(fPath)
        if data.startswith('version: "3'):
            return  {"": [{
                "paths": {"DockerComposeDir": [fDir]} }
            ]}

# Creates IBM VPC contract file
def transform(new_artifacts, old_artifacts):
    pathMappings = []
    artifacts = []

    dcPath = ''
    print('new_artifacts', new_artifacts)
    if len(new_artifacts) > 0:
        # print('no new artifacts provided')
        # return {'pathMappings': pathMappings, 'artifacts': artifacts}
        if len(new_artifacts) > 1:
            print('more than one artifact, ignoring everything but the first one')
        new_artifact = new_artifacts[0]
        print('using the new artifact:', new_artifact)
        dcPaths = new_artifact['paths']['DockerComposeDir']
        if len(dcPaths) == 0:
            print('no docker compose directories provided')
            return {'pathMappings': pathMappings, 'artifacts': artifacts}
        if len(dcPaths) > 1:
            print('more than one docker compose dir, ignoring everything but the first one')
        dcPath = dcPaths[0]
        print('using the docker compose directory:', dcPath)

    ## Q&A to fill the contract file
    usesVPC = m2k.query({"id": "move2kube.ibmvpc.enabled", "type": "Select", "description": "Do you use IBM VPC?", "hints": ["A VPC contract file will be created."], "options": ["Yes", "No"]})
    if usesVPC == "No":
        return {'pathMappings': pathMappings, 'artifacts': artifacts}

    confTypes = m2k.query({"id": "move2kube.ibmvpc.types", "type": "MultiSelect", "description": "Choose the types : ", "options": ["workload", "env"]})

    if len(confTypes) == 0:
        return {'pathMappings': pathMappings, 'artifacts': artifacts}

    data = {}

    configs = {}

    configs['VpcContractSec'] = {}

    volumeNames = []
    

    for confType in confTypes:
        if confType == "env":
            loggingOption = m2k.query({"id": "move2kube.ibmvpc.env.loggingoption", "type": "Select", "description": "Choose a logging backend : ", "options": ["LogDNA", "SysLog"]})
            if loggingOption == "LogDNA":
                logDnaHostName = m2k.query({"id": "move2kube.ibmvpc.env.logdnahostname", "type": "Input", "description": "Enter the log DNA hostname : ", "default": ""})
                logDnaIngestionKey = m2k.query({"id": "move2kube.ibmvpc.env.logdnaingestionkey", "type": "Input", "description": "Enter the ingestion key : ", "default": ""})
                logDNAPortStr = m2k.query({"id": "move2kube.ibmvpc.env.logdnaport", "type": "Input", "description": "Enter the log port : ", "default": "6514"})
                data["LogDNAHostName"] = logDnaHostName
                data["LogDNAIngestionKey"] = logDnaIngestionKey
                data["LogDNAPort"] = logDNAPortStr
                data["LogDNA"] = loggingOption
            else:
                sysLogHostName = m2k.query({"id": "move2kube.ibmvpc.env.sysloghostname", "type": "Input", "description": "Enter the sysLog hostname : ", "default": ""})
                sysLogServer = m2k.query({"id": "move2kube.ibmvpc.env.syslogserver", "type": "Input", "description": "Enter the sysLog server : ", "default": ""})
                sysLogPort = m2k.query({"id": "move2kube.ibmvpc.env.syslogport", "type": "Input", "description": "Enter the sysLog log port : ", "default": "514"})
                sysLogCert = m2k.query({"id": "move2kube.ibmvpc.env.syslogcert", "type": "MultiLineInput", "description": "Enter the sysLog cert : ", "default": ""})
                sysLogKey = m2k.query({"id": "move2kube.ibmvpc.env.syslogkey", "type": "MultiLineInput", "description": "Enter the sysLog key : ", "default": ""})
                data["SysLogHostName"] = sysLogHostName
                data["SysLogServer"] = sysLogServer
                data["SysLogPort"] = sysLogPort
                data["SysLogCert"] = sysLogCert
                data["SysLogKey"] = sysLogKey
                data["SysLog"] = loggingOption
            volumes = {}
            for volumneName in volumeNames:
                volumeSeed = m2k.query({"id": "move2kube.ibmvpc.env.volumes.[%d].seed" % (i), "type": "Input", "description": "Enter the volume %d seed : " % (i+1), "default": ""})
                volume = {"seed": volumeSeed}
                volumes[volumeName] = volume

            envEnvsCountStr = m2k.query({"id": "move2kube.ibmvpc.env.envcount", "type": "Input", "description": "Enter the number of environment variables : ", "default": "0"})
            envEnvsCount = int(envEnvsCountStr)

            envEnvs = {}

            for i in range(envEnvsCount):
                envKey = m2k.query({"id": "move2kube.ibmvpc.env.envs.[%d].key" % (i), "type": "Input", "description": "Enter the environment variable %d key : " % (i+1), "default": ""})
                envValue = m2k.query({"id": "move2kube.ibmvpc.env.envs.[%d].value" % (i), "type": "Input", "description": "Enter the environment variable %d value : " % (i+1), "default": ""})
                envEnvs[envKey] = envValue
            data["EnvType"] = confType
            data["EnvVolumes"] = volumes
            data["EnvEnvs"] = envEnvs

            configs["VpcContractSec"]["envType"] = confType

        elif confType == "workload":
            authsCountStr = m2k.query({"id": "move2kube.ibmvpc.workload.authscount", "type": "Input", "description": "Enter the number of container registry auths : ", "default": "0"})
            authsCount = int(authsCountStr)
            auths = {}
            for i in range(authsCount):
                serviceAdress = m2k.query({"id": "move2kube.ibmvpc.workload.service.[%d].address" % (i), "type": "Input", "description": "Enter the hostname of the container registry %d  : " % (i+1), "default": ""})
                serviceUserName = m2k.query({"id": "move2kube.ibmvpc.env.service.[%d].username" % (i), "type": "Input", "description": "Enter the username : ", "default": ""})
                servicePass = m2k.query({"id": "move2kube.ibmvpc.env.service.[%d].pass" % (i), "type": "Password", "description": "Enter the password : "})
                auth = {"username": serviceUserName, "password": servicePass}
                auths[serviceAdress] = auth

            composeDigest = ''
            if len(dcPath) > 0:
                print('using the existing docker compose directory:', dcPath)
                composeDigest = archive.arch_tar_gzip_str(dcPath)
            else:
                print('did not find an existing docker compose file. Asking the user instead')
                composeContent = m2k.query({"id": "move2kube.ibmvpc.workload.compose", "type": "MultiLineInput", "description": "Enter the docker compose file contents : ", "default": "version: \"3.0\"\nservices:\nvolumes:"})
                fs.write(fs.path_join(temp_dir, "docker-compose.yaml"), composeContent)
                composeDigest = archive.arch_tar_gzip_str(fs.path_join(temp_dir, "docker-compose.yaml"))
            print('composeDigest', composeDigest)

            dctImagesCountStr = m2k.query({"id": "move2kube.ibmvpc.workload.dctimagescount", "type": "Input", "description": "Enter the number of images signed using dct: ", "default": "0"})
            dctImagesCount = int(dctImagesCountStr)
            dctImages = {}

            for i in range(dctImagesCount):
                registryAdress = m2k.query({"id": "move2kube.ibmvpc.workload.dctregistry.[%d].address" % (i), "type": "Input", "description": "Enter the image %d registry address : " % (i+1), "default": ""})
                registryNotary = m2k.query({"id": "move2kube.ibmvpc.env.dctregistry.[%d].notary" % (i), "type": "Input", "description": "Enter the image %d notary : " % (i+1), "default": ""})
                registryPublicKey = m2k.query({"id": "move2kube.ibmvpc.env.dctregistry.[%d].publickey" % (i), "type": "Input", "description": "Enter the image %d public key : " % (i+1), "default": ""})
                image = {"notary": '"'+registryNotary+'"', "publicKey": registryPublicKey}
                dctImages[registryAdress] = image


            workloadVolumes = {}
            if len(confTypes) != 0:
                volumeCountStr = m2k.query({"id": "move2kube.ibmvpc.volumes.volumecount", "type": "Input", "description": "Enter the number of volumes : ", "default": "0"})
                volumeCount = int(volumeCountStr)
                for i in range(volumeCount):
                    volumeName = m2k.query({"id": "move2kube.ibmvpc.volumes.[%d].name" % (i), "type": "Input", "description": "Enter the volume %d name : " % (i+1), "default": ""})
                    volumeNames.append(volumeName)

            for volumeName in volumeNames:
                volume = {}
                volumeSeed = m2k.query({"id": "move2kube.ibmvpc.workload.volumes.[%d].seed" % (i), "type": "Input", "description": "Enter the volume %d seed : " % (i+1), "default": ""})
                volume["seed"] = volumeSeed
                volumeMount = m2k.query({"id": "move2kube.ibmvpc.workload.volumes.[%d].mount" % (i), "type": "Input", "description": "Enter the volume %d mount : " % (i+1), "default": ""})
                if volumeMount != "":
                    volume["mount"] = volumeMount
                volumeFS = m2k.query({"id": "move2kube.ibmvpc.workload.volumes.[%d].fs" % (i), "type": "Input", "description": "Enter the volume %d filesystem : " % (i+1), "default": ""})
                if volumeFS != "":
                    volume["filesystem"] = volumeFS
                workloadVolumes[volumeName] = volume

            workloadEnvsCountStr = m2k.query({"id": "move2kube.ibmvpc.workload.envcount", "type": "Input", "description": "Enter the number of environment variables : ", "default": "0"})
            workloadEnvsCount = int(workloadEnvsCountStr)

            workloadEnvs = {}

            for i in range(workloadEnvsCount):
                envKey = m2k.query({"id": "move2kube.ibmvpc.workload.envs.[%d].key" % (i), "type": "Input", "description": "Enter the environment variable %d key : " % (i+1), "default": ""})
                envValue = m2k.query({"id": "move2kube.ibmvpc.workload.envs.[%d].value" % (i), "type": "Input", "description": "Enter the environment variable %d value : " % (i+1), "default": ""})
                workloadEnvs[envKey] = envValue

            data["WorkloadType"] = confType
            data["Auths"] = auths
            data["composeDigest"] = composeDigest
            data["dctImages"] = dctImages
            data["WorkloadVolumes"] = workloadVolumes
            data["WorkloadEnvs"] = workloadEnvs

            configs["VpcContractSec"]["workloadType"] = confType
    if not "WorkloadType" in data:
        pathMappings.append({'type': 'Delete', 'destinationPath': 'ibm_vpc_artifacts/workload.yaml'})
    if not "EnvType" in data:
        pathMappings.append({'type': 'Delete', 'destinationPath': 'ibm_vpc_artifacts/env.yaml'})

    artifact = {'name': 'VpcContract', 'type': 'VpcContract', 'paths': {'VpcContract': [fs.path_join(output_dir, 'ibm_vpc_artifacts')]}, 'configs': configs}
    artifacts.append(artifact)
    pathMappings.append({'type': 'Template', 'templateConfig': data, 'destinationPath': 'ibm_vpc_artifacts/'})
    return {'pathMappings': pathMappings, 'artifacts': artifacts}
