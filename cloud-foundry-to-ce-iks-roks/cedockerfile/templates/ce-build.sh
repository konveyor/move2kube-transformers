#!/usr/bin/env bash
#   Copyright IBM Corporation 2020
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
# Create a secret
{{ if .VcapAsEnvSecretName -}}
ibmcloud ce secret create --name {{ .VcapAsEnvSecretName }} --from-file TARGET=./secrets/vcapasenv-secret.txt
{{ end -}}

# Create the build profile
ibmcloud ce build create --name {{ .ServiceName }}-build-local --build-type local --image {{ .RegistryURL }}/{{ .Namespace }}/{{ .ServiceName }} --registry-secret {{ .RegistrySecret }}

# Submit the build
ibmcloud ce buildrun submit -w --wait-timeout 1800 --timeout 1800 --name {{ .ServiceName }}-buildrun-local --build {{ .ServiceName }}-build-local --source . 

# Creates the application using the image created above, and given resource, environment configuration.
ibmcloud ce application create --name {{ .ServiceName }} --visibility project --registry-secret {{ .RegistrySecret }} --image {{ .RegistryURL }}/{{ .Namespace }}/{{ .ServiceName }}{{ if .Memory }}{{ .Memory }}{{ end }}{{ if .EphemeralStorage }}{{ .EphemeralStorage }}{{ end }}{{ if .EphemeralStorage }} --min-scale {{ .NumInstances }}{{ end }}{{ if .VcapAsEnvSecretName }} --env-sec {{ .VcapAsEnvSecretName }} {{ end }}
