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

func unpack(combined uint64) (uint32, uint32) {
	pointer := uint32(combined >> 32) // Extracts the upper 32 bits
	size := uint32(combined)          // Extracts the lower 32 bits
	return pointer, size
}

func pack(pointer uint32, size uint32) uint64 {
	return (uint64(pointer) << 32) | uint64(size)
}

func readData(dataPointer uint64) string {
	pointer, size := unpack(dataPointer)
	dataStr := unsafe.String((*byte)(unsafe.Pointer(uintptr(pointer))), size)
	return strings.Clone(dataStr)
}

//export directoryDetect
func directoryDetect(dataPointer uint64) uint64 {
	dir := readData(dataPointer)
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

		DDptr := uint32(uintptr(unsafe.Pointer(&(transform_return_data_byt[0]))))
		DDsize := uint32(len(transform_return_data_byt))

		return pack(DDptr, DDsize)
	} else {
		fmt.Printf("wasm stat failed: %v\n", err)
	}

	transform_return_data = nil
	transform_return_data_byt, err := json.Marshal(transform_return_data)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	DDptr := uint32(uintptr(unsafe.Pointer(&(transform_return_data_byt[0]))))
	DDsize := uint32(len(transform_return_data_byt))

	return pack(DDptr, DDsize)
}

//export transform
func transform(dataPointer uint64) uint64 {
	rawData := readData(dataPointer)

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
	TTptr := uint32(uintptr(unsafe.Pointer(&(transform_return_data_byt[0]))))
	TTsize := uint32(len(transform_return_data_byt))

	return pack(TTptr, TTsize)
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
