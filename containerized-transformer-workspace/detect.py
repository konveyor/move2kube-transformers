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
import xml.etree.ElementTree as ET
PomFile = "pom.xml"

# Performs the detection of pom file and extracts service name
def detect(workspaceDir):
    services = {}
    for rootDir, _, fileList in os.walk(workspaceDir):
            for fileName in fileList:
                if fileName != PomFile:
                    continue
                fullFilePath = os.path.join(rootDir, fileName)
                pomTree = ET.parse(fullFilePath)
                pomRoot = pomTree.getroot()
                for a in pomRoot:
                    if 'artifactId' in a.tag:
                        services[a.text] = [{
                        "paths": {"ServiceDirectories": [rootDir]} }]
                        break
    return services

# Entry-point of detect script
def main():
    services = detect(sys.argv[1])
    print(json.dumps(services))

if __name__ == '__main__':
    main()