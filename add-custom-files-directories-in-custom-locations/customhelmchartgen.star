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
PomFile = "pom.xml"

# Performs the detection of pom file and extracts service name
def directory_detect(dir):
    dataFilePath = fs.path_join(dir, PomFile)
    if fs.exists(dataFilePath):
        serviceName = getServiceName(dataFilePath)
        return  {serviceName: [{
                    "paths": {"ProjectPath": [dir]} }] }

# Creates the customized helm chart for every service
def transform(new_artifacts, old_artifacts):
    pathMappings = []
    artifacts = []
    pathTemplate = "{{ SourceRel .ServiceFsPath }}"
    for v in new_artifacts:
        serviceName = v["configs"]["Service"]["serviceName"]
        dir = v['paths']['ProjectPath'][0]
        # Create a path template for the service
        pathTemplateName = serviceName.replace("-", "") + 'path'
        tplPathData = {'ServiceFsPath': dir, 'PathTemplateName': pathTemplateName}
        pathMappings.append({'type': 'PathTemplate', \
                            'sourcePath': pathTemplate, \
                            'templateConfig': tplPathData})
        # Since the helm chart uses the same templating character {{ }} as Golang templates, 
        # we use `SpecialTemplate` type here where the templating character is <~ ~>.
        # The `Template` type can be used for all normal cases
        pathMappings.append({'type': 'SpecialTemplate', \
                    'destinationPath': "{{ ." + pathTemplateName + " }}", \
                    'templateConfig': {'ServiceFsPath': dir, 'ServiceName': serviceName}})
        pathMappings.append({'type': 'Source', \
                    'sourcePath': "{{ ." + pathTemplateName + " }}",
                    'destinationPath': "{{ ." + pathTemplateName + " }}"})

    return {'pathMappings': pathMappings, 'artifacts': artifacts}

# Extracts service name from pom file
def getServiceName(filePath):
    data = fs.read(filePath)
    lines = data.splitlines()
    for l in lines:
        if re.search("^[\t]<artifactId", l):
            t = l.split('>')
            t2 = t[1].split('<')
            return t2[0]
