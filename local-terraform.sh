#!/bin/bash

# Run the command and ignore the exit code
command || true

# Set AWS & remote backend variables
account="challenge"
bucket="bucket=faceit-prod-eu-west-1-${account}"
backend="dynamodb_table=faceit-prod-eu-west-1-${account}"
#role="role_arn=arn:aws:iam::${account_id}:role/OrganizationAccountAccessRole"

TF_WORKSPACE="app"

set -a
source .env
set +a

init_workspace() {
  terraform init \
    -backend-config=$bucket \
    -backend-config=$backend \
    -input=false \
    -reconfigure \
#    -upgrade

  if terraform workspace list | grep -q "$TF_WORKSPACE"; then
    terraform workspace select "$TF_WORKSPACE"
  else
    terraform workspace new "$TF_WORKSPACE"
  fi
}

case "$1" in
  plan)
    init_workspace
#    terraform state list
#    terraform validate
    terraform plan -out=plan  #-refresh=false
    ;;
  apply)
    init_workspace
    terraform plan -out=plan -refresh=false
    terraform apply -auto-approve plan
    ;;
  destroy)
    init_workspace
    terraform plan -out=plan -destroy -refresh=false
    terraform apply -auto-approve plan
    ;;
  console)
    init_workspace
    terraform console
    ;;
  *)
    echo "Invalid argument. Use one of: plan, apply, destroy."
    exit 1
    ;;
esac