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
from parseio import parseIO
PomFile = "pom.xml"

# Performs the detection of pom file and extracts service name
def detect(inputPath):
    print('[DETECT] Input file: ' + inputPath)
    with open(inputPath) as f:
        data = f.read()
        detectInput = json.loads(data)
        print('[DETECT] Input data: ' + str(detectInput))
        services = {}
        for rootDir, _, fileList in os.walk(detectInput["InputDirectory"]):
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
    ioEnvNames = ['DETECT_INPUT_PATH', 'DETECT_OUTPUT_PATH']
    inputPath, outputPath = parseIO(ioEnvNames, "Detect")
    if len(inputPath) == 0:
        print('[Detect script] Input path is not specified in script')
        exit(0)
    if len(outputPath) == 0:
        print('[Detect script] Output path is not specified in script')
        exit(0)
    services = detect(inputPath)
    outDir = os.path.dirname(outputPath)
    os.mkdir(outDir)
    with open(outputPath, "w+") as f:
        json.dump(services, f)

if __name__ == '__main__':
    main()