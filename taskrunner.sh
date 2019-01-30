
#! /bin/bash
set -e


#############################################
#         PRIVATE BUILD HELPERS             #
#############################################

clean() {
    echo -e "\n########## Cleaning Build Artifacts ##########\n"
    rm -rf ./.terraform/
    rm -rf ./manifests/.terraform/
}

#############################################
#             JENKINS RUNS THESE            #
#############################################

integration-test() {
    echo -e "\n############ There are not tests #############\n"
}

build() {
      echo -e "\n########## NO BUILD #############\n"
}

deploy() {
    # Build deployment container
    echo -e "\n########### Building Deployment Container ###########\n"
    docker-compose build deploy

    # Run terraform apply inside container
    echo -e "\n########### Starting Terraform Deployment ###########\n"
    docker-compose run --rm deploy ./tfw.sh apply

    sleep 35
}

destroy() {
    docker-compose run --rm deploy ./tfw.sh destroy
}

for ARG in "$@"; do
    echo "Running \"$ARG\""
    $ARG
done
