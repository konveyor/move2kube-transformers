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

// PathMappingType refers to the Path Mapping type
type PathMappingType string

const (
	// DefaultPathMappingType allows normal copy with overwrite
	DefaultPathMappingType PathMappingType = "Default" // Normal Copy with overwrite
	// TemplatePathMappingType allows copy of source to destination and applying of template
	TemplatePathMappingType PathMappingType = "Template" // Source path when relative, is relative to yaml file location
	// SourcePathMappingType allows for copying of source directory to another directory
	SourcePathMappingType PathMappingType = "Source" // Source path becomes relative to source directory
	// DeletePathMappingType allows for deleting of files or folder directory
	DeletePathMappingType PathMappingType = "Delete" // Delete path becomes relative to source directory
	// ModifiedSourcePathMappingType allows for copying of deltas wrt source
	ModifiedSourcePathMappingType PathMappingType = "SourceDiff" // Source path becomes relative to source directory
	// PathTemplatePathMappingType allows for path template registration
	PathTemplatePathMappingType PathMappingType = "PathTemplate" // Path Template type
	// SpecialTemplatePathMappingType allows copy of source to destination and applying of template with custom delimiter
	SpecialTemplatePathMappingType PathMappingType = "SpecialTemplate" // Source path when relative, is relative to yaml file location
)

// Artifact represents the artifact that can be passed between transformers
type Artifact struct {
	Name string `yaml:"name,omitempty" json:"name,omitempty"`
	Type string `yaml:"type,omitempty" json:"type,omitempty"`
	// ProcessWith metav1.LabelSelector `yaml:"processWith,omitempty" json:"processWith,omitempty"` // Selector for choosing transformers that should process this artifact, empty is everything

	Paths   map[string][]string    `yaml:"paths,omitempty" json:"paths,omitempty" m2kpath:"normal"`
	Configs map[string]interface{} `yaml:"configs,omitempty" json:"configs,omitempty"` // Could be IR or template config or any custom configuration
}

// PathMapping is the mapping between source and intermediate files and output files
type PathMapping struct {
	Type           PathMappingType `yaml:"type,omitempty" json:"type,omitempty"` // Default - Normal copy
	SrcPath        string          `yaml:"sourcePath" json:"sourcePath" m2kpath:"normal"`
	DestPath       string          `yaml:"destinationPath" json:"destinationPath" m2kpath:"normal"` // Relative to output directory
	TemplateConfig interface{}     `yaml:"templateConfig" json:"templateConfig"`
}

type DirDetectInput struct {
	SourceDir string `yaml:"sourceDir" json:"sourceDir"`
}

type DirDetectOutput struct {
	Services map[string][]Artifact `yaml:"services,omitempty" json:"services,omitempty"`
}

type TransformInput struct {
	NewArtifacts         []Artifact `yaml:"newArtifacts,omitempty" json:"newArtifacts,omitempty"`
	AlreadySeenArtifacts []Artifact `yaml:"alreadySeenArtifacts,omitempty" json:"alreadySeenArtifacts,omitempty"`
}

type TransformOutput struct {
	NewPathMappings []PathMapping `yaml:"newPathMappings,omitempty" json:"newPathMappings,omitempty"`
	NewArtifacts    []Artifact    `yaml:"newArtifacts,omitempty" json:"newArtifacts,omitempty"`
}

// https://github.com/tinygo-org/tinygo/issues/411#issuecomment-503066868
var keyToAllocatedBytes = map[uint32][]byte{}
var nextKey uint32 = 41

// https://github.com/ejcx/wazero/blob/40f59a877bcdb4949eba51f9e1dee3deaba1ff83/examples/allocation/tinygo/testdata/greet.go#L64C1-L68C2
// ptrToString returns a string from WebAssembly compatible numeric types
// representing its pointer and length.
func ptrToString(ptr uint32, size uint32) string {
	return unsafe.String((*byte)(unsafe.Pointer(uintptr(ptr))), size)
}

//go:export myAllocate
func myAllocate(size uint32) *byte {
	nextKey += 1
	newArr := make([]byte, size)
	keyToAllocatedBytes[nextKey] = newArr
	return &newArr[0]
}

func saveBytes(ptrBytes []byte) uint32 {
	nextKey += 1
	keyToAllocatedBytes[nextKey] = ptrBytes
	ptr := &ptrBytes[0]
	return uint32(uintptr(unsafe.Pointer(ptr)))
}

const PomFile = "pom.xml"

var artifactNameRegex = regexp.MustCompile(`^\s*<artifactId>(.+)</artifactId>`)

// Extracts service name from pom file
func getServiceName(path string) (string, error) {
	_data, err := os.ReadFile(path)
	if err != nil {
		return "", fmt.Errorf("failed to read the pom.xml file '%s' . Error: %w", path, err)
	}
	data := string(_data)
	lines := strings.Split(data, "\n")
	for _, l := range lines {
		ms := artifactNameRegex.FindStringSubmatch(l)
		if len(ms) == 2 {
			return ms[1], nil
		}
	}
	return "", fmt.Errorf("artifactId/name was not found in the pom.xml")
}

// Performs the detection of pom file and extracts service name
func DirectoryDetect(dir string) (map[string][]Artifact, error) {
	dataFilePath := filepath.Join(dir, PomFile)
	if f, err := os.Stat(dataFilePath); err == nil && !f.IsDir() {
		serviceName, err := getServiceName(dataFilePath)
		if err != nil {
			return nil, fmt.Errorf("failed to get the service name. Error: %w", err)
		}
		services := map[string][]Artifact{}
		services[serviceName] = []Artifact{{
			Paths: map[string][]string{"ProjectPath": {dir}},
		}}
		return services, nil
	}
	return nil, nil
}

