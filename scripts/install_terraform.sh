#!/bin/bash
set -e

TERRAFORM_DL=${TOOLS_DIR}/terraform-${TERRAFORM_VERSION}

mkdir -p ${TOOLS_DIR}/bin

if [ ! -d "${TERRAFORM_DL}" ]
then
    mkdir -p ${TERRAFORM_DL}
    wget -q -O terraform-${TERRAFORM_VERSION}.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    unzip -q terraform-${TERRAFORM_VERSION}.zip -d ${TERRAFORM_DL}
    rm terraform-${TERRAFORM_VERSION}.zip
fi

ln -sf ${TERRAFORM_DL}/terraform ${TOOLS_DIR}/bin
terraform version
