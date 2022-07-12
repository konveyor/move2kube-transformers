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

# Creates the application using the resource and environment configuration.
# This command leverages cloud-native build-packs for building, pushing and deploying the app images
# Create a secret
{{ if .VcapAsEnvSecretName -}}
ibmcloud ce secret create --name {{ .VcapAsEnvSecretName }} --from-file TARGET=./secrets/vcapasenv-secret.txt
{{ end -}}

# Create the application
ibmcloud ce application create -w --wait-timeout 1800 --build-timeout 1800 --name {{ .ServiceName }}{{ if .Memory }}{{ .Memory }}{{ end }}{{ if .EphemeralStorage }}{{ .EphemeralStorage }}{{ end }} --min-scale {{ .NumInstances }} --src . {{ if .VcapAsEnvSecretName }} --env-sec {{ .VcapAsEnvSecretName }} {{ end }}