func Transform(
	newArtifacts []Artifact,
	alreadySeenArtifacts []Artifact,
) ([]PathMapping, []Artifact, error) {
	pathMappings := []PathMapping{}
	artifacts := []Artifact{}
	pathTemplate := "{{ SourceRel .ServiceFsPath }}"
	for _, v := range newArtifacts {
		_serviceName, ok := v.Configs["Service"].(map[string]interface{})
		if !ok {
			fmt.Println("failed to v.Configs[Service].(map[string]interface{})")
			continue
		}
		// serviceName, ok := _serviceName["serviceName"].(string)
		serviceName, ok := _serviceName["ServiceName"].(string)
		if !ok {
			fmt.Printf("failed to _serviceName[ServiceName].(string). actual _serviceName: %T %+v\n", _serviceName, _serviceName)
			continue
		}
		if len(v.Paths) == 0 {
			fmt.Printf("failed to v.Paths. actual v.Paths: %T %+v\n", v.Paths, v.Paths)
			continue
		}
		projPaths := v.Paths["ProjectPath"]
		if len(projPaths) == 0 {
			fmt.Printf("failed to v.Paths[ProjectPath]. actual v.Paths: %T %+v\n", projPaths, projPaths)
			continue
		}
		fmt.Printf("len(projPaths) %d %+v\n", len(projPaths), projPaths)
		dir := projPaths[0]
		// Create a path template for the service
		pathTemplateName := strings.ReplaceAll(serviceName, "-", "") + "path"
		tplPathData := map[string]interface{}{
			"ServiceFsPath":    dir,
			"PathTemplateName": pathTemplateName,
		}
		pathMappings = append(pathMappings,
			PathMapping{
				Type:           "PathTemplate",
				SrcPath:        pathTemplate,
				TemplateConfig: tplPathData,
			})
		// Since the helm chart uses the same templating character {{ }} as Golang templates,
		// we use `SpecialTemplate` type here where the templating character is <~ ~>.
		// The `Template` type can be used for all normal cases
		pathMappings = append(pathMappings, PathMapping{
			Type:     "SpecialTemplate",
			DestPath: "{{ ." + pathTemplateName + " }}",
			TemplateConfig: map[string]interface{}{
				"ServiceFsPath": dir,
				"ServiceName":   serviceName,
			}})
		pathMappings = append(pathMappings, PathMapping{
			Type:     "Source",
			SrcPath:  "{{ ." + pathTemplateName + " }}",
			DestPath: "{{ ." + pathTemplateName + " }}",
		})
	}
	return pathMappings, artifacts, nil
}

//go:export RunDirectoryDetect
func RunDirectoryDetect(
	inputJsonPtr uint32,
	inputJsonLen uint32,
	outputJsonPtrPtr uint32,
	outputJsonLenPtr uint32,
) (successOrError int32) {
	fmt.Println("mycustomtransformer: RunDirectoryDetect start")
	defer fmt.Println("mycustomtransformer: RunDirectoryDetect end")
	transformInputJson := ptrToString(inputJsonPtr, inputJsonLen)
	input := DirDetectInput{}
	if err := json.Unmarshal([]byte(transformInputJson), &input); err != nil {
		fmt.Printf("mycustomtransformer: failed to unmarshal input. Error: %q\n", err)
		return -1
	}
	ps, err := DirectoryDetect(input.SourceDir)
	if err != nil {
		fmt.Printf("mycustomtransformer: failed to transform. Error: %q\n", err)
		return -1
	}
	output := DirDetectOutput{Services: ps}
	outputJson, err := json.Marshal(output)
	if err != nil {
		fmt.Println("mycustomtransformer: failed to marshal")
		return -1
	}
	ptr := saveBytes(outputJson)
	ptrr := (*uint32)(unsafe.Pointer(uintptr(outputJsonPtrPtr)))
	*ptrr = ptr
	ptrl := (*uint32)(unsafe.Pointer(uintptr(outputJsonLenPtr)))
	*ptrl = uint32(len(outputJson))
	return 0
}

//go:export RunTransform
func RunTransform(
	inputJsonPtr uint32,
	inputJsonLen uint32,
	outputJsonPtrPtr uint32,
	outputJsonLenPtr uint32,
) (successOrError int32) {
	fmt.Println("mycustomtransformer: RunTransform start")
	defer fmt.Println("mycustomtransformer: RunTransform end")
	transformInputJson := ptrToString(inputJsonPtr, inputJsonLen)
	input := TransformInput{}
	if err := json.Unmarshal([]byte(transformInputJson), &input); err != nil {
		fmt.Printf("mycustomtransformer: failed to unmarshal input. Error: %q\n", err)
		return -1
	}
	ps, as, err := Transform(input.NewArtifacts, input.AlreadySeenArtifacts)
	if err != nil {
		fmt.Printf("mycustomtransformer: failed to transform. Error: %q\n", err)
		return -1
	}
	output := TransformOutput{
		NewPathMappings: ps,
		NewArtifacts:    as,
	}
	outputJson, err := json.Marshal(output)
	if err != nil {
		fmt.Printf("mycustomtransformer: failed to marshal. Error: %q\n", err)
		return -1
	}
	ptr := saveBytes(outputJson)
	ptrr := (*uint32)(unsafe.Pointer(uintptr(outputJsonPtrPtr)))
	*ptrr = ptr
	ptrl := (*uint32)(unsafe.Pointer(uintptr(outputJsonLenPtr)))
	*ptrl = uint32(len(outputJson))
	return 0
}

func main() {
	// wasmexport hasn't been implemented yet
	// https://github.com/golang/go/issues/42372a
	args := os.Args
	fmt.Printf("args: %+v\n", args)
}
