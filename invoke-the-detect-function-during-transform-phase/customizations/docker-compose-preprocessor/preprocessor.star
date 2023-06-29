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

# Performs the detection of docker-compose files and .env files
def directory_detect(dir):
    dotEnvFilePaths = []
    envFilePaths = fs.get_files_with_pattern(filepath=source_dir, ext=".env")
    for envFilePath in envFilePaths:
        envFileName = fs.path_base(envFilePath)
        if envFileName == ".env":
            dotEnvFilePaths.append(envFilePath)
    composeYamlFilePaths = []
    yamlFilePaths = fs.get_files_with_pattern(filepath=source_dir, ext=".yaml")
    yamlFilePaths = yamlFilePaths + fs.get_files_with_pattern(
        filepath=source_dir, ext=".yml"
    )
    for yamlFilePath in yamlFilePaths:
        fileName = fs.path_base(yamlFilePath)
        if fileName == "docker-compose.yml" or fileName == "docker-compose.yaml":
            # print('Detected Docker-compose yaml file at path: ')
            # print(yamlFilePath)
            composeYamlFilePaths.append(yamlFilePath)
    return {
        "": [
            {
                "paths": {
                    "DockerCompose": composeYamlFilePaths,
                    "DotEnvFiles": dotEnvFilePaths,
                }
            }
        ]
    }


# Processes docker compose files and creates the configs for detected services
def transform(new_artifacts, old_artifacts):
    new_source_dir = "newsource"
    pathMappings = [
        {
            "type": "Source",
            "sourcePath" : "",
            "destinationPath": new_source_dir,
        }
    ]
    artifacts = []
    for new_artifact in new_artifacts:
        envVars = {}
        if "paths" not in new_artifact:
            continue
        if "DotEnvFiles" not in new_artifact["paths"]:
            continue
        if "DockerCompose" not in new_artifact["paths"]:
            continue

        # rewrite the .env files with environment valid variable names
        dotEnvFilePaths = new_artifact["paths"]["DotEnvFiles"]
        for dotEnvFilePath in dotEnvFilePaths:
            fileName = fs.path_base(dotEnvFilePath)
            tmpEnvFilePath = fs.path_join(temp_dir, fileName)
            d = []
            f = fs.read_as_string(dotEnvFilePath)
            lines = str(f).splitlines()
            for line in lines:
                data = line.split("=", 1)
                if len(data) < 2:
                    continue
                # replace hyphens with underscores in environment variable names
                d.append(data[0].replace("-", "_") + "=" + data[1])
                # keep track of all the environment variables we find
                vals = data[1].split('"')
                if len(vals) == 3:
                    envVars[data[0]] = vals[1]
                else:
                    envVars[data[0]] = vals[0]
            # fs.write(tmpEnvFilePath, "\n".join(d))
            fs.write(dotEnvFilePath, "\n".join(d))
        # print(envVars)

        # rewrite the docker-compose.yaml files with valid service names and valid environment variable names
        composeYamlFilePaths = new_artifact["paths"]["DockerCompose"]
        # print("docker-compose file paths:")
        # print(composeYamlFilePaths)
        for composeYamlFilePath in composeYamlFilePaths:
            fileName = fs.path_base(composeYamlFilePath)
            tmpFilePath = fs.path_join(temp_dir, fileName)
            # print("tmpFilePath")
            # print(tmpFilePath)
            data = fs.read_as_string(composeYamlFilePath)
            # print(data)
            newData = process_compose_file_data(data, envVars)
            print("newData")
            print(newData)
            new_compose_path = fs.path_join(temp_dir, "docker-compose.yaml")
            fs.write(new_compose_path, newData)

            invoke_detect_artifact = create_invoke_detect_artifact()
            artifacts.append(invoke_detect_artifact)
            dest_path = fs.path_join(new_source_dir, "docker-compose.yaml")
            pathMappings.append({
                "type": "Default",
                "sourcePath": new_compose_path,
                "destinationPath": dest_path,
            })
    return {"pathMappings": pathMappings, "artifacts": artifacts}


# Creates an artifact for the InvokeDetect transformer to consume
def create_invoke_detect_artifact():
    newArtifact = {
        "type": "InvokeDetect",
        "configs": {
            "InvokeDetect": {
                "transformerSelector": {
                    "matchLabels": {
                        "move2kube.konveyor.io/name": "ComposeAnalyser",
                    },
                },
            },
        },
        "paths": {
            "InvokeDetect": ["newsource"],
        },
    }
    return newArtifact


# Processes the docker compose file and makes it compatible for the ComposeAnalyser transformer
def process_compose_file_data(data, envVars):
    # rewrite with a valid service name
    if "ENV" in envVars:
        data = data.replace("frontend-${ENV}", "frontend-" + envVars["ENV"])

    # and valid environment variable names
    for old_name in envVars.keys():
        new_name = old_name.replace("-", "_")
        data = data.replace("${" + old_name + "}", "${" + new_name + "}")
        # if "_REPLICAS" in key:
        #     print(key)
        #     data = data.replace('${' + key + '}', envVars[key])
    return data
