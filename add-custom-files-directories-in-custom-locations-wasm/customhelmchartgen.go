//    Copyright IBM Corporation 2021

//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at

//         http://www.apache.org/licenses/LICENSE-2.0

//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.
package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"unsafe"
)

const PomFile = "pom.xml"

//export directoryDetect
func directoryDetect(dataPointer *int32) *int32 {
	nth := 0
	var dataStr strings.Builder
	pointer := uintptr(unsafe.Pointer(dataPointer))
	for {
		s := *(*int32)(unsafe.Pointer(pointer + uintptr(nth)))
		if s == 0 {
			break
		}

		dataStr.WriteByte(byte(s))
		nth++
	}
	dir := dataStr.String()
	dataFilePath := filepath.Join(dir, PomFile)
	transform_return_data := make(map[string]interface{})
	if _, err := os.Stat(dataFilePath); err == nil {
		serviceName := getServiceName(dataFilePath)
		transform_return_data = map[string]interface{}{
			serviceName: []map[string]interface{}{
				{
					"paths": map[string]interface{}{
						"ProjectPath": []string{dir},
					},
				},
			},
		}
		transform_return_data_byt, err := json.Marshal(transform_return_data)
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}
		r := make([]int32, 2)
		r[0] = int32(uintptr(unsafe.Pointer(&(transform_return_data_byt[0]))))
		r[1] = int32(len(transform_return_data_byt))

		return &r[0]
	}
	transform_return_data = nil
	transform_return_data_byt, err := json.Marshal(transform_return_data)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	r := make([]int32, 2)
	r[0] = int32(uintptr(unsafe.Pointer(&(transform_return_data_byt[0]))))
	r[1] = int32(len(transform_return_data_byt))

	return &r[0]
}

//export transform
func transform(dataPointer *int32) *int32 {
	nth := 0
	var dataStr strings.Builder
	pointer := uintptr(unsafe.Pointer(dataPointer))
	for {
		s := *(*int32)(unsafe.Pointer(pointer + uintptr(nth)))
		if s == 0 {
			break
		}

		dataStr.WriteByte(byte(s))
		nth++
	}
	var data map[string]interface{}
	err := json.Unmarshal([]byte(dataStr.String()), &data)
	if err != nil {
		panic(err)
	}
	// map[string]interface{}
	newArtifacts := data["newArtifacts"].([]map[string]interface{})
	// oldArtifacts := data["oldArtifacts"].([]map[string]interface{})
	pathMappings := []map[string]interface{}{}
	artifacts := []map[string]interface{}{}
	pathTemplate := "{{ SourceRel .ServiceFsPath }}"
	for _, v := range newArtifacts {
		serviceName := v["configs"].(map[string]interface{})["Service"].(map[string]interface{})["serviceName"].(string)
		dir := v["paths"].(map[string]interface{})["ProjectPath"].([]string)[0]
		// Create a path template for the service
		pathTemplateName := strings.ReplaceAll(serviceName, "-", "") + "path"
		tplPathData := map[string]interface{}{
			"ServiceFsPath":    dir,
			"PathTemplateName": pathTemplateName,
		}
		pathMappings = append(pathMappings, map[string]interface{}{
			"type":           "PathTemplate",
			"sourcePath":     pathTemplate,
			"templateConfig": tplPathData,
		})
		// Since the helm chart uses the same templating character {{ }} as Golang templates,
		// we use `SpecialTemplate` type here where the templating character is <~ ~>.
		// The `Template` type can be used for all normal cases
		pathMappings = append(pathMappings, map[string]interface{}{
			"type":            "SpecialTemplate",
			"destinationPath": "{{ ." + pathTemplateName + " }}",
			"templateConfig": map[string]interface{}{
				"ServiceFsPath": dir,
				"ServiceName":   serviceName,
			},
		})
		pathMappings = append(pathMappings, map[string]interface{}{
			"type":            "Source",
			"sourcePath":      "{{ ." + pathTemplateName + " }}",
			"destinationPath": "{{ ." + pathTemplateName + " }}",
		})
	}
	transform_return_data := map[string]interface{}{
		"pathMappings": pathMappings,
		"artifacts":    artifacts,
	}
	transform_return_data_byt, err := json.Marshal(transform_return_data)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	r := make([]int32, 2)
	r[0] = int32(uintptr(unsafe.Pointer(&(transform_return_data_byt[0]))))
	r[1] = int32(len(transform_return_data_byt))

	return &r[0]
}

// getServiceName extracts service name from pom file
func getServiceName(filePath string) string {
	data, err := ioutil.ReadFile(filePath)
	if err != nil {
		fmt.Println("Error reading file:", err)
		return ""
	}
	lines := strings.Split(string(data), "\n")
	for _, line := range lines {
		if matched, _ := regexp.MatchString(`^[\t]<artifactId`, line); matched {
			t := strings.Split(line, ">")
			t2 := strings.Split(t[1], "<")
			return t2[0]
		}
	}
	return ""
}

func main() {}
