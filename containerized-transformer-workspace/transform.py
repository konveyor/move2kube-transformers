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

# Performs the transformation for the given service
def transform(artifactsPath):
    pathMappings = []
    artifacts = []
    with open(artifactsPath) as f:
        artifacts = json.load(f)
        for artifact in artifacts:
            # print('IN TRANSFORMER: ' + workspaceDir)
            # print('In transform method: ' + workspaceDir)
            pathTemplate = "{{ SourceRel .ServiceFsPath }}"
            serviceName = artifact["name"]
            serviceDirs = artifact['paths']['ServiceDirectories']
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
    services = transform(sys.argv[1])
    with open("./transformer.yaml") as fp:
        configData = yaml.safe_load(fp)
        containerCfg = configData['spec']['config']['container']
        if 'outputFilePath' in containerCfg:
            outputFilePath = containerCfg['outputFilePath']
            os.makedirs(os.path.dirname(outputFilePath))
            with open(outputFilePath, "w+") as f:
                json.dump(services, f)
        else:
            print('Error: Output file path not specified!')

if __name__ == '__main__':
    main()
