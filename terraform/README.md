## Configure terraform

1. Export environment variables for credentials
```
export AWS_PROFILE=lbernail
export AWS_DEFAULT_REGION=eu-west-1
```
1. Create bucket to store states (you must choose a unique name)
```
aws s3 mb s3://tfstates
```
