#! /bin/bash
set -e

DEPLOYMENT_ENV=${ENV-'dev'};
BACKEND_BUCKET="bucket=proxy-tfstate";

if [ "$DEPLOYMENT_ENV" == "prd" ]; then
    BACKEND_BUCKET="$BACKEND_BUCKET-prod"
fi

DOMAIN_PREFIX=''

if [ "$GIT_SAFE_BRANCH" != "$DEPLOYMENT_ENV" ]; then
  DOMAIN_PREFIX="$GIT_SAFE_BRANCH."
fi

if [ "$DEPLOYMENT_ENV" == "prd" ]; then
    DOMAIN_PREFIX=""
fi

RESOURCE_PREFIX="proxy-$GIT_SAFE_BRANCH"

# Hook up state object storage to S3
cd manifests
terraform init \
    -backend=true \
    -backend-config="$BACKEND_BUCKET" \
    -backend-config="key=$GIT_SAFE_BRANCH/terraform.tfstate" \
    -backend-config="region=us-west-2"

terraform env new ${GIT_SAFE_BRANCH} || true
terraform env select ${GIT_SAFE_BRANCH}

cp -r .terraform/ ../.terraform/
cd ../

terraform plan \
    -var-file=manifests/variables/$DEPLOYMENT_ENV.tfvars \
    -var="resource_prefix=$RESOURCE_PREFIX" \
    -var="domain_prefix=$DOMAIN_PREFIX" \
    -refresh=true \
    -parallelism=2 \
    manifests/

if [ $1 == "destroy" ]; then
    terraform destroy \
    -var-file=manifests/variables/$DEPLOYMENT_ENV.tfvars \
    -var="resource_prefix=$RESOURCE_PREFIX" \
    -var="domain_prefix=$DOMAIN_PREFIX" \
    -force \
    manifests/
    exit
fi

# Some resources require second run to update calculated fields
if [ $1 == "apply" ]; then
    terraform $@ \
        -var-file=manifests/variables/$DEPLOYMENT_ENV.tfvars \
        -var="resource_prefix=$RESOURCE_PREFIX" \
        -var="domain_prefix=$DOMAIN_PREFIX" \
        -auto-approve \
        -refresh=true \
        -parallelism=2 \
        manifests/
fi
