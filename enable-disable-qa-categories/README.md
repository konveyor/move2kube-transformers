# How to enable/disable the QA categories using custom QA mappings file

By default, Move2Kube uses the QA categories from the built-in [QA mappings](https://github.com/konveyor/move2kube/blob/main/assets/built-in/qa/qamappings.yaml) file. All the categories in the built-in QA Mappings file are enabled by default.

There are multiple ways in which the QA categories can be enabled or disabled. It can be done through a custom QA mappings file that can be uploaded to the Move2Kube UI. It can be also done through `--qa-disable` or `--qa-enable` flags with the Move2Kube CLI/API.

In the custom QA mappings file, the user can also move the questions from one category to the other category, or even define new categories and add questions to them and enable/disable the categories as per the requirements. This is the additional feature that the custom QA mappings file offer, because the `--qa-disable` and `--qa-enable` flags can only be used to enable or disable the categories amongst the existing set of categories.

## Disabling QA category using the mappings file

- To disable the `network` QA category, we will use a custom QA mappings file in which the `enabled` flag is set to `false` for the `network` category. And then we will have to pass this QA mappings file as a customization in the UI before running the planning and transform phases.

  ```yaml
  - name: network
        enabled: false
        questions:
          - move2kube.services.*.*.servicetype
          - move2kube.target.*.ingress.ingressclassname
          - move2kube.target.*.ingress.host
          - move2kube.target.*.ingress.tls
  ```
  
  ```console
  $ docker pull quay.io/konveyor/move2kube-ui:latest
  ```

  ```console
  $ docker run --rm -it -p 8080:8080 quay.io/konveyor/move2kube-ui:latest
  ```

- Upload the source zip file and the customizations zipped folder containing the custom QA mappings file with network categories disabled. Run the plan phase and then start the transformation. During the transformation, Move2Kube will not ask any questions from the network category (servicetype, ingress host, tls, etc.).

## Using a config file along with the QA mappings file

- We have also provided a sample `config.yaml` file, with some dummy values, that can be used for answering some of the questions automatically to further reduce the number of questions that the user is required to answer during the transform phase.

- To use the config file and the customized qa mappings file, upload the source zip file, the config file and the customizations zipped folder containing the custom QA mappings file with network categories disabled. And then run the plan phase followed by the transform phase.

- It should only ask questions related to the service ports, because the config.yaml file contains the answer for all the categories other than the `ports` and `network` categories, and the custom QA mappings file disables the `network` category. So, the user will have to answer only the questions related to ports.

## Enabling/Disabling QA categories with Move2Kube CLI

- When using the Move2Kube CLI, to disable the QA categories `network` the below command can be used. Let's assume that the `src` folder contains the source artifacts.

  ```console
  $ move2kube transform -s src --qa-disable network
  ```

  To use the config file with `--qa-disable` flag

  ```console
  $ move2kube transform -s src --qa-disable network -f config.yaml
  ```
