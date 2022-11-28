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
import sys
import os
import json
import yaml
from parseio import parseIO
LogTag = "<TRANSFORM SCRIPT>"

# Performs the transformation for the given service
def transform(artifactsPath):
    pathMappings = []
    artifacts = []
    with open(artifactsPath) as f:
        data = f.read()
        artifactsData = json.loads(data)
        newArtifacts = artifactsData["newArtifacts"]
        print('%s Number of new artifacts: %d' % (LogTag, len(newArtifacts)))
        for artifact in newArtifacts:
            pathTemplate = "{{ SourceRel .ServiceFsPath }}"
            serviceName = artifact["name"]
            serviceDirs = artifact['paths']['ServiceDirectories']
            print(LogTag + ' Service Name: ' + serviceName)
            print(LogTag + ' Service Directories: ' + str(serviceDirs))
            if len(serviceDirs) > 0:
                # Create a path template for the service
                pathTemplateName = serviceName.replace("-", "") + 'path'
                tplPathData = {'ServiceFsPath': serviceDirs[0], 'PathTemplateName': pathTemplateName}
                pathMappings.append({'type': 'PathTemplate', \
                                    'sourcePath': pathTemplate, \
                                    'templateConfig': tplPathData})
                # Since the helm chart uses the same templating character {{ }} as Golang templates, 
                # we use `SpecialTemplate` type here where the templating character is <~ ~>.
                # The `Template` type can be used for all normal cases
                pathMappings.append({'type': 'SpecialTemplate', \
                            'destinationPath': "{{ ." + pathTemplateName + " }}", \
                            'templateConfig': {'ServiceName': serviceName}})
                pathMappings.append({'type': 'Source', \
                            'sourcePath': "{{ ." + pathTemplateName + " }}",
                            'destinationPath': "{{ ." + pathTemplateName + " }}"})

    return {'pathMappings': pathMappings, 'artifacts': artifacts}

# Entry-point of transform script
def main():
    ioEnvNames = ['M2K_TRANSFORM_INPUT_PATH', 'M2K_TRANSFORM_OUTPUT_PATH']
    inputPath, outputPath = parseIO(ioEnvNames, "<TRANSFORM SCRIPT>")
    services = transform(inputPath)
    outDir = os.path.dirname(outputPath)
    os.mkdir(outDir)
    with open(outputPath, "w+") as f:
        json.dump(services, f)

if __name__ == '__main__':
    main()
