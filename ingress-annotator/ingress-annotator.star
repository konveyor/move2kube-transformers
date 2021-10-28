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
# load("encoding/yaml", "yaml")

# transform creates a new artifact of type "KubernetesYamlsWithAnnotatedIngress" which
# has an annotation for ingress-class added to every ingress resource yaml created during
# transformation
def transform(new_artifacts, old_artifacts):
    pathMappings = []
    artifacts = []
    for v in new_artifacts:
        if v["artifact"] != "KubernetesYamls":
            continue
        if v['name'] != "Kubernetes":
            continue
        v["artifact"] = "KubernetesYamlsWithAnnotatedIngress"
        artifacts.append(v)
        yamlsPath = v["paths"]["KubernetesYamls"][0]
        fileList = fs.readdir(yamlsPath)
        for f in fileList:
            filePath = fs.pathjoin(yamlsPath, f)
            s = fs.read(filePath)
            yamlData = yaml.loads(s)
            if yamlData['kind'] != 'Ingress':
                continue
            md = yamlData['metadata']
            d = {}
            if 'annotations' in md:
                d = md['annotations']
            d["kubernetes.io/ingress.class"] = "haproxy"
            md["annotations"] = d
            yamlData['metadata'] = md
            s = yaml.dumps(yamlData)
            fs.write(filePath, s)
            pathMappings.append({'type': 'Default', \
            'sourcePath': yamlsPath, \
            'destinationPath': fs.pathjoin("deploy", "yamls")})
        
    return {'pathMappings': pathMappings, 'artifacts': artifacts}