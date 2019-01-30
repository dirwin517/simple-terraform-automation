FROM node:8.10

WORKDIR /tmp
RUN apt-get update && apt-get install -y curl unzip python-dev ruby-sass

# Install Terraform
RUN curl -sL "https://releases.hashicorp.com/terraform/0.11.8/terraform_0.11.8_linux_amd64.zip" -o "terraform.zip" && \
    unzip terraform.zip -d terraform/ && \
    rm terraform.zip && \
    mv terraform /usr/local/terraform

# Install AWS-CLI to deploy
RUN curl -sL "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" && \
    unzip awscli-bundle.zip && \
    ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

ENV PATH /usr/local/terraform:node_modules/.bin:$PATH
WORKDIR /root