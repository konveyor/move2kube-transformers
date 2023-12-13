package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"unsafe"
)

var artifactRegex = regexp.MustCompile(`<artifactId>(\w+)</artifactId>`)

const PomFile = "pom.xml"

var input []byte = make([]byte, 2048)

// Reads a null-terminated string (ala C strings) from the provided pointer
func readPtr(dataPointer *int32) string {
	nth := 0
	var dataStr strings.Builder
	pointer := uintptr(unsafe.Pointer(dataPointer))
	for {
		s := *(*int32)(unsafe.Pointer(pointer + uintptr(nth)))
		if byte(s) == 0 {
			break
		}

		dataStr.WriteByte(byte(s))
		nth++
	}

	return dataStr.String()
}

//export directoryDetect
func directoryDetect(dataPointer *int32) *int32 {
	dir := readPtr(dataPointer)
	dataFilePath := filepath.Join(dir, PomFile)

	transform_return_data := make(map[string]interface{})
	if _, err := os.Stat(dataFilePath); err == nil {
		serviceName := getServiceName(dataFilePath)
		transform_return_data = map[string]interface{}{
			serviceName: []map[string]interface{}{
				{
					"paths": map[string]interface{}{
						"ServiceDirectories":   []string{dir},
						"ServiceRootDirectory": []string{dir},
						"pomFiles":             []string{dataFilePath},
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
	} else {
		fmt.Printf("wasm stat failed: %v\n", err)
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
	rawData := readPtr(dataPointer)

	var data map[string]interface{}
	err := json.Unmarshal([]byte(rawData), &data)
	if err != nil {
		panic(err)
	}
	newArtifacts := data["newArtifacts"].([]interface{})

	pathMappings := []map[string]interface{}{}
	artifacts := []map[string]interface{}{}
	pathTemplate := "{{ SourceRel .ServiceFsPath }}"
	for _, v := range newArtifacts {
		v := v.(map[string]interface{})
		serviceName := v["configs"].(map[string]interface{})["Service"].(map[string]interface{})["ServiceName"].(string)
		paths := v["paths"].(map[string]interface{})
		dirs := paths["ServiceDirectories"].([]interface{})
		dir := dirs[0].(string)

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
	data, err := os.ReadFile(filePath)
	if err != nil {
		fmt.Println("Error reading file:", err)
		return ""
	}
	lines := strings.Split(string(data), "\n")
	for _, line := range lines {
		m := artifactRegex.FindStringSubmatch(line)
		if len(m) != 0 {
			return m[1]
		}
	}
	return ""
}

func main() {}
