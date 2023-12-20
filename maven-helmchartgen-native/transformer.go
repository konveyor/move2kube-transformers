package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

var artifactRegex = regexp.MustCompile(`<artifactId>(\w+)</artifactId>`)

const PomFile = "pom.xml"

var input []byte = make([]byte, 2048)

// DirectoryDetect runs detect in each sub directory
func DirectoryDetect(inputPath string) map[string]interface{} {
	jsonFile, err := os.Open(inputPath)
	if err != nil {
		fmt.Println(err)

	}
	defer jsonFile.Close()
	byteValue, _ := ioutil.ReadAll(jsonFile)
	var data map[string]interface{}
	err = json.Unmarshal(byteValue, &data)
	dataFilePath := filepath.Join(data["InputDirectory"].(string), PomFile)

	transform_return_data := make(map[string]interface{})
	if _, err := os.Stat(dataFilePath); err == nil {
		serviceName := getServiceName(dataFilePath)
		transform_return_data = map[string]interface{}{
			serviceName: []map[string]interface{}{
				{
					"paths": map[string]interface{}{
						"ServiceDirectories":   []string{data["InputDirectory"].(string)},
						"ServiceRootDirectory": []string{data["InputDirectory"].(string)},
						"pomFiles":             []string{dataFilePath},
					},
				},
			},
		}
		return transform_return_data
	}
	return transform_return_data
}

// Transform transforms
func Transform(inputPath string) map[string]interface{} {
	jsonFile, err := os.Open(inputPath)
	if err != nil {
		fmt.Println(err)
	}
	defer jsonFile.Close()
	byteValue, _ := ioutil.ReadAll(jsonFile)
	var data map[string]interface{}
	err = json.Unmarshal(byteValue, &data)
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
	return transform_return_data
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

func main() {
	// ./transformer detect inputpath outputpath
	// ./transformer transform inputpath outputpath
	action := os.Args[1]
	var data map[string]interface{}
	inputPath := os.Getenv(os.Args[2])
	// fmt.Println(inputPath)
	if action == "detect" {
		data = DirectoryDetect(inputPath)
	} else {
		data = Transform(inputPath)
	}
	outputPath := os.Getenv(os.Args[3])
	// fmt.Println(outputPath)
	file, err := json.Marshal(data)
	if err != nil {
		panic(err)
	}
	os.MkdirAll(filepath.Dir(outputPath), 0755)
	err = ioutil.WriteFile(outputPath, file, 0644)
	if err != nil {
		panic(err)
	}
}
