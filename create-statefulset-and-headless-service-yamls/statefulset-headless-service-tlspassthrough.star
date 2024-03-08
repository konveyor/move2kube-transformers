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

# transform creates a new artifact of type "KubernetesYamls" which
# has an annotation for ingress-class added to every ingress resource yaml created during
# transformation
def transform(new_artifacts, old_artifacts):
    pathMappings = []
    artifacts = []

    for a in new_artifacts:
        yamlsPath = a["paths"]["KubernetesYamls"][0]
        serviceName = a["name"]
        artifacts.append(a)

        fileList = fs.read_dir(yamlsPath)
        yamlsBasePath = yamlsPath.split("/")[-1]
        # Create a custom path template for the service, whose values gets filled and can be used in other pathmappings
        pathTemplateName = serviceName + yamlsBasePath
        pathTemplateName = pathTemplateName.replace("-", "")
        tplPathData = {'PathTemplateName': pathTemplateName}
        pathMappings.append({'type': 'PathTemplate', \
                            'sourcePath': "{{ OutputRel \"" + yamlsPath + "\" }}", \
                            'templateConfig': tplPathData})
        for f in fileList:
            filePath = fs.path_join(yamlsPath, f)
            s = fs.read_as_string(filePath)
            yamlData = yaml.loads(s)
            name = ""
            if 'metadata' in yamlData.keys():
                name = yamlData['metadata']['name']
            if yamlData['kind'] == 'Deployment':
                useStatefulSet = m2k.query({"id": "move2kube."+name +".statefulSet",
                                                "type": "Select",
                                                "options": ["Yes", "No"],
                                                "description": "Use StatefulSet instead of Deployment for the "+ name + " service : "})
                if useStatefulSet == "Yes":
                    yamlData['kind'] = 'StatefulSet'
                    if 'spec' in yamlData.keys():
                        if 'metadata' in yamlData.keys():
                            yamlData['spec']['serviceName'] = yamlData['metadata']['name']
                        yamlData['spec'] = {key: val for key,
                                    val in yamlData['spec'].items() if key != 'strategy'} 
                    if 'status' in yamlData.keys():
                        yamlData = {key: val for key,
                                            val in yamlData.items() if key != 'status'}
            if yamlData['kind'] == 'Service':
                useStatefulSet = m2k.query({"id": "move2kube."+name +".statefulSet",
                                                "type": "Select",
                                                "options": ["Yes", "No"],
                                                "description": "Use StatefulSet instead of Deployment for the "+ name + " service : "})
                if useStatefulSet == "Yes":
                    if 'spec' in yamlData.keys():
                        yamlData['spec'] = {key: val for key,
                                    val in yamlData['spec'].items() if key != 'type'}
                        yamlData['spec']['clusterIP'] = "None" 
            if yamlData['kind'] == 'Route':
                useTLSPassthrough = m2k.query({"id": "move2kube.tlspassthrough",
                                            "type": "Select",
                                            "options": ["Yes", "No"],
                                            "description": "Use passthrough termination in TLS in the Route files : "})
                if useTLSPassthrough == "Yes":
                    if 'spec' in yamlData.keys():
                        if 'tls' not in yamlData['spec']:
                            yamlData['spec']['tls'] = {}
                        yamlData['spec']['tls']['termination'] = "passthrough"
                        yamlData['spec'] = {key: val for key,
                                    val in yamlData['spec'].items() if key != 'path'}
                        yamlData['spec'] = {key: val for key,
                                    val in yamlData['spec'].items() if key != 'host'}
            s = yaml.dumps(yamlData)
            fs.write(filePath, s)
            pathMappings.append({'type': 'Default', \
                    'sourcePath': yamlsPath, \
                    'destinationPath': "{{ ." + pathTemplateName + " }}"})
        
    return {'pathMappings': pathMappings, 'artifacts': artifacts}
