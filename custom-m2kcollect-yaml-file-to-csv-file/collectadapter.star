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

# Performs the detection of m2k_collect folder
def directory_detect(dir):
    kind = "CfApps"
    fileList = fs.get_yamls_with_type_meta(inputpath=dir, kind=kind)
    return  {"": [{
                "paths": {"CfAppsFilesPaths": fileList} }] }

# Creates a list of strings having the application details and appends it to the output_strings_lists
def append_app_details_to_lists(app, applications, output_strings_lists, fields):
    app["Record Type 1"] = "1"
    app["Application Name"] = "A:" + applications["application"]["name"]
    app["Tag Type 1"] = "application"
    app["Tag 1"] = applications["application"]["spacedata"]["entity"]["orgdata"]["entity"]["name"]
    app["Tag Type 2"] = "app type"
    app["Tag 2"] = "app"
    output_strings_lists = update_output_strings_lists(fields, app, output_strings_lists)
    return output_strings_lists

# Updates the app_dep dictionary with dependency service details
def update_app_dependency_dict(app_dep, applications, vcap_serv):
    app_dep["Record Type 1"] = "2"
    app_dep["Application Name"] = "A:" + applications["application"]["name"]
    app_dep["Dependency"] = "S:" + vcap_serv["instance_name"]
    app_dep["Dependency Direction"] = "northbound"
    return app_dep

# Creates a dictionary which contains the service's details
def create_serv_dict(app_dep, applications, vcap_serv):
    serv = {}
    serv["Record Type 1"] = "1"
    serv["Application Name"] = app_dep["Dependency"]
    serv["Tag Type 1"] = "application"
    serv["Tag 1"] = applications["application"]["spacedata"]["entity"]["orgdata"]["entity"]["name"]
    serv["Tag Type 2"] = "app type"
    serv["Tag 2"] = "service"
    serv["Tag Type 3"] = "service"
    serv["Tag 3"] = vcap_serv["label"]
    return serv

# Creates lists of strings for app dependencies and services and appends them to output_strings_lists
def append_app_dependencies_services_to_lists(applications, output_strings_lists, fields):
    vcap_serv_labels = ["postgresql-database", "storagegrid", "user-provided", "cloud-object-storage"]
    for vcap_serv_label in vcap_serv_labels:
        if type(applications["environment"]["systemenv"]["VCAP_SERVICES"]) == "string":
            applications["environment"]["systemenv"]["VCAP_SERVICES"] = json.decode(applications["environment"]["systemenv"]["VCAP_SERVICES"])
        if vcap_serv_label in applications["environment"]["systemenv"]["VCAP_SERVICES"].keys():
            app_dep = {}
            for vcap_serv in applications["environment"]["systemenv"]["VCAP_SERVICES"][vcap_serv_label]:
                app_dep = update_app_dependency_dict(app_dep, applications, vcap_serv)
                output_strings_lists = update_output_strings_lists(fields, app_dep, output_strings_lists)
                serv = create_serv_dict(app_dep, applications, vcap_serv)
                output_strings_lists = update_output_strings_lists(fields, serv, output_strings_lists)
    return output_strings_lists

# Returns list of strings formed using the dictionary values
def get_output_strings_list(fields, app_dict):
    output_strings_list = []
    for field in fields:
        if field in app_dict.keys():
            output_strings_list.append(app_dict[field])
        else:
            output_strings_list.append("")
    return output_strings_list

# Updates the output_strings_lists by adding the new list of strings if it doesn't exist already
def update_output_strings_lists(fields, app_dict, output_strings_lists):
    output_strings_list = get_output_strings_list(fields, app_dict)
    if output_strings_list not in output_strings_lists:
        output_strings_lists.append(output_strings_list)
    return output_strings_lists

# Creates a csv file, in the format consumable by Tackle, using m2k_collect output
def transform(new_artifacts, old_artifacts):
    print('context dir: ' + context_dir)
    pathMappings = []
    artifacts = []
    fields = ["Record Type 1", "Application Name", "Description", "Comments", "Business Service", "Dependency", "Dependency Direction", "Tag Type 1", "Tag 1", "Tag Type 2", "Tag 2", "Tag Type 3", "Tag 3", "Tag Type 4", "Tag 4", "Tag Type 5", "Tag 5", "Tag Type 6", "Tag 6", "Tag Type 7", "Tag 7", "Tag Type 8", "Tag 8", "Tag Type 9", "Tag 9", "Tag Type 10", "Tag 10", "Tag Type 11", "Tag 11", "Tag Type 12", "Tag 12", "Tag Type 13", "Tag 13", "Tag Type 14", "Tag 14", "Tag Type 15", "Tag 15", "Tag Type 16", "Tag 16", "Tag Type 17", "Tag 17", "Tag Type 18", "Tag 18", "Tag Type 19", "Tag 19", "Tag Type 20", "Tag 20"]
    output_strings_lists = [fields]
    for v in new_artifacts:
        cfAppsFilesPaths = v["paths"]["CfAppsFilesPaths"]
        for cfAppsFilePath in cfAppsFilesPaths:
            s = fs.read_as_string(cfAppsFilePath)
            yamlData = yaml.loads(s)
            app = {}
            for applications in yamlData["spec"]["applications"]:
                output_strings_lists = append_app_details_to_lists(app, applications, output_strings_lists, fields)
                output_strings_lists = append_app_dependencies_services_to_lists(applications, output_strings_lists, fields)
            outputFileName = cfAppsFilePath.split("/")[-1].split(".")[0]+ ".csv"
            tmpFilePath = temp_dir + outputFileName
            fs.write(tmpFilePath, csv.write_all(output_strings_lists))
            pathMappings.append({'type': 'Default', \
                'sourcePath': tmpFilePath, \
                'destinationPath': outputFileName})
    return {'pathMappings': pathMappings, 'artifacts': artifacts}
