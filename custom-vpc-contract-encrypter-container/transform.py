#   Copyright IBM Corporation 2023
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

import os
import json
from parseio import parseIO
import subprocess
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
        for new_artifact in newArtifacts:
            data = {}
            filenames = next(os.walk(new_artifact["paths"]["VpcContract"][0]), (None, None, []))[2]
            print(filenames)
            print(new_artifact)
            filenames = next(os.walk("./"), (None, None, []))
            print(filenames)
            if "envType" in new_artifact["configs"]["VpcContractSec"].keys():
                with open(os.path.join(new_artifact["paths"]["VpcContract"][0], 'env.yaml'), 'r') as file: 
                    envData = file.read()
                    data["EnvData"] = envData
                    # cmd_env = {"ENV": os.path.join(new_artifact["paths"]["VpcContract"][0], 'env.yaml')}
                    # data["EnvEncryptedData"] = subprocess.check_output(["sh", "env.sh"], env=cmd_env)
                    os.environ["ENV"] = os.path.join(new_artifact["paths"]["VpcContract"][0], 'env.yaml')
                    data["EnvEncryptedData"] = os.popen("sh env.sh").read()[:-1]
            if "workloadType" in new_artifact["configs"]["VpcContractSec"].keys():
                with open(os.path.join(new_artifact["paths"]["VpcContract"][0], 'workload.yaml'), 'r') as file: 
                    workloadData = file.read()
                    data["WorkloadData"] = workloadData
                    # cmd_env = {"WORKLOAD": os.path.join(new_artifact["paths"]["VpcContract"][0], 'workload.yaml')}
                    # data["WorkloadEncryptedData"] = subprocess.check_output(["sh", "workload.sh"], env=cmd_env)
                    os.environ["WORKLOAD"] = os.path.join(new_artifact["paths"]["VpcContract"][0], 'workload.yaml')
                    data["WorkloadEncryptedData"] = os.popen("sh workload.sh").read()[:-1]
            if not ("EnvData" in data or "WorkloadData" in data):
                pathMappings.append({'type': 'Delete', 'destinationPath': 'ibm_vpc_artifacts/user-data.yaml'})
            pathMappings.append({'type': 'Template', 'templateConfig': data, 'destinationPath': 'ibm_vpc_artifacts/'})
    return {'pathMappings': pathMappings, 'artifacts': artifacts}

# Entry-point of transform script
def main():
    ioEnvNames = ['M2K_TRANSFORM_INPUT_PATH', 'M2K_TRANSFORM_OUTPUT_PATH']
    inputPath, outputPath = parseIO(ioEnvNames, "<TRANSFORM SCRIPT>")
    print(inputPath, outputPath)
    services = transform(inputPath)
    outDir = os.path.dirname(outputPath)
    os.makedirs(outDir)
    with open(outputPath, "w+") as f:
        json.dump(services, f)

if __name__ == '__main__':
    main()