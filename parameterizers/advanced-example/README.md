# Advanced Example

This shows multiple parameterizers being used to parameterize the replicas, container name and image name fields in K8s Deployment yamls.

## Layout

### Parameterizer syntax

The `container-name-parameterizer.yaml` file contains a parameterizer for parameterizing the container name.
```yaml
    - target: "spec.template.spec.containers.[0].name"
      filters:
        - kind: Deployment
          apiVersion: "apps/v1"
```

The `multiple-parameterizers.yaml` file contains the multiple parameterizers.  
The first parameterizer is for `spec.replicas` same as the simple example.
```yaml
    - target: "spec.replicas"
      template: "${common.replicas}"
      default: 10
      filters:
        - kind: Deployment
          apiVersion: ".*/v1.*"
```
The second parameterizer is for the image name in deployments.  
However instead of parameterizing the entire field we want to parameterize different parts differently.  
In this case we want to parameterize the image registry, the namespace, the image name and the image tag.  
The parameters field contains a list of defaults for different environments like `dev` `staging` and `prod`.
```yaml
    - target: 'spec.template.spec.containers.[containerName:name].image'
      template: '${imageregistry.url}/${imageregistry.namespace}/${services.$(metadataName).containers.$(containerName).image.name}:${services.$(metadataName).containers.$(containerName).image.tag}'
      default: us.icr.io/move2kube/myimage:latest
      filters:
        - kind: Deployment
          apiVersion: ".*/v1.*"
      parameters:
        - name: services.$(metadataName).containers.$(containerName).image.name
          values:
          - envs: [dev, staging, prod]
            metadataName: nginx
            value: nginx-allenvs
          - envs: [prod]
            metadataName: javaspringapp
            value: openjdk-prod8
            custom:
              containerName: apicontainer
          - envs: [dev]
            metadataName: javaspringapp
            value: openjdk-dev8
            custom:
              containerName: apicontainer
          - envs: [prod]
            metadataName: javaspringapp
            value: mysql-prod
            custom:
              containerName: mysqlcontainer
          - envs: [dev]
            metadataName: javaspringapp
            value: mysql-dev
            custom:
              containerName: mysqlcontainer
```
