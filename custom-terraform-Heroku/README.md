## Custom default transformer to generate terraform artifacts to deploy simple app on Heroku


### Prerequisites

1. terraform tool installed
2. heroku cli tool installed
3. heroku configured with credentials

### Run transform

```
move2kube transform -c move2kube-transformers/custom-terraform-Heroku -o heroku --overwrite
```

### Apply terraform artifacts

```
cd heroku
terraform init
terraform apply
```
