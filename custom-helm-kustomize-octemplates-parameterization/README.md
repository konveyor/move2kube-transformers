# Parameterizer

This shows multiple parameterizers being used to parameterize the replicas, container name and image name fields in K8s Deployment yamls.

## Parameterizer syntax

  ```yaml
    apiVersion: move2kube.konveyor.io/v1alpha1
    kind: Parameterizer
    metadata:
      name: deployment-parameterizers
    spec:
      parameterizers:
  ```

The parameterizer syntax contains `apiVersion`, `kind` and `metadata` fields as before to indicate to Move2Kube that it is a paramterizer. The `spec.parameterizers` is a list of parameterizers.   

### Replicas Prameterization

  ```yaml
    - target: "spec.replicas"
      template: "${common.replicas}"
      default: 10
      filters:
        - kind: Deployment
          apiVersion: ".*/v1.*"
  ```

Inside the parameterizer the `target` field specifies the field to be parameterized. In this case we are targetting the `spec.replicas` field.  
The `template` field is optional and specifies what gets substituted when `spec.replicas` is parameterized.  
The `default` field is optional and specifies the default value to use when parameterizing the field. If `default` is not specified then the original value of `spec.replicas` will be used as the default.  
The `filters` field is used to specify which K8s resources we want to target. Here we filter by `kind` and `apiVersion` to target all K8s Deployment yamls.

#### Helm values.yaml
  ```yaml
  common:
    replicas: 10
  ```

#### Kustomize overlay
  ```yaml
  - op: replace
    path: /spec/replicas
    value: 10
  ```

#### Openshift Template
  ```yaml
  parameters:
    - name: COMMON_REPLICAS
      value: "10"
  ```

### Container Name parameterization
However instead of parameterizing the entire field we want to parameterize different parts differently. In this case we want to parameterize the image registry, the namespace, the image name and the image tag. The parameters field contains a list of defaults for different environments like `dev` `staging` and `prod`.

  ```yaml
    - target: 'spec.template.spec.containers.[containerName:name].image'
      template: '${imageregistry.url}/${imageregistry.namespace}/${services.$(metadataName).containers.$(containerName).image.name}:${services.$(metadataName).containers.$(containerName).image.tag}'
      default: quay.io/konveyor/myimage:latest
      filters:
        - kind: Deployment
          apiVersion: ".*/v1.*"
      parameters:
        - name: services.$(metadataName).containers.$(containerName).image.name
          values:
          - envs: [dev, staging, prod]
            metadataName: frontend
            value: frontend
          - envs: [prod]
            metadataName: orders
            value: orders
            custom:
              containerName: orders
  ```

#### Helm values-prod.yaml
  ```yaml
    imageregistry:
      namespace: konveyor
      url: quay.io
    services:
      frontend:
        containers:
          frontend:
            image:
              name: frontend
              tag: latest
      orders:
        containers:
          orders:
            image:
              name: orders
              tag: latest
  ```

#### Kustomize overlay 
`myproject/deploy/yamls-parameterized/kustomize/overlays/dev/apps-v1-deployment-frontend.yaml`
  ```yaml
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: frontend
  ```
`myproject/deploy/yamls-parameterized/kustomize/overlays/dev/apps-v1-deployment-orders.yaml`
  ```yaml
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: quay.io/konveyor/myimage:latest
  ```
`myproject/deploy/yamls-parameterized/kustomize/overlays/prod/apps-v1-deployment-frontend.yaml`
  ```yaml
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: frontend
  ```
`myproject/deploy/yamls-parameterized/kustomize/overlays/prod/apps-v1-deployment-orders.yaml`
  ```yaml
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: orders
  ```

#### Openshift Template
  ```yaml
    parameters:
      - name: IMAGEREGISTRY_URL
        value: quay.io
      - name: IMAGEREGISTRY_NAMESPACE
        value: konveyor
      - name: SERVICES_ORDERS_CONTAINERS_ORDERS_IMAGE_NAME
        value: myimage
      - name: SERVICES_ORDERS_CONTAINERS_ORDERS_IMAGE_TAG
        value: latest
      - name: SERVICES_FRONTEND_CONTAINERS_FRONTEND_IMAGE_TAG
        value: latest
  ```