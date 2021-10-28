# Simple Example

This shows a simple parameterizer that parameterizes the `spec.replicas` field in K8s Deployment yamls.

## Layout

### Transformer metadata

The `parameterizers.yaml` file contains the transformer configuration.
```yaml
apiVersion: move2kube.konveyor.io/v1alpha1
kind: Transformer
metadata:
  name: CustomParameterizers
spec:
  mode: "Container"
  class: "Parameterizer"
  consumes:
    - "KubernetesYamls"
```
This `apiVersion`, `kind` and `metadata` fields tells Move2Kube that this folder contains a custom transformer.  
The `spec.class` is set to `Parameterizer` since we want this transformer to parameterize the output of other transformers.  
The `spec.consumes` field lists all the different artifacts that this transformer can consume. In this case we consume K8s yamls.

### Parameterizer syntax

The `replicas-parameterizer.yaml` file contains the actual parameterizer.
```yaml
apiVersion: move2kube.konveyor.io/v1alpha1
kind: Parameterizer
metadata:
  name: replicas-parameterizer
spec:
  parameterizers:
    - target: "spec.replicas"
      template: "${common.replicas}"
      default: 10
      filters:
        - kind: Deployment
          apiVersion: ".*/v1.*"
```
It contains `apiVersion`, `kind` and `metadata` fields as before to indicate to Move2Kube that it is a paramterizer.  
The `spec.parameterizers` is a list of parameterizers. In this case we only have one parameterizer.  
Inside the parameterizer the `target` field specifies the field to be parameterized. In this case we are targetting the `spec.replicas` field.  
The `template` field is optional and specifies what gets substituted when `spec.replicas` is parameterized.  
The `default` field is optional and specifies the default value to use when parameterizing the field.  
If `default` is not specified then the original value of `spec.replicas` will be used as the default.  
The `filters` field is used to specify which K8s resources we want to target. Here we filter by `kind` and `apiVersion` to target all K8s Deployment yamls.

In case of helm we will end up with
```yaml
spec:
  replicas: {{ index .Values "common" "replicas" }}
```
in the deployment template and
```yaml
common:
  replicas: 10
```
in the `values.yaml` file.

In the case of Openshift templates we will end up with
```yaml
spec:
  replicas: ${{COMMON_REPLICAS}}
```
and a similar thing for Kustomize.
