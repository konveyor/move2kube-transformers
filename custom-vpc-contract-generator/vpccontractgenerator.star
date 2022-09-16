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

# Creates IBM VPC contract file
def transform(new_artifacts, old_artifacts):
    ibmHyperProtectCert = """
-----BEGIN CERTIFICATE-----
MIIF8TCCA9mgAwIBAgIQLKNAizePV1jGkvBknjjfOzANBgkqhkiG9w0BAQ0FADCB
0TELMAkGA1UEBhMCREUxGzAZBgNVBAgMEkJhZGVuLVfDvHJ0dGVtYmVyZzETMBEG
A1UEBwwKQsO2YmxpbmdlbjE0MDIGA1UECgwrSUJNIERldXRzY2hsYW5kIFJlc2Vh
cmNoICYgRGV2ZWxvcG1lbnQgR21iSDEkMCIGA1UECxMbSUJNIFogSHlicmlkIENs
b3VkIFBsYXRmb3JtMTQwMgYDVQQDDCtJQk0gRGV1dHNjaGxhbmQgUmVzZWFyY2gg
JiBEZXZlbG9wbWVudCBHbWJIMB4XDTIyMDkwMjE2NTc0N1oXDTQyMDkwMjE2NTc1
N1owgZYxCzAJBgNVBAYTAkRFMQswCQYDVQQIEwJCVzETMBEGA1UEBxMKQm9lYmxp
bmdlbjEhMB8GA1UECgwYSUJNIERldXRzY2hsYW5kIFImRCBHbWJIMSQwIgYDVQQL
ExtJQk0gWiBIeWJyaWQgQ2xvdWQgUGxhdGZvcm0xHDAaBgNVBAMTE2NvbnRyYWN0
LWRlY3J5cHRpb24wggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDI9Jx9
NXPsbONFVqIsXfzB/4WI4Kj070AxveF8QHTMb8mQ8KOD5ZDs6Ug1fli2JbxFPfvK
oFD0v1FNsxBhjWHAkq8LpeIzrG0YVLmDcjQqEaJQd58YK8GygOLy7qoRMedsVr2X
+MIqxJda06tc/O3GrM4swZRQVh7I0BHB9cJ3mLbh7St3vmhBpNZt9EKIgTJUGFUH
gTpeZuh2AjOcKsdrbzfGcs+4q1CstVNZ9eECVc27JPAzzrfzS8ZRlLJPOVEVDj1Z
gs3rA36eTxRMC0XuJC+mgKASJsFKygYQmfbs1mzIN0oIzsewjHM6AywuJ21Srjaq
gMSaRKzfpnMELJqWpIKFDGjj+p6anp8zJPYQy9IrOG8ifgCg+LhVGQ6mx3xMgY3m
H9Mwcto/ox6mkLf/7JYWK2RoAZEJRuojuMpOfeOLEkkzkBgzgD2JLh2ps+Zc7YxE
I9O02vMHUHhamqLyjD1OOBUBbYQ+W+28svbMgr3m5F8ILzXVWTnT6+h6WStXhLbk
zUIsAWconRt6g3A6Y9UCeK252j3ITjKPlcduICZkkcnaj73VDACRmoOVBPrnb2Ex
YfXhibBlwPcGyUV+GwlZgs5IN+X8GIU0I6QFFUUh3+BhgbVu8Rei0CKl52aRyFTe
w9wo0abntwYLQlovZLNsPtMeZIGO/P37IMelGwIDAQABMA0GCSqGSIb3DQEBDQUA
A4ICAQAgBhbamlqQlOYNgyOOPnuDNRe/LEshv+yeHS5Yqjgb/o5WzhHQNla6kQpD
TgbYvF70Qkj3agSH6+M6C+mmdgzGNQOWhnPBPtDiySOn8BvlhIvcsOz/OQyIi0Se
4vqiKPQmGUJ9aZCmzmkKbzUIpWJZy8XOcG15a5lW1OIDIVl7qRehZDQ0MqhYk5yQ
hXG/0o50APhSJ3fN6ulcdP/BfMGQmHs3fRHiaOMxJvJC/obUSDCgDIrBodAk2GvW
8aKEu2yRS1RoespumrkB621eULWhTQ//M31JlvBSo5daulOcjfBeCmGcQGQFJs45
hsTkLfltYf6nkFxzrjPvaRMT9xGmXFUkMrr163P2f0ngDp2BopqAGaVT/yD4llOs
Li5o5ZEcSOhILypa141pGwDBK/7IGv35zicO39VlpKsF/sRej4xPMkZOSlBSAgQf
oDJ6NLx69TtmcDpz0nU9y4yjZQDWj2CiG8yK5Lr9ayq8ayOneJr3Krh0bJ43izD2
19UeNHaQrN94ylMNAyNB+2QrOtkAYuu0XKYuEDYaKx5V9w0Oodc2RJVZVt4PeHyY
BxB0v4gNdfr/ESjrmwHfQJh1wQYMG6mUUHseIGKwb7qLaHIp7Nxxc1bydlxEHqqB
bF0c1daNoz1JrAL6rrhMRMT8TQZTw+n/+R3HDbdIWG9alxtNbg==
-----END CERTIFICATE-----"""

    pathMappings = []
    artifacts = []
    usesVPC = m2k.query({"id": "move2kube.ibmvpc", "type": "Select", "description": "Do you use IBM VPC?", "hints": ["A VPC contract file will be created."], "options": ["Yes", "No"]})
    if usesVPC == "No":
        return {'pathMappings': pathMappings, 'artifacts': artifacts}

    confTypes = m2k.query({"id": "move2kube.ibmvpc.types", "type": "MultiSelect", "description": "Choose the types : ", "options": ["workload", "env"]})

    if len(confTypes) == 0:
        return {'pathMappings': pathMappings, 'artifacts': artifacts}

    data = {}

    for confType in confTypes:
        if confType == "env":
            logHostName = m2k.query({"id": "move2kube.ibmvpc.env.loghostname", "type": "Input", "description": "Enter the log DNA hostname : ", "default": ""})
            ingestionKey = m2k.query({"id": "move2kube.ibmvpc.env.ingestionkey", "type": "Input", "description": "Enter the ingestion key : ", "default": ""})
            logPortStr = m2k.query({"id": "move2kube.ibmvpc.env.logport", "type": "Input", "description": "Enter the log port : ", "default": "8080"})
            volumeCountStr = m2k.query({"id": "move2kube.ibmvpc.env.volumecount", "type": "Input", "description": "Enter the number of volumes : ", "default": "0"})
            volumeCount = int(volumeCountStr)
            volumes = {}

            for i in range(volumeCount):
                volumeName = m2k.query({"id": "move2kube.ibmvpc.env.volumes[%d].name" % (i), "type": "Input", "description": "Enter the volume %d name : " % (i+1), "default": ""})
                volumeSeed = m2k.query({"id": "move2kube.ibmvpc.env.volumes[%d].seed" % (i), "type": "Input", "description": "Enter the volume %d seed : " % (i+1), "default": ""})
                volumeMount = m2k.query({"id": "move2kube.ibmvpc.env.volumes[%d].mount" % (i), "type": "Input", "description": "Enter the volume %d mount : " % (i+1), "default": ""})
                volumeFS = m2k.query({"id": "move2kube.ibmvpc.env.volumes[%d].fs" % (i), "type": "Input", "description": "Enter the volume %d filesystem : " % (i+1), "default": ""})
                volume = {"mount": volumeMount, "seed": volumeSeed, "filesystem": volumeFS}
                volumes[volumeName] = volume

            envPass = m2k.query({"id": "move2kube.ibmvpc.env.password", "type": "Input", "description": "Enter the password for encryption of env(Private Key) : ", "hint": ["If ignored, encrypted contract file would be empty"], "default": ""})

            data["EnvType"] = confType
            data["LogHostName"] = logHostName
            data["IngestionKey"] = ingestionKey
            data["LogPort"] = logPortStr
            data["EnvVolumes"] = volumes
            if envPass != "":
                data["EnvPass"] = envPass

        elif confType == "workload":
            authsCountStr = m2k.query({"id": "move2kube.ibmvpc.workload.authscount", "type": "Input", "description": "Enter the number of workloads : ", "default": "0"})
            authsCount = int(authsCountStr)
            auths = {}
            for i in range(authsCount):
                serviceAdress = m2k.query({"id": "move2kube.ibmvpc.workload.service[%d].address" % (i), "type": "Input", "description": "Enter the service %d address : " % (i+1), "default": ""})
                serviceUserName = m2k.query({"id": "move2kube.ibmvpc.env.service[%d].username" % (i), "type": "Input", "description": "Enter the username : ", "default": ""})
                servicePass = m2k.query({"id": "move2kube.ibmvpc.env.service[%d].pass" % (i), "type": "Input", "description": "Enter the password : ", "default": ""})
                auth = {"username": serviceUserName, "password": servicePass}
                auths[serviceAdress] = auth
            composeArchive = m2k.query({"id": "move2kube.ibmvpc.workload.compose.archive", "type": "Input", "description": "Enter the compose archive : ", "default": ""})
            imagesCountStr = m2k.query({"id": "move2kube.ibmvpc.workload.imagescount", "type": "Input", "description": "Enter the number of images : ", "default": "0"})
            imagesCount = int(imagesCountStr)
            images = {}

            for i in range(imagesCount):
                registryAdress = m2k.query({"id": "move2kube.ibmvpc.workload.registry[%d].address" % (i), "type": "Input", "description": "Enter the image %d registry address : " % (i+1), "default": ""})
                registryNotary = m2k.query({"id": "move2kube.ibmvpc.env.registry[%d].notary" % (i), "type": "Input", "description": "Enter the image %d notary : " % (i+1), "default": ""})
                registryPublicKey = m2k.query({"id": "move2kube.ibmvpc.env.registry[%d].publickey" % (i), "type": "Input", "description": "Enter the image %d public key : " % (i+1), "default": ""})
                image = {"notary": registryNotary, "publicKey": registryPublicKey}
                images[registryAdress] = image

            workloadVolumeCountStr = m2k.query({"id": "move2kube.ibmvpc.workload.volumecount", "type": "Input", "description": "Enter the number of volumes : ", "default": "0"})
            workloadVolumeCount = int(workloadVolumeCountStr)
            
            workloadVolumes = {}

            for i in range(workloadVolumeCount):
                volumeName = m2k.query({"id": "move2kube.ibmvpc.workload.volumes[%d].name" % (i), "type": "Input", "description": "Enter the volume %d name : "% (i+1), "default": ""})
                volumeSeed = m2k.query({"id": "move2kube.ibmvpc.workload.volumes[%d].seed" % (i), "type": "Input", "description": "Enter the volume %d seed : " % (i+1), "default": ""})
                volumeMount = m2k.query({"id": "move2kube.ibmvpc.workload.volumes[%d].mount" % (i), "type": "Input", "description": "Enter the volume %d mount : " % (i+1), "default": ""})
                volumeFS = m2k.query({"id": "move2kube.ibmvpc.workload.volumes[%d].fs" % (i), "type": "Input", "description": "Enter the volume %d filesystem : " % (i+1), "default": ""})
                volume = {"mount": volumeMount, "seed": volumeSeed, "filesystem": volumeFS}
                workloadVolumes[volumeName] = volume

            workloadEnvsCountStr = m2k.query({"id": "move2kube.ibmvpc.workload.envcount", "type": "Input", "description": "Enter the number of environment variables : ", "default": "0"})
            workloadEnvsCount = int(workloadEnvsCountStr)

            workloadEnvs = {}

            for i in range(workloadEnvsCount):
                envKey = m2k.query({"id": "move2kube.ibmvpc.workload.envs[%d].key" % (i), "type": "Input", "description": "Enter the environment variable %d key : " % (i+1), "default": ""})
                envValue = m2k.query({"id": "move2kube.ibmvpc.workload.envs[%d].value" % (i), "type": "Input", "description": "Enter the environment variable %d value : " % (i+1), "default": ""})
                workloadEnvs[envKey] = envValue
            
            workloadPass = m2k.query({"id": "move2kube.ibmvpc.workload.password", "type": "Input", "description": "Enter the password for encryption of workload (Private Key) : ", "hint": ["If ignored, encrypted contract file would be empty"], "default": ""})

            data["WorkloadType"] = confType
            data["Auths"] = auths
            data["ComposeArchive"] = composeArchive
            data["Images"] = images
            data["WorkloadVolumes"] = workloadVolumes
            data["WorkloadEnvs"] = workloadEnvs
            if workloadPass != "":
                data["WorkloadPass"] = workloadPass
    data["IbmHyperProtectCert"] = ibmHyperProtectCert
    pathMappings.append({'type': 'Template', 'templateConfig': data, 'destinationPath': 'ibm_vpc_artifacts/'})
    return {'pathMappings': pathMappings, 'artifacts': artifacts}
