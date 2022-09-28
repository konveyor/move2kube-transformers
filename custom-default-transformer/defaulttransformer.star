#   Copyright IBM Corporation 2022
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

# Example for default transformer
def transform(new_artifacts, old_artifacts):
    pathMappings = []
    artifacts = []
    data = {}
    transformerName = "SampleDefaultTransformer"
    data["TransformerName"] = transformerName

    pathMappings.append({'type': 'Template', 'templateConfig': data})
    return {'pathMappings': pathMappings, 'artifacts': artifacts}
