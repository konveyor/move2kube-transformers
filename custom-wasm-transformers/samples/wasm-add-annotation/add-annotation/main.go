package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"unsafe"

	"gopkg.in/yaml.v3"
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

func Transform(
	newArtifacts []Artifact,
	alreadySeenArtifacts []Artifact,
) ([]PathMapping, []Artifact, error) {
	pathMappings := []PathMapping{}
	artifacts := []Artifact{}

	for _, newArtifact := range newArtifacts {
		if len(newArtifact.Paths) == 0 {
			fmt.Println("[DEBUG] newArtifact.Paths is nil/empty")
			continue
		}
		if len(newArtifact.Paths["KubernetesYamls"]) == 0 {
			fmt.Println("[DEBUG] newArtifact.Paths[KubernetesYamls] is nil/empty")
			continue
		}
		yamlsPath := newArtifact.Paths["KubernetesYamls"][0]
		fmt.Printf("[DEBUG] newArtifact yamlsPath: '%s'\n", yamlsPath)
		serviceName := newArtifact.Name
		artifacts = append(artifacts, newArtifact)

		yamlsBasePath := filepath.Base(yamlsPath)
		// Create a custom path template for the service, whose values gets filled and can be used in other pathmappings
		pathTemplateName := serviceName + yamlsBasePath
		pathTemplateName = strings.ReplaceAll(pathTemplateName, "-", "")
		tplPathData := map[string]string{"PathTemplateName": pathTemplateName}
		pathMappings = append(pathMappings, PathMapping{
			Type:           "PathTemplate",
			SrcPath:        "{{ OutputRel \"" + yamlsPath + "\" }}",
			TemplateConfig: tplPathData,
		})
		fileList, err := os.ReadDir(yamlsPath)
		if err != nil {
			return nil, nil, fmt.Errorf("failed to read the directory '%s' . Error: %w", yamlsPath, err)
		}
		fmt.Printf("[DEBUG] newArtifact fileList: '%d'\n", len(fileList))
		for _, f := range fileList {
			filePath := filepath.Join(yamlsPath, f.Name())
			fmt.Printf("[DEBUG] filePath: '%s'\n", filePath)
			inputBytes, err := os.ReadFile(filePath)
			if err != nil {
				fmt.Printf("[ERROR] read file filePath: '%s' . Error: %q\n", filePath, err)
				continue
			}
			// inputYaml := string(inputBytes)
			yamlData := map[string]interface{}{}
			if err := yaml.Unmarshal(inputBytes, &yamlData); err != nil {
				fmt.Printf("[ERROR] yaml unmarshal filePath: '%s' . Error: %q\n", filePath, err)
				continue
			}
			if yamlData["kind"] != "Deployment" {
				fmt.Println("kind does not exist/kind is not Deployment")
				continue
			}
			__svc_name, ok := yamlData["metadata"].(map[string]interface{})
			if !ok {
				fmt.Println("metadata is missing")
				continue
			}
			svc_name, ok := __svc_name["name"].(string)
			if !ok {
				fmt.Println("name is missing")
				continue
			}
			fmt.Printf("[DEBUG] svc_name %s\n", svc_name)
			annotations, ok := __svc_name["annotations"].(map[string]string)
			if !ok {
				annotations = map[string]string{}
				__svc_name["annotations"] = annotations
			}
			annotations["my.domain.com/custom-annotation"] = "foo"
			fmt.Printf("[DEBUG] annotations %+v\n", annotations)
			sBytes, err := yaml.Marshal(yamlData)
			if err != nil {
				fmt.Printf("[ERROR] yaml marshal error: %q\n", err)
				continue
			}
			if err := os.WriteFile(filePath, sBytes, 0644); err != nil {
				fmt.Printf("[ERROR] write file %s error: %q\n", filePath, err)
				continue
			}
			pathMappings = append(pathMappings,
				PathMapping{
					Type:     "Default",
					SrcPath:  yamlsPath,
					DestPath: "{{ ." + pathTemplateName + " }}",
				},
			)
		}
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
		fmt.Println("mycustomtransformer: failed to unmarshal")
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

func main() {
	// wasmexport hasn't been implemented yet
	// https://github.com/golang/go/issues/42372a
	args := os.Args
	fmt.Printf("args: %+v\n", args)
}
