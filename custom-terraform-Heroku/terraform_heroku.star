#   Copyright IBM Corporation 2024
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


# Example for default
def transform(new_artifacts, old_artifacts):
    data = {}
    default_heroku_app_name = m2k.query({"id": "move2kube.heroku.default_heroku_app_name", "type": "Input", "description": "Enter default app name : ", "default" : "example"})
    data["default_heroku_app_name"] = default_heroku_app_name
    default_heroku_build_domain = m2k.query({"id": "move2kube.heroku.default_heroku_build_domain", "type": "Input", "description": "Enter default build domain : ", "default" : "example"})
    data["default_heroku_build_domain"] = default_heroku_build_domain

    pathMappings = []
    artifacts = []

    pathMappings.append({'type': 'Template', 'templateConfig': data, 'destinationPath': 'heroku_artifacts/'})
    return {'pathMappings': pathMappings, 'artifacts': artifacts}
