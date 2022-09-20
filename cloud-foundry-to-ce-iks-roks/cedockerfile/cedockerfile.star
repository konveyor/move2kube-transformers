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
def envListAsStr(envMapJson):
    envStr = ""
    if envMapJson == None:
        print("CEDocker: The environment map is None!")
        return envStr
    for env in envMapJson:
        if len(env["Value"]) > 0:
            envStr = envStr + "--env " + env["Name"] + "=\"" + env["Value"] + "\" "
    return envStr

# Convert byte array to string
def byteArrayToString(byteData):
    return "".join([chr(b) for b in byteData])

def convertMemToCeFormat(mem):
    memAsInt = int(mem[:-1])
    if memAsInt == 1024:
        mem = "1G"
    if memAsInt == 2*1024:
        mem = "2G"
    if memAsInt > 2*1024 and memAsInt <= 4*1024:
        mem = "4G"
    if memAsInt > 4*1024 and memAsInt <= 8*1024:
        mem = "8G"
    if memAsInt > 8*1024 and memAsInt <= 12*1024:
        mem = "12G"
    if memAsInt > 12*1024 and memAsInt <= 16*1024:
        mem = "16G"
    if memAsInt > 16*1024 and memAsInt <= 24*1024:
        mem = "24G"
    if memAsInt > 24*1024 and memAsInt <= 32*1024:
        mem = "32G"
    return mem

def transform(new_artifacts, old_artifacts):
    print('CEDockerfile Transformer invokation!')
    pathMappings = []
    artifacts = []
    regUrl = m2k.query({"id": "move2kube.target.imageregistry.url",
            "type": "Input",
            "description": "Enter the URL of the image registry where the new images should be pushed : "})
    namespace = m2k.query({"id": "move2kube.target.imageregistry.namespace",
            "type": "Input",
            "description": "Enter the namespace where the new images should be pushed : "})
    regSecret = m2k.query({"id": "move2kube.target.imageregistry.registrysecret",
            "type": "Input",
            "description": "Enter the name of the registry secret : "})
    minReplicas = m2k.query({"id": "move2kube.minreplicas",
                "type": "Input",
                "description": "Provide the minimum number of replicas each service should have : "})
    pathTemplate = "{{ SourceRel .ServiceFsPath }}"
    if new_artifacts == None:
        print('CEDocker Error: Artifact list is empty!')
        return {'pathMappings': pathMappings, 'artifacts': artifacts}
    for new_artifact in new_artifacts:
        d = {}
        vcapAsEnvSecretName = ""
        vcapAsEnvData = []
        d["RegistryURL"] = regUrl
        d["Namespace"] = namespace
        d["RegistrySecret"] = regSecret
        d["NumInstances"] = minReplicas
        serviceName = new_artifact["name"]
        servicePath = new_artifact['paths']['ServiceDirectories'][0]
        d["ServiceFsPath"] = servicePath
        d["ServiceName"] = serviceName
        pathTemplateName = serviceName.replace("-", "") + 'cedockerpath'
        tplPathData = {'ServiceFsPath': servicePath, \
                'PathTemplateName': pathTemplateName}
        pathMappings.append({'type': 'PathTemplate', \
                        'sourcePath': pathTemplate, \
                        'templateConfig': tplPathData})
        if "configs" in new_artifact.keys() and \
                "IR" in new_artifact["configs"] and \
                "services" in new_artifact["configs"]["IR"].keys() and \
                serviceName in new_artifact["configs"]["IR"]["services"].keys():
                if "storages" in new_artifact["configs"]["IR"]:
                    storages = new_artifact["configs"]["IR"]["storages"]
                    print('CEDocker: Number of storages --> ' + str(len(storages)))
                    for s in storages:
                        if s["storagetype"] == "Secret" and serviceName + "-vcapasenv" == s["name"]:
                            vcapAsEnvSecretName = s["name"]
                            if "content" in s: 
                                for key, val in s["content"].items():
                                    vcapAsEnvData.append({"name": key, "value": byteArrayToString(val)})
                            else:
                                print('CEDocker: VCAP Content is empty!')
                es = \
                    new_artifact["configs"]["IR"]["services"][serviceName]["Containers"][0]["Resources"]["Requests"]["ephemeral-storage"]
                if es != "0":
                    d["EphemeralStorage"] = " --es \"" + convertMemToCeFormat(es) + "\""
                mem = \
                    new_artifact["configs"]["IR"]["services"][serviceName]["Containers"][0]["Resources"]["Requests"]["memory"]
                if mem != "0":
                    d["Memory"] = " --memory \"" + convertMemToCeFormat(mem) + "\""
                d["EnvList"] = \
                envListAsStr(new_artifact["configs"]["IR"]["services"][serviceName]["Containers"][0]["Env"])
                if len(vcapAsEnvData) > 0:
                    d["VcapAsEnvData"] = vcapAsEnvData
                    d["VcapAsEnvSecretName"] = vcapAsEnvSecretName       
                    d['ServiceName'] = serviceName
                pathMappings.append({'type': 'Template', \
                    'sourcePath': "", \
                    'destinationPath': "source/{{ ." + pathTemplateName + " }}", \
                    'templateConfig': d})
                if len(vcapAsEnvData) == 0:
                    pathMappings.append({'type': 'Delete', \
                            'destinationPath': "{{ ." + pathTemplateName + " }}/secrets"})
    return {'pathMappings': pathMappings, 'artifacts': artifacts}