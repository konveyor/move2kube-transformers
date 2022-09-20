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
        print("CECNB Error: The environment map is None!!!")
        return envStr
    for env in envMapJson:
        if len(env["Value"]) > 0:
            envStr = envStr + "--env " + env["Name"] + "=\"" + env["Value"] + "\" "
    return envStr

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

# Convert byte array to string
def byteArrayToString(byteData):
    return "".join([chr(b) for b in byteData])

def transform(new_artifacts, old_artifacts):
    tgtDir = "source-ce-push/"
    pathMappings = []
    artifacts = []
    pathTemplate = "{{ SourceRel .ServiceFsPath }}"
    if new_artifacts == None:
        print('CECNB Error: Artifact list is empty!!!')
        return {'pathMappings': pathMappings, 'artifacts': artifacts}
    for new_artifact in new_artifacts:
        d = {}
        serviceName = new_artifact["name"]
        servicePath = new_artifact['paths']['ServiceDirectories'][0]
        vcapAsEnvSecretName = ""
        vcapAsEnvData = []
        if "configs" in new_artifact.keys() and \
            "IR" in new_artifact["configs"] and \
            "services" in new_artifact["configs"]["IR"].keys() and \
            serviceName in new_artifact["configs"]["IR"]["services"].keys():
            if "storages" in new_artifact["configs"]["IR"]:
                storages = new_artifact["configs"]["IR"]["storages"]
                for s in storages:
                    if s["storagetype"] == "Secret" and serviceName + "-vcapasenv" == s["name"]:
                        vcapAsEnvSecretName = s["name"]
                        if "content" in s: 
                            for key, val in s["content"].items():
                                vcapAsEnvData.append({"name": key, "value": byteArrayToString(val)})
                        else:
                            print('CECNB: VCAP Content is empty!!')
            d["ServiceName"] = serviceName
            d["ServiceFsPath"] = servicePath
            pathTemplateName = serviceName.replace("-", "") + 'cecnbpath'
            tplPathData = {'ServiceFsPath': servicePath, \
                        'PathTemplateName': pathTemplateName}
            pathMappings.append({'type': 'PathTemplate', \
                                'sourcePath': pathTemplate, \
                                'templateConfig': tplPathData})
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
            d["NumInstances"] = new_artifact["configs"]["IR"]["services"][serviceName]["Replicas"]
            if len(vcapAsEnvData) > 0:
                d["VcapAsEnvData"] = vcapAsEnvData
                d["VcapAsEnvSecretName"] = vcapAsEnvSecretName       
                d['ServiceName'] = serviceName
            pathMappings.append({'type': 'Template', \
                'destinationPath': tgtDir + "{{ ." + pathTemplateName + " }}", \
                'templateConfig': d})
            pathMappings.append({'type': 'Source', \
                    'sourcePath': "{{ ." + pathTemplateName + " }}",
                    'destinationPath': tgtDir + "{{ ." + pathTemplateName + " }}"})
            if len(vcapAsEnvData) == 0:
                pathMappings.append({'type': 'Delete', \
                            'destinationPath': tgtDir + "{{ ." + pathTemplateName + " }}/secrets"})
    return {'pathMappings': pathMappings, 'artifacts': artifacts}