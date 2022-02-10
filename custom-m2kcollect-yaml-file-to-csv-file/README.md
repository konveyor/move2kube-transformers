# Custom yaml-to-csv transformer

This custom transformer can be used to convert *move2kube collect* output yaml files of `kind:CfApps` to csv files.

## Steps

Steps 1 - 4 can be skipped if you just want to try out this transformer without logging in to cloud foundry. You can use our sample [cfapps.yaml](https://github.com/konveyor/move2kube-demos/blob/main/samples/enterprise-app/collect/cf/cfapps.yaml) file which is the anonymized yaml file of move2kube collect output.

1. First log in to your cloud foundry account in which your application instances are running.

    ```console
    $ cf login
    ```

    You can run `cf apps` to get the list of apps which are deployed to cloud foundry.

2. Install the latest version of Move2Kube.

   ```console
   $ BLEEDING_EDGE='true' bash <(curl https://raw.githubusercontent.com/konveyor/move2kube/main/scripts/install.sh)
   ```

   To verify that Mov2Kube was correctly installed you can run `move2kube version -l`.

3. Run the below command to collect the runtime information of your cloud foundry applications. (Here we are using the `-a` annotation flag to collect the information only from cloud foundry.)

   ```console
   $ move2kube collect -a cf
   ```

4. The data we collected will be stored in a new directory called `./m2k_collect`.

    ```console
    $ ls m2k_collect
    cf
    
    $ ls m2k_collect/cf
    cfapps.yaml
    ```

    The `./m2k_collect/cf` directory contains the `cfapps.yaml` file which has the runtime information about applications running on cloud foundry. There is information about the buildpacks that are supported, the memory, the number of instances, the ports that are supported, enviroment variables, etc.

5. We have already provided a sample [cfapps.yaml](https://github.com/konveyor/move2kube-demos/blob/main/samples/enterprise-app/collect/cf/cfapps.yaml) file which you can directly use. First download the file by running the below command.

   ```console
    $ curl https://move2kube.konveyor.io/scripts/download.sh | bash -s -- -d samples/enterprise-app/collect/cf -r move2kube-demos

    $ ls cf
    cfapps.yaml
    ```

6. Download the [custom yaml-to-csv transformer](https://github.com/konveyor/move2kube-transformers/tree/main/custom-m2kcollect-yaml-file-to-csv).

    ```console
    $ curl https://move2kube.konveyor.io/scripts/download.sh | bash -s -- -d custom-m2kcollect-yaml-file-to-csv-file -r move2kube-transformers -o customizations

    $ ls customizations/custom-m2kcollect-yaml-file-to-csv-file
    README.md    collectadapter.star    transformer.yaml
    ```

7. Run move2kube transform on the source folder which contains the yaml files and also provide the custom transformer to Move2Kube using the `-c` flag. In this case, `./cf` is the source folder contains the `cfapps.yaml` file.

    Select the default answers for the questions asked by Move2Kube during the `transform` phase by pressing `return` or `enter` key.

    ```console
    $ move2kube transform -s ./cf -c ./customizations
    ? Select all transformer types that you are interested in:
    ID: move2kube.transformers.types
    Hints:
    [Services that don't support any of the transformer types you are interested in will be ignored.]
    [Use arrows to move, space to select, <right> to all, <left> to none, type to filter]
     CollectAdapter
    INFO[0106] Configuration loading done                   
    INFO[0106] Planning Transformation - Base Directory     
    INFO[0106] [Base Directory] Identified 0 named services and 0 to-be-named services 
    INFO[0106] Transformation planning - Base Directory done 
    INFO[0106] Planning Transformation - Directory Walk     
    INFO[0106] Identified 1 named services and 0 to-be-named services in . 
    INFO[0106] Transformation planning - Directory Walk done 
    INFO[0106] [Directory Walk] Identified 1 named services and 0 to-be-named services 
    INFO[0106] [Named Services] Identified 1 named services 
    INFO[0106] No of services identified : 1                
    INFO[0106] Starting Plan Transformation                 
    ? Select all services that are needed:
    ID: move2kube.services.[].enable
    Hints:
    [The services unselected here will be ignored.]
    [Use arrows to move, space to select, <right> to all, <left> to none, type to filter
     move2kube-transformers
    INFO[1458] Iteration 1                                  
    INFO[1458] Iteration 2 - 1 artifacts to process         
    INFO[1458] Transformer CollectAdapter processing 1 artifacts 
    context dir: /var/folders/sw/_kjrz98j3ws1qj7zz6chzhrr0000gn/T/move2kube2985197932/m2kassets/custom
    INFO[1458] Transformer CollectAdapter Done              
    INFO[1458] Plan Transformation done                     
    INFO[1458] Transformed target artifacts can be found at [/Users/user/myproject].
    ```

8. The transformation has completed and Move2Kube has generated a directory called `./myproject`.

    ```console
    $ ls myproject
    cfapps.csv
    ```

    The `./myproject` folder contains the `cfapps.csv` file which Move2Kube has created by transforming the `cfapps.yaml` file.
