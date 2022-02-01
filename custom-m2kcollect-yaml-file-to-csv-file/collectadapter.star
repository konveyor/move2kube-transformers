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
    if 'm2k_collect' in dir:
        print('Detected path: ' + dir)
        return  {"": [{
                    "paths": {"ProjectPath": [dir]} }] }

# Return csv string formed using the dictionary values
def get_csv_string(fields, app_dict):
    csv_string = ""
    for field in fields:
        if field in app_dict.keys():
            csv_string = csv_string + app_dict[field] + ","
        else:
            csv_string = csv_string + ","
    csv_string = csv_string + "\n"
    return csv_string

# Creates a csv file, in the format consumable by Tackle, using m2k_collect output
def transform(new_artifacts, old_artifacts):
    print('context dir: ' + context_dir)
    pathMappings = []
    artifacts = []
    fields = ["Record Type 1", "Application Name", "Description", "Comments", "Business Service", "Dependency", "Dependency Direction", "Tag Type 1", "Tag 1", "Tag Type 2", "Tag 2", "Tag Type 3", "Tag 3", "Tag Type 4", "Tag 4", "Tag Type 5", "Tag 5", "Tag Type 6", "Tag 6", "Tag Type 7", "Tag 7", "Tag Type 8", "Tag 8", "Tag Type 9", "Tag 9", "Tag Type 10", "Tag 10", "Tag Type 11", "Tag 11", "Tag Type 12", "Tag 12", "Tag Type 13", "Tag 13", "Tag Type 14", "Tag 14", "Tag Type 15", "Tag 15", "Tag Type 16", "Tag 16", "Tag Type 17", "Tag 17", "Tag Type 18", "Tag 18", "Tag Type 19", "Tag 19", "Tag Type 20", "Tag 20"]
    pathTemplateName = 'cfappspathtpl'
    tplPathData = {'PathTemplateName': pathTemplateName}
    pathMappings.append({'type': 'PathTemplate', \
                        'sourcePath': "m2k_collect/cfapps.csv", \
                        'templateConfig': tplPathData})
    apps = {}
    for v in new_artifacts:
        dir = v['paths']['ProjectPath'][0] + "/cf/"
        fileList = fs.readdir(dir)
        for p in fileList:
            if 'cfapps' in p:
                fullPath = fs.pathjoin(dir, p)
                s = fs.read(fullPath)
                yamlData = yaml.loads(s)
                csv_string = "Record Type 1,Application Name,Description,Comments,Business Service,Dependency,Dependency Direction,Tag Type 1,Tag 1,Tag Type 2,Tag 2,Tag Type 3,Tag 3,Tag Type 4,Tag 4,Tag Type 5,Tag 5,Tag Type 6,Tag 6,Tag Type 7,Tag 7,Tag Type 8,Tag 8,Tag Type 9,Tag 9,Tag Type 10,Tag 10,Tag Type 11,Tag 11,Tag Type 12,Tag 12,Tag Type 13,Tag 13,Tag Type 14,Tag 14,Tag Type 15,Tag 15,Tag Type 16,Tag 16,Tag Type 17,Tag 17,Tag Type 18,Tag 18,Tag Type 19,Tag 19,Tag Type 20,Tag 20\n"
                csv_strings = [csv_string]
                app = {}
                for applications in yamlData["spec"]["applications"]:
                    app["Record Type 1"] = "1"
                    app["Application Name"] = "A:" + applications["application"]["name"]
                    app["Tag Type 1"] = "application"
                    app["Tag 1"] = applications["application"]["spacedata"]["entity"]["orgdata"]["entity"]["name"]
                    app["Tag Type 2"] = "app type"
                    app["Tag 2"] = "app"
                    
                    csv_string = get_csv_string(fields, app)
                    if csv_string not in csv_strings:
                        csv_strings.append(csv_string)
                    
                    vcap_serv_labels = ["postgresql-database", "storagegrid", "user-provided"]
                    for vcap_serv_label in vcap_serv_labels:
                        if vcap_serv_label in applications["environment"]["systemenv"]["VCAP_SERVICES"].keys():
                            app1 = {}
                            for vcap_serv in applications["environment"]["systemenv"]["VCAP_SERVICES"][vcap_serv_label]:
                                app1["Record Type 1"] = "2"
                                app1["Application Name"] = "A:" + applications["application"]["name"]
                                app1["Dependency"] = "S:" + vcap_serv["instance_name"]
                                app1["Dependency Direction"] = "northbound"

                                csv_string = get_csv_string(fields, app1)
                                if csv_string not in csv_strings:
                                    csv_strings.append(csv_string)
                                
                                serv = {}
                                serv["Record Type 1"] = "1"
                                serv["Application Name"] = app1["Dependency"]
                                serv["Tag Type 1"] = "application"
                                serv["Tag 1"] = applications["application"]["spacedata"]["entity"]["orgdata"]["entity"]["name"]
                                serv["Tag Type 2"] = "app type"
                                serv["Tag 2"] = "service"
                                serv["Tag Type 3"] = "service"
                                serv["Tag 3"] = vcap_serv["label"]
                                
                                csv_string = get_csv_string(fields, serv)
                                if csv_string not in csv_strings:
                                    csv_strings.append(csv_string)
                tmpFilePath = temp_dir + "/cfapps.csv"
                string = ""
                for csv_string in csv_strings:
                    string  = string + csv_string
                fs.write(tmpFilePath, string)
                pathMappings.append({'type': 'Default', \
                    'sourcePath': tmpFilePath, \
                    'destinationPath': "{{ ." + pathTemplateName + " }}"})

    return {'pathMappings': pathMappings, 'artifacts': artifacts}
